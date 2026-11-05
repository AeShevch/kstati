import UIKit
import UniformTypeIdentifiers
import MemoryCore
import MemoryPersistence

final class ShareViewController: UIViewController {
    private let captureID = UUID().uuidString
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
        let providers = (extensionContext?.inputItems as? [NSExtensionItem])?
            .flatMap { $0.attachments ?? [] } ?? []
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }) else {
            status.text = "Изображение не найдено"
            return
        }
        let identifier = provider.registeredTypeIdentifiers.first {
            UTType($0)?.conforms(to: .image) == true
        } ?? UTType.image.identifier
        provider.loadDataRepresentation(forTypeIdentifier: identifier) { [weak self] data, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let data, !data.isEmpty {
                    self.imageData = data
                    self.status.text = "Изображение готово к сохранению"
                    self.saveButton.isEnabled = true
                } else {
                    self.status.text = "Не удалось прочитать изображение: \(error?.localizedDescription ?? "нет данных")"
                }
            }
        }
    }

    @objc private func save() {
        guard !isSaving, let imageData else { return }
        isSaving = true
        saveButton.isEnabled = false
        status.text = "Сохранение…"
        do {
            guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.app.kstati.memory") else {
                throw MemoryError.unavailableContainer
            }
            let repository = try MemoryRepository(directory: container)
            try repository.saveImage(imageData, captureID: captureID)
            status.text = "Сохранено локально"
            extensionContext?.completeRequest(returningItems: nil)
        } catch {
            status.text = "Не удалось сохранить: \(error.localizedDescription)"
            saveButton.isEnabled = true
            isSaving = false
        }
    }
}
