import CoreML
import Foundation
import Vision

public struct VisionTextRecognizer: TextRecognizer {
    public init() {}

    public func recognize(_ data: Data) throws -> String {
        try recognize(data, preferCPU: false)
    }

    func recognize(_ data: Data, preferCPU: Bool) throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        if preferCPU {
            for (stage, devices) in try request.supportedComputeStageDevices {
                if let cpu = devices.first(where: {
                    if case .cpu = $0 { return true }
                    return false
                }) {
                    request.setComputeDevice(cpu, for: stage)
                }
            }
        }
        let handler = VNImageRequestHandler(data: data)
        try handler.perform([request])
        return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }
}
