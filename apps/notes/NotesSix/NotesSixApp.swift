import SwiftUI

@main
struct NotesSixApp: App {
  @State private var store: NotesStore

  init() {
    let arguments = ProcessInfo.processInfo.arguments
    var url = NotesStore.defaultURL()
    if arguments.contains("--uitesting") {
      url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("NotesSixUITests/notes.json")
      if arguments.contains("--reset-notes") { try? FileManager.default.removeItem(at: url) }
    }
    let store = NotesStore(fileURL: url, seed: arguments.contains("--demo"))
    if arguments.contains("--uitesting"), arguments.contains("--long-list"),
      arguments.contains("--reset-notes")
    {
      for index in 0..<24 {
        if let id = store.create() { store.update(id, text: "Archive entry \(index)") }
      }
    }
    _store = State(initialValue: store)
  }

  var body: some Scene {
    WindowGroup {
      NotesRootView(store: store)
        .environment(\.locale, AppLanguage.current.locale)
        .preferredColorScheme(.light)
        .environment(\.colorScheme, .light)
        .tint(ClassicTheme.ink)
    }
  }
}
