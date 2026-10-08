import SwiftUI

@main
struct WeatherSixApp: App {
  @State private var store = WeatherStore()

  var body: some Scene {
    WindowGroup {
      WeatherRootView(store: store)
        .preferredColorScheme(.dark)
        .tint(.white)
    }
  }
}
