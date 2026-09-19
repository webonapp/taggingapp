import Foundation
import Combine

@MainActor
final class UndoRedoController: ObservableObject {
    private var undoStack: [Data] = []
    private var redoStack: [Data] = []

    func record<T: Encodable>(_ value: T) {
        guard let data = try? JSONEncoder.projectEncoder.encode(value) else { return }
        undoStack.append(data)
        if undoStack.count > 100 { undoStack.removeFirst() }
        redoStack.removeAll()
    }

    func undo<T: Codable>(_ current: T, as type: T.Type) -> T? {
        guard let previous = undoStack.popLast(), let old = try? JSONDecoder.projectDecoder.decode(T.self, from: previous), let currentData = try? JSONEncoder.projectEncoder.encode(current) else { return nil }
        redoStack.append(currentData)
        return old
    }

    func redo<T: Codable>(_ current: T, as type: T.Type) -> T? {
        guard let next = redoStack.popLast(), let value = try? JSONDecoder.projectDecoder.decode(T.self, from: next), let currentData = try? JSONEncoder.projectEncoder.encode(current) else { return nil }
        undoStack.append(currentData)
        return value
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
}
