import SwiftUI

@main
struct CalculatorSixApp: App {
  @State private var calculator = CalculatorEngine()

  var body: some Scene {
    WindowGroup {
      CalculatorRootView(calculator: calculator)
        .environment(\.locale, AppLanguage.current.locale)
        .preferredColorScheme(.dark)
    }
  }
}
