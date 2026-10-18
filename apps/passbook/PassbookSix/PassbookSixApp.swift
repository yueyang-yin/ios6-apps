import SwiftUI

@main
struct PassbookSixApp: App {
  @State private var store: PassStore
  init() {
    let arguments = ProcessInfo.processInfo.arguments
    let testing = arguments.contains("--ui-testing")
    let demo = arguments.contains("--demo")
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    let directory =
      testing
      ? base.appendingPathComponent("PassbookSix-UI")
      : demo ? base.appendingPathComponent("PassbookSix-Demo") : nil
    if testing, !arguments.contains("--preserve-test-state"), let directory {
      try? FileManager.default.removeItem(at: directory)
    }
    _store = State(initialValue: PassStore(directory: directory, demo: demo))
  }
  var body: some Scene {
    WindowGroup { PassbookRootView(store: store).tint(.white) }
  }
}
