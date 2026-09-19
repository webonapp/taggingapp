import Foundation

struct ImportedSportscodePackage {
    let packageURL: URL
    let videoURL: URL?
    let timelineURL: URL?
    let timeline: TimelineModel?
}

enum SportscodePackageImporter {
    static func importPackage(at url: URL) throws -> ImportedSportscodePackage {
        let packageURL = url.standardizedFileURL
        let videoDirectory = packageURL.appendingPathComponent("Video", isDirectory: true)
        let timelineURL = try FileManager.default.contentsOfDirectory(at: packageURL, includingPropertiesForKeys: nil)
            .first(where: { $0.pathExtension.lowercased() == "sctimeline" })
        let videoURL = try findFirstVideo(in: videoDirectory)
        let timeline = try timelineURL.map { try SportscodeInterop.importTimeline(from: $0) }
        return ImportedSportscodePackage(packageURL: packageURL, videoURL: videoURL, timelineURL: timelineURL, timeline: timeline)
    }

    private static func findFirstVideo(in directory: URL) throws -> URL? {
        guard FileManager.default.fileExists(atPath: directory.path) else { return nil }
        let keys: [URLResourceKey] = [.isRegularFileKey]
        let files = try FileManager.default.subpathsOfDirectory(atPath: directory.path)
        return files.map { directory.appendingPathComponent($0) }
            .first { url in
                guard let values = try? url.resourceValues(forKeys: Set(keys)), values.isRegularFile == true else { return false }
                return ["mov", "mp4", "m4v"].contains(url.pathExtension.lowercased())
            }
    }
}
