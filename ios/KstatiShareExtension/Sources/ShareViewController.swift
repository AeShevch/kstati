import MemoryCore
import MemoryPersistence
import UIKit
import UniformTypeIdentifiers

private struct SendableItemProvider: @unchecked Sendable {
    let value: NSItemProvider
}

final class ShareViewController: UIViewController {
    private let status = UILabel()
    private let saveButton = UIButton(type: .system)
    private var imageData: Data?
    private var isSaving = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        status.text = "Подготовка изображения…"
        status.numberOfLines = 0
        status.textAlignment = .center
        saveButton.setTitle("Сохранить в Кстати", for: .normal)
        saveButton.accessibilityIdentifier = "saveShareImage"
        saveButton.isEnabled = false
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [status, saveButton])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        loadImage()
    }

    private func loadImage() {
        let providers =
            (extensionContext?.inputItems as? [NSExtensionItem])?
            .flatMap { $0.attachments ?? [] } ?? []
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) })
        else {
            status.text = "Изображение не найдено"
            return
        }
        let identifier =
            provider.registeredTypeIdentifiers.first {
                UTType($0)?.conforms(to: .image) == true
            } ?? UTType.image.identifier
        let sendableProvider = SendableItemProvider(value: provider)
        provider.loadDataRepresentation(forTypeIdentifier: identifier) { [weak self] data, error in
            let imageData = data.flatMap { UIImage(data: $0) == nil ? nil : $0 }
            let errorMessage = error?.localizedDescription
            DispatchQueue.main.async {
                guard let self else { return }
                if let imageData {
                    self.setImageData(imageData)
                } else {
                    self.loadDecodedImage(
                        from: sendableProvider.value,
                        identifier: identifier, initialError: errorMessage)
                }
            }
        }
    }

    private func loadDecodedImage(from provider: NSItemProvider, identifier: String, initialError: String?) {
        provider.loadItem(forTypeIdentifier: identifier, options: nil) { [weak self] object, error in
            let imageData: Data?
            if let image = object as? UIImage {
                imageData = image.pngData()
            } else if let data = object as? Data {
                imageData =
                    UIImage(data: data)?.pngData()
                    ?? (try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIImage.self, from: data))?.pngData()
            } else if let url = object as? URL, let data = try? Data(contentsOf: url) {
                imageData = UIImage(data: data) == nil ? nil : data
            } else {
                imageData = nil
            }
            let errorMessage = error?.localizedDescription
            DispatchQueue.main.async {
                guard let self else { return }
                if let imageData {
                    self.setImageData(imageData)
                } else {
                    self.status.text =
                        "Не удалось прочитать изображение: \(errorMessage ?? initialError ?? "неподдерживаемые данные")"
                }
            }
        }
    }

    private func setImageData(_ data: Data) {
        imageData = data
        status.text = "Изображение готово к сохранению"
        saveButton.isEnabled = true
    }

    @objc private func save() {
        guard !isSaving, let imageData else { return }
        isSaving = true
        saveButton.isEnabled = false
        status.text = "Сохранение…"
        do {
            guard
                let container = FileManager.default.containerURL(
                    forSecurityApplicationGroupIdentifier: "group.app.kstati.memory")
            else {
                throw MemoryError.unavailableContainer
            }
            let repository = try MemoryRepository(directory: container)
            try repository.saveImage(imageData, captureID: ShareCaptureID.forImage(imageData))
            status.text = "Сохранено локально"
            extensionContext?.completeRequest(returningItems: nil)
        } catch {
            status.text = "Не удалось сохранить: \(error.localizedDescription)"
            saveButton.isEnabled = true
            isSaving = false
        }
    }
}
