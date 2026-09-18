import AVFoundation
import Foundation
import AppKit

@MainActor
final class VideoExporter {
    static let shared = VideoExporter()

    func exportClip(videoURL: URL, startTime: Double, endTime: Double, suggestedName: String) async throws -> URL {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.mpeg4Movie]
        panel.nameFieldStringValue = "\(suggestedName).mp4"
        guard panel.runModal() == .OK, let destination = panel.url else { throw ExportError.cancelled }

        let asset = AVAsset(url: videoURL)
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else { throw ExportError.unsupported }
        session.outputURL = destination
        session.outputFileType = .mp4
        session.timeRange = CMTimeRange(start: CMTime(seconds: max(0, startTime), preferredTimescale: 600), end: CMTime(seconds: max(startTime, endTime), preferredTimescale: 600))
        await session.export()
        if let error = session.error { throw error }
        return destination
    }

    enum ExportError: LocalizedError {
        case cancelled, unsupported
        var errorDescription: String? {
            switch self { case .cancelled: return "Esportazione annullata"; case .unsupported: return "Formato video non supportato" }
        }
    }
}
