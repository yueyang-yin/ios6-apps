import SwiftUI

struct CityManagerView: View {
  @Bindable var store: WeatherStore
  var done: () -> Void
  var addCity: () -> Void
  var about: () -> Void
  @State private var location = LocationService()
  @State private var pendingDeletionID: String?
  @Environment(\.openURL) private var openURL

  var body: some View {
    ZStack {
      LinenBackground()
      VStack(spacing: 0) {
        ClassicNavigationBar(
          title: "Weather",
          leading: {
            Button(action: addCity) { Text("+").font(.system(size: 28, weight: .bold)) }
              .buttonStyle(ClassicButtonStyle()).accessibilityLabel("Add city")
              .accessibilityIdentifier("addCity")
          },
          trailing: {
            Button("Done", action: done).buttonStyle(ClassicButtonStyle(blue: true))
              .accessibilityIdentifier("doneManaging")
          })
        ScrollView {
          VStack(spacing: 18) {
            cityList
            unitPicker
            locationButton
            modePicker
            Button(action: about) {
              VStack(spacing: 4) {
                Text("powered by").font(.custom("HelveticaNeue-Bold", size: 12)).foregroundStyle(
                  .white.opacity(0.7))
                Text("Open-Meteo").font(.custom("Georgia-Bold", size: 27)).foregroundStyle(.white)
                Text("The weather. Just like you remember.").font(ClassicTheme.font(12))
                  .foregroundStyle(.white.opacity(0.55))
              }.frame(maxWidth: .infinity).padding(.vertical, 6)
            }.accessibilityLabel("About Weather and data sources")
          }.padding(20).frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
      }
    }
    .onAppear {
      location.onCity = { city in
        store.setLocal(city)
        Task { await store.refresh(city, force: true) }
        done()
      }
    }
    .onDisappear { location.cancel() }
  }

  private var cityList: some View {
    VStack(spacing: 0) {
      if store.cities.isEmpty {
        Button("Add your first city", action: addCity)
          .font(.custom("HelveticaNeue-Bold", size: 18)).foregroundStyle(Color(hex: 0x324b70))
          .frame(maxWidth: .infinity).frame(height: 80).background(.white)
      } else {
        List {
          ForEach(store.cities) { city in
            HStack(spacing: 8) {
              Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                  pendingDeletionID = pendingDeletionID == city.id ? nil : city.id
                }
              } label: {
                ZStack {
                  Circle().fill(
                    LinearGradient(
                      colors: [Color(hex: 0xf27580), Color(hex: 0xb00c23), Color(hex: 0x8d1424)],
                      startPoint: .top, endPoint: .bottom))
                  Circle().stroke(.white, lineWidth: 2)
                  Rectangle().fill(.white).frame(width: 13, height: 3)
                }.frame(width: 25, height: 25)
                  .rotationEffect(.degrees(pendingDeletionID == city.id ? -90 : 0))
                  .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                  .frame(width: 32, height: 40)
              }.buttonStyle(.plain).accessibilityLabel("Delete \(city.name)")
                .accessibilityIdentifier("deleteCity_\(city.id)")
              Button {
                store.selectedCityID = city.id
                done()
              } label: {
                HStack(spacing: 7) {
                  if city.isLocal { Image(systemName: "location.fill").font(.system(size: 13)) }
                  Text(city.name).font(.custom("HelveticaNeue-Bold", size: 20)).lineLimit(1)
                }.frame(maxWidth: .infinity, alignment: .leading)
              }.buttonStyle(.plain).foregroundStyle(Color(hex: 0x263d5d))
                .accessibilityIdentifier("cityRow_\(city.id)")
              if pendingDeletionID == city.id {
                Button("Delete") {
                  withAnimation(.easeInOut(duration: 0.2)) {
                    store.remove(city)
                    pendingDeletionID = nil
                  }
                }
                .font(.custom("HelveticaNeue-Bold", size: 14))
                .foregroundStyle(.white).padding(.horizontal, 10).frame(height: 31)
                .background(
                  LinearGradient(
                    colors: [Color(hex: 0xed6c72), Color(hex: 0xba1a26), Color(hex: 0x930f1b)],
                    startPoint: .top, endPoint: .bottom)
                )
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .buttonStyle(.plain).accessibilityIdentifier("confirmDelete_\(city.id)")
              }
            }
            .listRowBackground(Color.white)
            .listRowInsets(EdgeInsets(top: 5, leading: 7, bottom: 5, trailing: 7))
            .listRowSeparatorTint(Color(hex: 0xc9c9c9))
            .moveDisabled(city.isLocal)
          }
          .onMove { store.move($0, to: $1) }
        }
        .environment(\.editMode, .constant(.active))
        .environment(\.colorScheme, .light)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .frame(height: CGFloat(min(max(store.cities.count, 4), 7)) * 57)
      }
    }
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .overlay { RoundedRectangle(cornerRadius: 12).stroke(.black.opacity(0.7), lineWidth: 1) }
    .shadow(color: .black.opacity(0.35), radius: 2, y: 2)
  }

  private var unitPicker: some View {
    HStack(spacing: 0) {
      ForEach(TemperatureUnit.allCases, id: \.self) { unit in
        Button {
          store.unit = unit
        } label: {
          Text(unit.symbol).font(.custom("HelveticaNeue-Bold", size: 22))
            .foregroundStyle(store.unit == unit ? .white : Color(hex: 0x777777))
            .shadow(
              color: store.unit == unit ? .black.opacity(0.4) : .white, radius: 0,
              y: store.unit == unit ? -1 : 1
            )
            .frame(maxWidth: .infinity).frame(height: 47)
            .background(
              LinearGradient(
                stops: store.unit == unit
                  ? [
                    .init(color: Color(hex: 0x1d62c9), location: 0),
                    .init(color: Color(hex: 0x4488f1), location: 0.5),
                    .init(color: Color(hex: 0x5a9bfa), location: 0.51),
                    .init(color: Color(hex: 0x74b0ff), location: 1),
                  ]
                  : [
                    .init(color: .white, location: 0),
                    .init(color: Color(hex: 0xededed), location: 0.5),
                    .init(color: Color(hex: 0xd1d1d1), location: 1),
                  ], startPoint: .top, endPoint: .bottom))
        }.accessibilityIdentifier(unit == .celsius ? "celsius" : "fahrenheit")
          .accessibilityAddTraits(store.unit == unit ? .isSelected : [])
        if unit == .fahrenheit { Color.black.opacity(0.3).frame(width: 1) }
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 10))
    .overlay { RoundedRectangle(cornerRadius: 10).stroke(.black.opacity(0.6), lineWidth: 1) }
  }

  private var locationButton: some View {
    VStack(spacing: 8) {
      Button {
        Task { await location.request() }
      } label: {
        HStack(spacing: 8) {
          if location.isRequesting {
            ProgressView().tint(Color(hex: 0x324b70))
          } else {
            Image(systemName: "location.fill")
          }
          Text(location.isRequesting ? "Finding your location…" : "Use Current Location")
        }.font(.custom("HelveticaNeue-Bold", size: 16))
          .foregroundStyle(Color(hex: 0x324b70)).frame(maxWidth: .infinity).frame(height: 46)
          .background(
            LinearGradient(
              colors: [.white, Color(hex: 0xd6d6d6)], startPoint: .top, endPoint: .bottom)
          )
          .clipShape(RoundedRectangle(cornerRadius: 9))
      }.disabled(location.isRequesting).accessibilityIdentifier("currentLocation")
      if let message = location.message {
        Text(message).font(ClassicTheme.font(14)).foregroundStyle(.white.opacity(0.8))
          .multilineTextAlignment(.center)
          .accessibilityIdentifier("locationError")
      }
      if location.showSettings {
        Button("Open Settings") {
          if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
        }.buttonStyle(ClassicButtonStyle(blue: true)).accessibilityIdentifier("locationSettings")
      }
    }
  }

  private var modePicker: some View {
    HStack {
      Text("Demo Weather").font(.custom("HelveticaNeue-Bold", size: 16))
      Spacer()
      Toggle("Demo Weather", isOn: $store.demoMode).labelsHidden().tint(Color(hex: 0x4388e9))
        .accessibilityIdentifier("demoWeather")
    }
    .padding(.horizontal, 14).padding(.vertical, 9)
    .background(.black.opacity(0.2)).clipShape(RoundedRectangle(cornerRadius: 9))
  }
}

struct CitySearchView: View {
  @Bindable var store: WeatherStore
  @Environment(\.dismiss) private var dismiss
  @State private var query = ""
  @State private var results: [WeatherCity] = []
  @State private var searching = false
  @State private var error: String?
  @State private var searchID: UUID?
  @FocusState private var focused: Bool

  private static let demoCities: [WeatherCity] =
    WeatherCity.defaults + [
      .init(
        id: "tokyo", name: "Tokyo", country: "Japan", latitude: 35.6762, longitude: 139.6503,
        timeZone: "Asia/Tokyo"),
      .init(
        id: "paris", name: "Paris", country: "France", latitude: 48.8534, longitude: 2.3488,
        timeZone: "Europe/Paris"),
      .init(
        id: "new-york", name: "New York", country: "United States", latitude: 40.7128,
        longitude: -74.006, timeZone: "America/New_York"),
      .init(
        id: "san-francisco", name: "San Francisco", country: "California, US", latitude: 37.7749,
        longitude: -122.4194, timeZone: "America/Los_Angeles"),
      .init(
        id: "sydney", name: "Sydney", country: "Australia", latitude: -33.8688, longitude: 151.2093,
        timeZone: "Australia/Sydney"),
      .init(
        id: "guildford", name: "Guildford", country: "United Kingdom", latitude: 51.2362,
        longitude: -0.5704, timeZone: "Europe/London"),
    ]

  var body: some View {
    ZStack {
      LinenBackground()
      VStack(spacing: 0) {
        ClassicNavigationBar(
          title: "Add City", leading: { EmptyView() },
          trailing: {
            Button("Cancel") { dismiss() }.buttonStyle(ClassicButtonStyle())
          })
        HStack(spacing: 8) {
          Button {
            focused = false
            Task { await search() }
          } label: {
            Image(systemName: "magnifyingglass").foregroundStyle(Color.gray)
          }.accessibilityLabel("Search places")
          TextField("City, district or postal code", text: $query)
            .font(.custom("HelveticaNeue", size: 17)).foregroundStyle(.black).tint(
              Color(hex: 0x326bd1)
            )
            .autocorrectionDisabled().textInputAutocapitalization(.words).submitLabel(.search)
            .focused($focused).accessibilityIdentifier("citySearch")
            .onSubmit {
              focused = false
              Task { await search() }
            }
          if !query.isEmpty {
            Button {
              query = ""
            } label: {
              Image(systemName: "xmark.circle.fill").foregroundStyle(.gray)
            }.accessibilityLabel("Clear search")
          }
        }.padding(10).background(.white).clipShape(RoundedRectangle(cornerRadius: 9)).padding(14)
        if searching { ProgressView().tint(.white).padding(20) }
        if let error {
          VStack(spacing: 12) {
            Text(error).font(ClassicTheme.font(16)).multilineTextAlignment(.center)
            Button("Try Again") { Task { await search() } }.buttonStyle(
              ClassicButtonStyle(blue: true))
          }.padding(20)
        }
        ScrollView {
          LazyVStack(spacing: 0) {
            ForEach(results) { city in
              Button {
                store.add(city)
                dismiss()
              } label: {
                VStack(alignment: .leading, spacing: 4) {
                  Text(city.name).font(.custom("HelveticaNeue-Bold", size: 19)).foregroundStyle(
                    Color(hex: 0x263d5d))
                  Text(city.country).font(ClassicTheme.font(14)).foregroundStyle(.gray)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(15).background(.white)
              }.accessibilityIdentifier("searchResult_\(city.id)")
              Color(hex: 0xc9c9c9).frame(height: 1)
            }
          }.clipShape(RoundedRectangle(cornerRadius: 10)).padding(.horizontal, 14)
          if !searching && error == nil && results.isEmpty {
            Text(
              query.trimmingCharacters(in: .whitespacesAndNewlines).count < 2
                ? "Enter a city, district or postal code."
                : "No places found. Try adding a city or region."
            )
            .font(ClassicTheme.font(16)).foregroundStyle(.white.opacity(0.7)).padding(24)
          }
        }
        if !store.demoMode {
          Link(
            "© OpenStreetMap contributors",
            destination: URL(string: "https://www.openstreetmap.org/copyright")!
          ).font(ClassicTheme.font(11)).foregroundStyle(.white.opacity(0.65)).padding(.vertical, 8)
        }
      }
    }
    .task { focused = true }
    .task(id: query + String(store.demoMode)) {
      results = []
      error = nil
      searching = false
      searchID = nil
      guard query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else { return }
      do { try await Task.sleep(for: .milliseconds(700)) } catch { return }
      await search()
    }
  }

  private func search() async {
    let value = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard value.count >= 2 else { return }
    let id = UUID()
    searchID = id
    searching = true
    error = nil
    defer { if searchID == id { searching = false } }
    do {
      let found =
        store.demoMode
        ? Self.demoCities.filter { $0.name.localizedCaseInsensitiveContains(value) }
        : try await store.service.search(value)
      guard !Task.isCancelled, searchID == id,
        value == query.trimmingCharacters(in: .whitespacesAndNewlines)
      else { return }
      results = found
    } catch {
      guard !Task.isCancelled, searchID == id else { return }
      self.error = "Place search is unavailable. Check your connection and try again."
    }
  }
}

struct AboutView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    ZStack {
      LinenBackground()
      VStack(spacing: 0) {
        ClassicNavigationBar(
          title: "About Weather", leading: { EmptyView() },
          trailing: {
            Button("Done") { dismiss() }.buttonStyle(ClassicButtonStyle(blue: true))
              .accessibilityIdentifier("closeAbout")
          })
        ScrollView {
          VStack(spacing: 20) {
            WeatherArtwork(condition: .clear).frame(width: 170, height: 135)
            Text("Weather, circa 2012.").font(ClassicTheme.font(26, bold: true))
            Text(
              "A little sunshine. A familiar blue board.\nThe classic iOS 6 weather experience, rebuilt."
            )
            .font(ClassicTheme.font(18)).multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 14) {
              Text("Weather data").font(.custom("HelveticaNeue-Bold", size: 17))
              Link("Open-Meteo · Forecasts", destination: URL(string: "https://open-meteo.com/")!)
              Link("GeoNames · City search", destination: URL(string: "https://www.geonames.org/")!)
              Link(
                "OpenStreetMap · ODbL",
                destination: URL(string: "https://www.openstreetmap.org/copyright")!)
              Link("Photon · Geocoding", destination: URL(string: "https://photon.komoot.io/")!)
              Link(
                "Forecast license · CC BY 4.0",
                destination: URL(string: "https://creativecommons.org/licenses/by/4.0/")!)
              Text(
                "Y! recalls the original interface. Current forecasts are provided by Open-Meteo. Demo Weather uses sample forecasts and is always labeled Demo."
              )
              .font(ClassicTheme.font(14)).foregroundStyle(.white.opacity(0.65))
            }.font(ClassicTheme.font(16)).padding(20).background(.black.opacity(0.2)).clipShape(
              RoundedRectangle(cornerRadius: 12))
            Text("Swipe between cities. Scroll the hours.\nTap the update time to refresh.").font(
              ClassicTheme.font(15)
            ).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.6))
          }.padding(24).frame(maxWidth: 520).frame(maxWidth: .infinity)
        }
      }
    }.preferredColorScheme(.dark)
  }
}
