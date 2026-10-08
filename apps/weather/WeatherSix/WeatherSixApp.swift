import SwiftUI

@main
struct WeatherSixApp: App {
  @State private var store = WeatherStore()

  var body: some Scene {
    WindowGroup {
      WeatherRootView(store: store)
        .environment(\.locale, AppLanguage.current.locale)
        .preferredColorScheme(.dark)
        .tint(.white)
    }
  }
}
