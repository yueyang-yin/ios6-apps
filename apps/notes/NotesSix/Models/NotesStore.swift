import Foundation
import Observation

struct Note: Identifiable, Codable, Equatable {
  var id = UUID()
  var text: String
  var createdAt = Date.now
  var modifiedAt = Date.now

  var title: String {
    text.components(separatedBy: .newlines)
      .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })?
      .trimmingCharacters(in: .whitespaces) ?? L10n.text("New Note")
  }

  var isEmpty: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

enum NoteFont: String, Codable, CaseIterable {
  case noteworthy = "Noteworthy"
  case helvetica = "Helvetica"
  case markerFelt = "Marker Felt"

  var postScriptName: String {
    switch self {
    case .noteworthy: "Noteworthy-Light"
    case .helvetica: "HelveticaNeue"
    case .markerFelt: "MarkerFelt-Thin"
    }
  }
}

struct NotesArchive: Codable {
  var version = 1
  var notes: [Note] = []
  var font: NoteFont = .noteworthy
}

@MainActor
@Observable
final class NotesStore {
  private(set) var notes: [Note] = []
  private(set) var font = NoteFont.noteworthy
  private(set) var storageError: String?
  private(set) var canWrite = true
  @ObservationIgnored let fileURL: URL

  init(fileURL: URL = NotesStore.defaultURL(), seed: Bool = false) {
    self.fileURL = fileURL
    if FileManager.default.fileExists(atPath: fileURL.path) {
      do {
        let archive = try JSONDecoder().decode(NotesArchive.self, from: Data(contentsOf: fileURL))
        guard archive.version == 1 else { throw CocoaError(.fileReadCorruptFile) }
        notes = archive.notes
        font = archive.font
      } catch {
        canWrite = false
        storageError = L10n.text(
          "Your saved notes could not be read. The original file has been preserved.")
      }
    } else if seed {
      notes = Self.sampleNotes()
      persist()
    }
  }

  nonisolated static func defaultURL() -> URL {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    let name = ProcessInfo.processInfo.arguments.contains("--demo") ? "NotesSixDemo" : "NotesSix"
    return base.appendingPathComponent(name, isDirectory: true).appendingPathComponent("notes.json")
  }

  var sortedNotes: [Note] {
    notes.sorted {
      if $0.modifiedAt == $1.modifiedAt { return $0.id.uuidString < $1.id.uuidString }
      return $0.modifiedAt > $1.modifiedAt
    }
  }

  func matching(_ query: String) -> [Note] {
    let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else { return sortedNotes }
    return sortedNotes.filter { $0.text.localizedStandardContains(query) }
  }

  func note(_ id: UUID) -> Note? { notes.first { $0.id == id } }

  @discardableResult
  func create(now: Date = .now) -> UUID? {
    guard canWrite else { return nil }
    let note = Note(text: "", createdAt: now, modifiedAt: now)
    notes.append(note)
    persist()
    return note.id
  }

  func update(_ id: UUID, text: String, now: Date = .now) {
    guard canWrite, let index = notes.firstIndex(where: { $0.id == id }), notes[index].text != text
    else { return }
    notes[index].text = text
    notes[index].modifiedAt = now
    persist()
  }

  func delete(_ id: UUID) {
    guard canWrite else { return }
    notes.removeAll { $0.id == id }
    persist()
  }

  func discardEmpty(_ id: UUID) {
    if note(id)?.isEmpty == true { delete(id) }
  }

  func setFont(_ font: NoteFont) {
    guard canWrite else { return }
    self.font = font
    persist()
  }

  func persist() {
    guard canWrite else { return }
    do {
      try FileManager.default.createDirectory(
        at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
      let archive = NotesArchive(notes: notes, font: font)
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      try encoder.encode(archive).write(to: fileURL, options: .atomic)
      storageError = nil
    } catch {
      storageError = L10n.text(
        "Your latest changes could not be saved. Please free up storage and try again.")
    }
  }

  static func sampleNotes(language: AppLanguage = .current) -> [Note] {
    let texts = ["sample.welcome", "sample.weekend", "sample.shopping", "sample.ideas"]
    return texts.enumerated().map { index, key in
      let date = Date.now.addingTimeInterval(-Double(index) * 86_400)
      return Note(text: L10n.text(key, language: language), createdAt: date, modifiedAt: date)
    }
  }
}
