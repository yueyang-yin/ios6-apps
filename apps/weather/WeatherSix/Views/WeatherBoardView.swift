import SwiftUI

struct WeatherBoardView: View {
  let city: WeatherCity
  let report: WeatherReport?
  let unit: TemperatureUnit
  let demo: Bool
  let loading: Bool
  let error: String?
  let availableHeight: CGFloat
  var info: () -> Void
  var about: () -> Void
  var refresh: () -> Void
  @State private var showHourly = false

  private var isDay: Bool { report?.isDay ?? true }
  private var compact: Bool { availableHeight < 680 }
  private var rowHeight: CGFloat { compact ? 35 : 49 }
  private var hourlyHeight: CGFloat { compact ? 88 : 106 }
  private var heroHeight: CGFloat {
    compact ? 228 : min(274, max(230, availableHeight - 450))
  }
  private var artworkSize: CGSize {
    let height = heroHeight - (compact ? 72 : 92)
    return CGSize(width: height * 160 / 130, height: height)
  }
  private let artworkLift: CGFloat = 52
  private var artworkClearance: CGFloat { artworkSize.height - artworkLift + 8 }

  var body: some View {
    VStack(spacing: 0) {
      Spacer(minLength: artworkLift)
      VStack(spacing: 0) {
        hero
        ClassicRule()
        if compact && showHourly {
          hourlyList
        } else {
          hourlyStrip
          ClassicRule()
          dailyForecast
        }
        ClassicRule()
        footer
      }
      .background(
        LinearGradient(
          colors: ClassicTheme.blue(isDay), startPoint: .topLeading, endPoint: .bottomTrailing)
      )
      .clipShape(RoundedRectangle(cornerRadius: 15))
      .overlay {
        RoundedRectangle(cornerRadius: 15)
          .strokeBorder(
            LinearGradient(
              colors: [.white.opacity(0.45), .white.opacity(0.10), .white.opacity(0.40)],
              startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2.5
          )
          .allowsHitTesting(false)
      }
      .overlay(alignment: .top) {
        if let report {
          WeatherArtwork(condition: report.condition, isDay: report.isDay)
            .frame(width: artworkSize.width, height: artworkSize.height)
            .offset(y: -artworkLift)
            .accessibilityIdentifier("heroArtwork_\(city.id)")
            .allowsHitTesting(false)
        }
      }
      .shadow(color: .black.opacity(0.5), radius: 12, y: 6)
      Spacer(minLength: 4)
    }
  }

  private var hero: some View {
    VStack(spacing: 0) {
      // Reserve the full artwork footprint before laying out any header text.
      Spacer(minLength: artworkClearance)
      HStack(alignment: .bottom, spacing: 6) {
        VStack(alignment: .leading, spacing: 5) {
          HStack(spacing: 5) {
            if city.isLocal { Image(systemName: "location.fill").font(.system(size: 12)) }
            Text(city.displayName()).font(ClassicTheme.font(compact ? 21 : 25, bold: true))
              .lineLimit(1)
              .minimumScaleFactor(0.65)
              .accessibilityIdentifier("cityName_\(city.id)")
          }
          if compact {
            Button(L10n.text(showHourly ? "Daily" : "Hourly")) {
              withAnimation(.easeInOut(duration: 0.25)) { showHourly.toggle() }
            }.font(ClassicTheme.font(16)).accessibilityIdentifier("hourlyToggle")
          } else {
            TimelineView(.periodic(from: .now, by: 60)) { timeline in
              Text(
                WeatherDate.string(
                  timeline.date, format: "h:mm a", timeZone: report?.timeZone ?? city.timeZone
                ).lowercased()
              )
              .font(ClassicTheme.font(19))
            }
          }
        }
        Spacer(minLength: 0)
        VStack(alignment: .trailing, spacing: 0) {
          Text(report.map { unit.formatted($0.temperature) } ?? "—°")
            .font(ClassicTheme.font(compact ? 66 : 82))
            .tracking(-3)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .accessibilityIdentifier("currentTemperature_\(city.id)")
            .accessibilityLabel(
              report.map {
                L10n.format(
                  unit == .celsius ? "%lld degrees celsius" : "%lld degrees fahrenheit",
                  unit.value($0.temperature))
              }
                ?? L10n.text("Temperature unavailable"))
          HStack(spacing: 8) {
            if let today = report?.daily.first {
              Text(L10n.format("H: %lld", unit.value(today.high))).foregroundStyle(.white)
              Text(L10n.format("L: %lld", unit.value(today.low))).foregroundStyle(
                .white.opacity(0.45))
            }
          }.font(ClassicTheme.font(compact ? 17 : 20))
        }
      }
      .padding(.horizontal, compact ? 14 : 17)
      .padding(.bottom, 13)
    }
    .frame(height: heroHeight)
    .shadow(color: .black.opacity(0.5), radius: 0.7, y: -1)
  }

  @ViewBuilder
  private var hourlyStrip: some View {
    if let report {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 0) {
          ForEach(report.hourly) { hour in
            VStack(spacing: 0) {
              Text(WeatherDate.string(hour.date, format: "ha", timeZone: report.timeZone))
                .font(ClassicTheme.font(14)).foregroundStyle(.white.opacity(0.5))
              WeatherArtwork(condition: hour.condition, isDay: hour.isDay).frame(
                width: 44, height: 39)
              Text(unit.formatted(hour.temperature)).font(ClassicTheme.font(24))
              if hour.precipitation > 0 {
                Text("\(hour.precipitation)%").font(ClassicTheme.font(10, bold: true))
                  .foregroundStyle(ClassicTheme.lowTemperature)
              }
            }
            .frame(width: compact ? 53 : 64, height: hourlyHeight)
            .accessibilityElement(children: .combine)
          }
        }.padding(.horizontal, 8)
      }
      .background(.black.opacity(0.23))
      .accessibilityIdentifier("hourlyForecast")
    } else {
      unavailable.frame(height: hourlyHeight + rowHeight * 5)
    }
  }

  private var dailyForecast: some View {
    VStack(spacing: 0) {
      ForEach(Array((report?.daily.dropFirst() ?? []).enumerated()), id: \.element.id) {
        index, day in
        HStack(spacing: 0) {
          Text(
            WeatherDate.string(
              day.date, format: "EEEE", timeZone: report?.timeZone ?? city.timeZone)
          )
          .font(ClassicTheme.font(compact ? 18 : 21)).frame(
            maxWidth: .infinity, alignment: .leading
          ).lineLimit(1).minimumScaleFactor(0.7)
          WeatherArtwork(condition: day.condition).frame(width: 42, height: rowHeight - 5)
          Text(unit.formatted(day.high)).foregroundStyle(.white).frame(
            width: compact ? 50 : 58, alignment: .trailing)
          Text(unit.formatted(day.low)).foregroundStyle(
            isDay ? ClassicTheme.lowTemperature : .white.opacity(0.4)
          ).frame(width: compact ? 48 : 56, alignment: .trailing)
        }
        .font(ClassicTheme.font(compact ? 24 : 28))
        .padding(.horizontal, compact ? 14 : 17)
        .frame(height: rowHeight)
        .background(.white.opacity(index.isMultiple(of: 2) ? 0 : 0.025))
        .accessibilityElement(children: .combine)
        if index < 4 { ClassicRule() }
      }
    }
    .accessibilityIdentifier("dailyForecast")
  }

  private var hourlyList: some View {
    ScrollView(showsIndicators: false) {
      VStack(spacing: 0) {
        ForEach(report?.hourly ?? []) { hour in
          HStack {
            Text(
              WeatherDate.string(
                hour.date, format: "h:mm a", timeZone: report?.timeZone ?? city.timeZone
              ).lowercased()
            ).frame(maxWidth: .infinity, alignment: .leading)
            WeatherArtwork(condition: hour.condition, isDay: hour.isDay).frame(
              width: 42, height: 38)
            Text(hour.precipitation > 0 ? "\(hour.precipitation)%" : "").foregroundStyle(
              .white.opacity(0.45)
            ).frame(width: 45)
            Text(unit.formatted(hour.temperature)).font(ClassicTheme.font(26)).frame(
              width: 49, alignment: .trailing)
          }.font(ClassicTheme.font(18)).padding(.horizontal, 14).frame(height: rowHeight + 10)
          ClassicRule()
        }
      }
    }.frame(height: hourlyHeight + rowHeight * 5 + 5).background(.black.opacity(0.12))
  }

  private var unavailable: some View {
    VStack(spacing: 15) {
      if loading {
        ProgressView().tint(.white)
        Text(L10n.text("Updating weather…"))
      } else {
        Image(systemName: "cloud").font(.system(size: 32))
        Text(error ?? L10n.text("Weather isn't available yet.")).multilineTextAlignment(.center)
        Button(L10n.text("Try Again"), action: refresh).buttonStyle(ClassicButtonStyle(blue: true))
      }
    }.font(ClassicTheme.font(17)).padding(24).frame(maxWidth: .infinity)
  }

  private var footer: some View {
    HStack(spacing: 3) {
      Button(action: about) {
        Text("Y!").font(.custom("Georgia-BoldItalic", size: 22)).foregroundStyle(
          .white.opacity(0.55)
        )
        .frame(width: 41, height: 41)
      }.accessibilityLabel(L10n.text("Weather sources and app information"))
      Spacer(minLength: 0)
      Button(action: refresh) {
        HStack(spacing: 4) {
          if loading { ProgressView().scaleEffect(0.6).frame(width: 12) }
          Text(updateText).font(.custom("HelveticaNeue-Bold", size: compact ? 10 : 11)).lineLimit(1)
            .minimumScaleFactor(0.6)
        }.frame(minHeight: 42)
      }
      .accessibilityLabel(
        demo
          ? L10n.text("Demo weather. Open settings to use live weather.")
          : L10n.format("Refresh weather. %@", updateText)
      )
      .accessibilityIdentifier("refreshWeather")
      Spacer(minLength: 0)
      Button(action: info) {
        ZStack {
          Circle().fill(.white.opacity(0.50)).frame(width: 21, height: 21)
          Text("i").font(.custom("Georgia-Bold", size: 18)).foregroundStyle(
            Color(hex: isDay ? 0x435775 : 0x402444)
          ).offset(y: -0.5)
        }.frame(width: 41, height: 41)
      }.accessibilityLabel(L10n.text("Manage cities")).accessibilityIdentifier(
        "manageCities_\(city.id)")
    }.padding(.horizontal, 6).frame(height: 43)
  }

  private var updateText: String {
    if demo { return L10n.text("Demo · iOS 6 Weather") }
    guard let report else { return L10n.text(loading ? "Updating…" : "Tap to update") }
    let timestamp = WeatherDate.string(
      report.updatedAt, format: "M/d/yy  h:mm a", timeZone: report.timeZone)
    return L10n.format(error == nil ? "Updated %@" : "Offline · %@", timestamp)
  }
}
