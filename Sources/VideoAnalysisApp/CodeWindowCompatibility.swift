import Foundation

struct CodeWindowInspection {
    let isNSKeyedArchive: Bool
    let topLevelKeys: [String]
    let nestedArchiveCount: Int
    let notes: String
}

enum CodeWindowImportError: LocalizedError {
    case invalidArchive
    case missingNestedArchive
    case noButtons

    var errorDescription: String? {
        switch self {
        case .invalidArchive: return "Il file non è un archivio .CWcode2SC valido."
        case .missingNestedArchive: return "Archivio Code Window interno non trovato."
        case .noButtons: return "Nessun pulsante di codifica trovato nella Code Window."
        }
    }
}

enum NativeCodeWindowImporter {
    /// Imports the Apple binary property-list archive used by Sportscode.
    /// The archive contains a second plist and UID references, so decoding it
    /// as ordinary JSON/XML would silently lose the Code Window relationships.
    static func importCodeWindow(at url: URL) throws -> CodeWindowModel {
        let data = try Data(contentsOf: url)
        let outer = try propertyListDictionary(data)
        guard let objects = outer["$objects"] as? [Any], objects.count > 3,
              let nestedData = objects[3] as? Data else {
            throw CodeWindowImportError.missingNestedArchive
        }
        let nested = try propertyListDictionary(nestedData)
        guard let nestedObjects = nested["$objects"] as? [Any],
              let top = nested["$top"] as? [String: Any] else {
            throw CodeWindowImportError.invalidArchive
        }

        let resolver = UIDResolver(objects: nestedObjects)
        guard let window = resolver.resolve(top) as? [String: Any] else { throw CodeWindowImportError.invalidArchive }
        let rawButtons = resolver.objects(in: window["m_codeButtons"])
        guard !rawButtons.isEmpty else { throw CodeWindowImportError.noButtons }

        var buttons: [CodeButton] = []
        var namesToIDs: [String: UUID] = [:]
        for raw in rawButtons {
            let name = raw.string("m_primaryName") ?? "Senza nome"
            let type = raw.int("m_codeButtonType")
            let hasLead = raw.bool("m_hasCustomLeadTime") == true
            let hasLag = raw.bool("m_hasLagTime") == true
            let mode: CodeButton.Mode
            switch type {
            case 1, 2, 3: mode = .instant
            default: mode = .toggle
            }
            var button = CodeButton(
                name: name,
                rowName: raw.string("m_secondaryName")?.isEmpty == false ? raw.string("m_secondaryName")! : name,
                colorHex: "#6E48AA",
                hotkey: hotkey(from: raw["m_hotkey"]),
                mode: mode,
                leadTime: hasLead ? raw.double("m_customLeadTime") : 0,
                lagTime: hasLag ? raw.double("m_lagTime") : 0
            )
            button.secondaryName = raw.string("m_secondaryName") ?? ""
            button.sportscodeType = type
            button.actionType = raw.int("m_actionType")
            button.showOutput = raw.bool("m_showOutput") ?? false
            button.populateTimeline = raw.bool("m_populateTimeline") ?? false
            button.script = script(from: raw["m_scriptData"])
            button.sourceIdentifier = name
            if hasLead { button.preSeconds = raw.double("m_customLeadTime") }
            buttons.append(button)
            namesToIDs[name] = button.id
        }

        var links: [CodeWindowLink] = []
        for raw in resolver.objects(in: window["m_codeButtonLinks"]) {
            let from = raw.string("m_fromButton") ?? buttonName(raw["m_fromButton"])
            let to = raw.string("m_toButton") ?? buttonName(raw["m_toButton"])
            guard let from, let to, let fromID = namesToIDs[from], let toID = namesToIDs[to] else { continue }
            links.append(CodeWindowLink(fromButtonID: fromID, toButtonID: toID, type: raw.int("m_type") ?? 1, label: raw.string("m_label")))
        }

        var categoryMap: [String: [UUID]] = [:]
        for button in buttons where !button.secondaryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            categoryMap[button.secondaryName, default: []].append(button.id)
        }
        let categories = categoryMap.keys.sorted().map { CodeWindowCategory(name: $0, buttonIDs: categoryMap[$0] ?? []) }
        let name = url.deletingPathExtension().lastPathComponent
        let globalLead = window.double("m_defaultLeadTime")
        return CodeWindowModel(name: name, buttons: buttons, links: links, categories: categories, globalLeadTime: globalLead, globalLagTime: 0, sourceFormat: ".CWcode2SC", sourceArchiveData: data)
    }

    private static func propertyListDictionary(_ data: Data) throws -> [String: Any] {
        guard let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let dictionary = plist as? [String: Any] else { throw CodeWindowImportError.invalidArchive }
        return dictionary
    }

    private static func hotkey(from value: Any?) -> String {
        guard let dictionary = value as? [String: Any], let event = dictionary["m_keyEvent"] as? [String: Any] else { return "" }
        return event.string("NSUnmodKeys") ?? ""
    }

    private static func script(from value: Any?) -> String? {
        guard let dictionary = value as? [String: Any] else { return nil }
        let code = dictionary.string("script_code")?.trimmingCharacters(in: .whitespacesAndNewlines)
        return code?.isEmpty == false ? code : nil
    }

    private static func buttonName(_ value: Any?) -> String? {
        (value as? [String: Any])?.string("m_primaryName")
    }
}

private struct UIDResolver {
    let objects: [Any]

    func resolve(_ value: Any?, depth: Int = 0) -> Any? {
        guard let value, depth < 100 else { return nil }
        if let index = uidIndex(value), index < objects.count {
            return resolve(objects[index], depth: depth + 1)
        }
        if let dictionary = value as? [String: Any] {
            var resolved: [String: Any] = [:]
            for (key, item) in dictionary {
                if let item = resolve(item, depth: depth + 1) { resolved[key] = item }
            }
            return resolved
        }
        if let array = value as? [Any] {
            return array.compactMap { resolve($0, depth: depth + 1) }
        }
        return value
    }

    func objects(in value: Any?) -> [[String: Any]] {
        guard let container = (value as? [String: Any]) ?? (resolve(value) as? [String: Any]), let array = container["NS.objects"] as? [Any] else { return [] }
        return array.compactMap { resolve($0) as? [String: Any] }
    }

    private func uidIndex(_ value: Any) -> Int? {
        if value is [String: Any] || value is [Any] || value is Data { return nil }
        let description = String(describing: value)
        guard description.contains("CFKeyedArchiverUID"), let range = description.range(of: "value = ") else { return nil }
        let suffix = description[range.upperBound...]
        let digits = suffix.prefix { $0.isNumber }
        return Int(digits)
    }
}

private extension Dictionary where Key == String, Value == Any {
    func string(_ key: String) -> String? { self[key] as? String }
    func double(_ key: String) -> Double { (self[key] as? NSNumber)?.doubleValue ?? (self[key] as? Double ?? 0) }
    func int(_ key: String) -> Int? { (self[key] as? NSNumber)?.intValue ?? (self[key] as? Int) }
    func bool(_ key: String) -> Bool? { (self[key] as? NSNumber)?.boolValue ?? (self[key] as? Bool) }
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
