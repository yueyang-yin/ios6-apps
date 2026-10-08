import SwiftUI

private enum WeatherModal: String, Identifiable {
  case search, about
  var id: String { rawValue }
}

struct WeatherRootView: View {
  @Bindable var store: WeatherStore
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var managingCities = false
  @State private var isFlipping = false
  @State private var modal: WeatherModal?

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Color.black.ignoresSafeArea()
        if managingCities {
          CityManagerView(
            store: store, done: { flip(false) }, addCity: { modal = .search },
            about: { modal = .about }
          )
          .transition(flipTransition)
        } else {
          weatherPages(size: geometry.size)
            .transition(flipTransition)
        }
      }
    }
    .disabled(isFlipping)
    .fullScreenCover(item: $modal) { destination in
      switch destination {
      case .search: CitySearchView(store: store)
      case .about: AboutView()
      }
    }
    .task(id: store.selectedCityID + String(store.demoMode)) {
      if let city = store.selectedCity {
        async let labels: Void = store.localizeCity(city)
        async let forecast: Void = store.refresh(city)
        _ = await (labels, forecast)
      }
    }
    .onChange(of: scenePhase) { _, phase in
      if phase == .active, let city = store.selectedCity { Task { await store.refresh(city) } }
    }
  }

  @ViewBuilder
  private func weatherPages(size: CGSize) -> some View {
    if store.cities.isEmpty {
      VStack(spacing: 22) {
        WeatherArtwork(condition: .clear).frame(width: 160)
        Text(L10n.text("Weather")).font(ClassicTheme.font(30, bold: true))
        Text(L10n.text("Add a city to see its forecast.")).font(ClassicTheme.font(18))
        Button(L10n.text("Add a City")) { flip(true) }.buttonStyle(ClassicButtonStyle(blue: true))
      }
    } else {
      VStack(spacing: 12) {
        TabView(selection: $store.selectedCityID) {
          ForEach(store.cities) { city in
            WeatherBoardView(
              city: city, report: store.report(for: city), unit: store.unit, demo: store.demoMode,
              loading: store.loading.contains(city.id), error: store.errors[city.id],
              availableHeight: size.height - 55, info: { flip(true) }, about: { modal = .about },
              refresh: { Task { await store.refresh(city, force: true) } }
            )
            .padding(.horizontal, size.width > 600 ? max(20, (size.width - 460) / 2) : 20)
            .accessibilityElement(children: .contain)
            .accessibilityHidden(city.id != store.selectedCityID || managingCities)
            .tag(city.id)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        HStack(spacing: 10) {
          ForEach(store.cities) { city in
            Button {
              withAnimation(.easeInOut(duration: 0.25)) { store.selectedCityID = city.id }
            } label: {
              if city.isLocal {
                Image(systemName: "location.fill").font(.system(size: 11))
              } else {
                Circle().frame(width: 7, height: 7)
              }
            }
            .foregroundStyle(store.selectedCityID == city.id ? .white : .white.opacity(0.35))
            .frame(minWidth: 24, minHeight: 30)
            .accessibilityLabel(L10n.format("Show %@", city.displayName()))
            .accessibilityAddTraits(store.selectedCityID == city.id ? .isSelected : [])
          }
        }
        .padding(.bottom, 5)
      }
    }
  }

  private func flip(_ value: Bool) {
    guard !isFlipping else { return }
    let arguments = ProcessInfo.processInfo.arguments
    let testing = arguments.contains("--uitesting") && !arguments.contains("--animate-flips")
    let animate = !reduceMotion && !testing
    isFlipping = animate
    withAnimation(animate ? .easeInOut(duration: 0.55) : nil) { managingCities = value }
    if animate {
      Task {
        try? await Task.sleep(for: .milliseconds(600))
        isFlipping = false
      }
    }
  }

  private var flipTransition: AnyTransition {
    .asymmetric(
      insertion: .modifier(active: FlipFace(angle: 180), identity: FlipFace(angle: 0)),
      removal: .modifier(active: FlipFace(angle: -180), identity: FlipFace(angle: 0))
    )
  }
}

private struct FlipFace: AnimatableModifier {
  var angle: Double
  var animatableData: Double {
    get { angle }
    set { angle = newValue }
  }

  func body(content: Content) -> some View {
    content
      .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.7)
      .opacity(abs(angle) < 90 ? 1 : 0)
  }
}

#Preview("Classic weather") {
  WeatherRootView(store: WeatherStore(arguments: ["--uitesting", "--demo"]))
    .preferredColorScheme(.dark)
}
