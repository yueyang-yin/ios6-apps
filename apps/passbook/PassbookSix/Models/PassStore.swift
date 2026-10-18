import Foundation
import Observation

@MainActor @Observable
final class PassStore {
  private(set) var passes: [PocketPass] = []
  var errorMessage: String?
  private let fileURL: URL
  private var hasUnreadableData = false

  init(directory: URL? = nil, demo: Bool = false) {
    let base =
      directory
      ?? FileManager.default.urls(
        for: .applicationSupportDirectory,
        in: .userDomainMask)[0].appendingPathComponent("PassbookSix", isDirectory: true)
    fileURL = base.appendingPathComponent("passes.json")
    do {
      try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
      if FileManager.default.fileExists(atPath: fileURL.path) {
        passes = try JSONDecoder().decode([PocketPass].self, from: Data(contentsOf: fileURL))
        if demo, !passes.isEmpty, passes.allSatisfy(\.isDemo),
          passes.contains(where: { $0.sampleStyle == nil })
        {
          passes = PassSamples.collection
          try write(passes)
        }
      } else if demo {
        passes = PassSamples.collection
        try write(passes)
      }
    } catch {
      hasUnreadableData = true
      errorMessage = L10n.text("Could not load passes")
    }
  }

  func pass(_ id: String) -> PocketPass? { passes.first { $0.id == id } }

  @discardableResult
  func save(_ pass: PocketPass) -> Bool {
    var updated = passes
    if let index = updated.firstIndex(where: { $0.id == pass.id }) {
      updated[index] = pass
    } else {
      updated.append(pass)
    }
    return commit(updated)
  }

  @discardableResult
  func remove(_ id: String) -> Bool { commit(passes.filter { $0.id != id }) }

  func move(_ id: String, by offset: Int) {
    guard let index = passes.firstIndex(where: { $0.id == id }),
      passes.indices.contains(index + offset)
    else { return }
    var updated = passes
    updated.swapAt(index, index + offset)
    _ = commit(updated)
  }

  func addSamples() {
    var updated = passes
    for var pass in PassSamples.collection {
      if let index = updated.firstIndex(where: { $0.id == pass.id }) {
        pass.userNote = updated[index].userNote
        updated[index] = pass
      } else {
        updated.append(pass)
      }
    }
    _ = commit(updated)
  }

  func sourceURL(for pass: PocketPass) -> URL? {
    pass.sourceFilename.map { fileURL.deletingLastPathComponent().appendingPathComponent($0) }
  }

  func importPass(from url: URL) {
    let access = url.startAccessingSecurityScopedResource()
    defer { if access { url.stopAccessingSecurityScopedResource() } }
    do {
      let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
      guard size <= 20_000_000 else { throw PassImportError.tooLarge }
      let data = try Data(contentsOf: url, options: .mappedIfSafe)
      var pass = try PassImporter.decode(data)
      pass.userNote = self.pass(pass.id)?.userNote ?? ""
      // Use a new filename on replacement so a failed metadata write preserves the old pass.
      let name = "\(UUID().uuidString).pkpass"
      let destination = fileURL.deletingLastPathComponent().appendingPathComponent(name)
      try data.write(to: destination, options: .atomic)
      pass.sourceFilename = name
      if !save(pass) { try? FileManager.default.removeItem(at: destination) }
    } catch { errorMessage = L10n.text("Could not import pass") }
  }

  private func commit(_ updated: [PocketPass]) -> Bool {
    do {
      if hasUnreadableData, FileManager.default.fileExists(atPath: fileURL.path) {
        let backup = fileURL.deletingLastPathComponent().appendingPathComponent(
          "unreadable-\(UUID().uuidString).json")
        try FileManager.default.copyItem(at: fileURL, to: backup)
      }
      try write(updated)
      hasUnreadableData = false
      let kept = Set(updated.compactMap(\.sourceFilename))
      let removed = passes.compactMap(\.sourceFilename).filter { !kept.contains($0) }
      passes = updated
      for name in removed {
        try? FileManager.default.removeItem(
          at: fileURL.deletingLastPathComponent().appendingPathComponent(name))
      }
      return true
    } catch {
      errorMessage = L10n.text("Could not save passes")
      return false
    }
  }

  private func write(_ values: [PocketPass]) throws {
    try JSONEncoder().encode(values).write(to: fileURL, options: .atomic)
  }
}
