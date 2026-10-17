import SwiftUI

@main
struct StocksSixApp: App {
  @State private var store: StocksStore
  init() {
    let arguments = ProcessInfo.processInfo.arguments
    let testing = arguments.contains("--ui-testing")
    let demo = testing || arguments.contains("--demo")
    let defaults =
      demo
      ? UserDefaults(suiteName: testing ? "stocks-six-ui-tests" : "stocks-six-demo") : .standard
    if testing, !arguments.contains("--preserve-test-state") {
      defaults?.removePersistentDomain(forName: "stocks-six-ui-tests")
    }
    _store = State(initialValue: StocksStore(demo: demo, defaults: defaults))
  }
  var body: some Scene {
    WindowGroup {
      StocksRootView(store: store)
        .environment(\.locale, AppLanguage.current.locale)
        .preferredColorScheme(.dark)
        .tint(.white)
    }
  }
}
