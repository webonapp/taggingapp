import AVFoundation
import AppKit
import CoreVideo
import Foundation

@MainActor
enum SlideExporter {
    static func export(imageURL: URL, duration: Double, to destination: URL) async throws {
        guard let image = NSImage(contentsOf: imageURL), let bitmap = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { throw ExportError.invalidImage }
        let width = max(2, bitmap.width - bitmap.width % 2)
        let height = max(2, bitmap.height - bitmap.height % 2)
        let writer = try AVAssetWriter(outputURL: destination, fileType: .mp4)
        let settings: [String: Any] = [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: width, AVVideoHeightKey: height]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB, kCVPixelBufferWidthKey as String: width, kCVPixelBufferHeightKey as String: height])
        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        let fps = 30
        let frameCount = max(1, Int(duration * Double(fps)))
        guard let pool = adaptor.pixelBufferPool else { throw ExportError.writer }
        for frame in 0..<frameCount {
            while !input.isReadyForMoreMediaData { try await Task.sleep(for: .milliseconds(2)) }
            var buffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)
            guard let buffer else { throw ExportError.writer }
            CVPixelBufferLockBaseAddress(buffer, [])
            if let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) {
                context.setFillColor(NSColor.black.cgColor)
                context.fill(CGRect(x: 0, y: 0, width: width, height: height))
                context.draw(bitmap, in: CGRect(x: 0, y: 0, width: width, height: height))
            }
            CVPixelBufferUnlockBaseAddress(buffer, [])
            adaptor.append(buffer, withPresentationTime: CMTime(value: CMTimeValue(frame), timescale: CMTimeScale(fps)))
        }
        input.markAsFinished()
        await writer.finishWriting()
        if let error = writer.error { throw error }
    }

    enum ExportError: LocalizedError { case invalidImage, writer; var errorDescription: String? { "Impossibile creare il video della slide" } }
}
