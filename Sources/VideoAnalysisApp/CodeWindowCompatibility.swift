import Foundation

struct CodeWindowInspection {
    let isNSKeyedArchive: Bool
    let topLevelKeys: [String]
    let nestedArchiveCount: Int
    let notes: String
}

enum CodeWindowCompatibility {
    static func inspect(url: URL) throws -> CodeWindowInspection {
        let data = try Data(contentsOf: url)
        let isArchive = data.starts(with: Data("bplist00".utf8))
        var keys: [String] = []
        var nested = 0
        if let propertyList = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil), let dictionary = propertyList as? [String: Any] {
            keys = dictionary.keys.sorted()
            nested = countDataObjects(dictionary)
        }
        return CodeWindowInspection(isNSKeyedArchive: isArchive, topLevelKeys: keys, nestedArchiveCount: nested, notes: isArchive ? "Archivio Apple NSKeyedArchiver rilevato; conversione completa dei pulsanti richiede verifica su file campione." : "Formato non riconosciuto")
    }

    private static func countDataObjects(_ value: Any) -> Int {
        if value is Data { return 1 }
        if let dictionary = value as? [String: Any] { return dictionary.values.reduce(0) { $0 + countDataObjects($1) } }
        if let array = value as? [Any] { return array.reduce(0) { $0 + countDataObjects($1) } }
        return 0
    }
}
