import SwiftUI

struct StocksRootView: View {
  @Bindable var store: StocksStore
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.scenePhase) private var scenePhase
  @ScaledMetric(relativeTo: .body) private var rowHeight = 49.0
  @ScaledMetric(relativeTo: .caption2) private var footerHeight = 48.0
  @State private var managing = false
  @State private var page = 1
  @State private var openSearch = false

  var body: some View {
    ZStack {
      StockSurface().ignoresSafeArea()
      GeometryReader { proxy in
        if managing {
          StockManagerView(store: store, startSearching: openSearch) { managing = false }
            .transition(.opacity)
        } else if proxy.size.width > proxy.size.height {
          landscape
        } else {
          portrait(size: proxy.size)
        }
      }
    }
    .font(StockTheme.font(16))
    .foregroundStyle(.white)
    .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: managing)
    .task(id: scenePhase) {
      guard scenePhase == .active else { return }
      await store.refresh()
      guard !store.demo else { return }
      while !Task.isCancelled {
        do { try await Task.sleep(for: .seconds(60)) } catch { return }
        await store.refresh()
        await store.loadChart(force: true)
      }
    }
    .task(id: store.chartKey) { await store.loadChart() }
    .task(id: "\(store.selectedSymbol):\(page)") { if page == 2 { await store.loadNews() } }

  }
  private func portrait(size: CGSize) -> some View {
    let rows = max(1, min(7, store.watchlist.count))
    let maximumHeight = size.height * 0.50
    let compactHeight = max(44, min(rowHeight, maximumHeight / Double(rows)))
    let effectiveRowHeight = rowHeight <= 50 ? compactHeight : rowHeight
    let visibleRows = rowHeight <= 50 ? rows : max(1, min(rows, Int(maximumHeight / rowHeight)))
    return VStack(spacing: 0) {
      watchlist(rowHeight: effectiveRowHeight)
        .frame(
          height: store.watchlist.isEmpty
            ? min(250, size.height * 0.43)
            : Double(visibleRows) * effectiveRowHeight)
      VStack(spacing: 0) {
        TabView(selection: $page) {
          StockSummaryView(store: store).tag(0)
          chartPanel.tag(1)
          StockNewsView(store: store).tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .clipped()
        footer
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(StockTheme.blue, ignoresSafeAreaEdges: [])
      .overlay(alignment: .top) { Color.white.opacity(0.4).frame(height: 1) }
    }
  }
  private func watchlist(rowHeight: Double) -> some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        if store.watchlist.isEmpty {
          VStack(spacing: 12) {
            Text(L10n.text("No Stocks")).font(StockTheme.font(22, bold: true))
            Button(L10n.text("Add Stock")) {
              openSearch = true
              managing = true
            }.buttonStyle(GlossyButtonStyle(blue: true))
              .accessibilityIdentifier("empty-add")
          }.frame(maxWidth: .infinity).padding(.vertical, 40)
        }
        ForEach(Array(store.watchlist.enumerated()), id: \.element.id) { position, stock in
          StockRow(
            stock: stock, quote: store.quotes[stock.symbol],
            selected: store.selectedSymbol == stock.symbol,
            alternate: position.isMultiple(of: 2) == false,
            display: store.changeDisplay,
            height: rowHeight, failed: store.quoteFailures.contains(stock.symbol),
            select: { store.selectedSymbol = stock.symbol }, cycle: store.cycleDisplay)
        }
      }
    }
    .scrollIndicators(.hidden)
    .refreshable {
      await store.refresh()
      await store.loadChart(force: true)
    }
    .accessibilityIdentifier("watchlist")
  }
  private var chartPanel: some View {
    VStack(spacing: 0) {
      ranges
      if let chart = store.selectedChart, !chart.points.isEmpty {
        StockChartView(chart: chart, range: store.range)
      } else {
        StockEmptyPanel(
          title: L10n.text(
            store.selectedStock == nil
              ? "Select a Stock" : store.loadingChart ? "Loading Chart" : "No Chart Data"),
          retry: store.selectedStock == nil ? nil : { Task { await store.loadChart(force: true) } })
      }
      if store.chartFailures.contains(store.chartKey) {
        Button(L10n.text("Chart Unavailable")) { Task { await store.loadChart(force: true) } }
          .font(StockTheme.font(11)).frame(minHeight: 28).accessibilityIdentifier("chart-retry")
      }
    }
  }
  private var ranges: some View {
    HStack(spacing: 0) {
      ForEach(ChartRange.allCases) { range in
        Button {
          store.range = range
        } label: {
          Text(range.title).font(StockTheme.font(13, bold: true)).minimumScaleFactor(0.8)
            .foregroundStyle(store.range == range ? StockTheme.ink : .white)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background {
              if store.range == range {
                Capsule().fill(.white).shadow(color: .black.opacity(0.6), radius: 1, y: 1)
              }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.format("Show %@ Chart", range.title))
        .accessibilityAddTraits(store.range == range ? .isSelected : [])
        .accessibilityIdentifier("range-\(range.rawValue)")
      }
    }
    .background(
      LinearGradient(
        colors: [Color(red: 0.34, green: 0.43, blue: 0.57), StockTheme.blue], startPoint: .top,
        endPoint: .bottom))
  }
  private var footer: some View {
    HStack(alignment: .center, spacing: 0) {
      Link(destination: financeURL) {
        Text("Y!").font(.custom("Georgia-BoldItalic", size: 20)).shadow(
          color: .black, radius: 0, y: 1
        )
        .frame(width: 48, height: 48).contentShape(Rectangle())
      }
      .accessibilityLabel(L10n.text("Open Yahoo Finance"))
      ZStack(alignment: .top) {
        HStack(spacing: 0) {
          ForEach(0..<3) { number in
            Button {
              withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { page = number }
            } label: {
              Circle().fill(number == page ? .white : Color.white.opacity(0.33))
                .frame(width: 5, height: 5)
                .padding(.bottom, 6)
                .frame(width: 44, height: footerHeight, alignment: .bottom)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.text(number == 0 ? "Summary" : number == 1 ? "Chart" : "News"))
            .accessibilityValue(number == page ? footerStatus : "")
            .accessibilityAddTraits(number == page ? .isSelected : [])
            .accessibilityIdentifier("page-\(number)")
            .accessibilityAction(named: L10n.text("Refresh Quotes"), refreshQuotes)
            .contentShape(.interaction, Rectangle())
            .contextMenu {
              Button(L10n.text("Refresh Quotes"), action: refreshQuotes)
                .accessibilityIdentifier("refresh-quotes")
            }
          }
        }
        .frame(maxWidth: .infinity)
        VStack(spacing: 1) {
          Text(footerStatus)
          if let quote = store.selectedQuote {
            Text(StockFormat.date(quote.timestamp, time: true))
          }
        }
        .font(StockTheme.font(10)).lineLimit(1).minimumScaleFactor(0.7)
        .padding(.horizontal, 4).padding(.top, 3)
        .allowsHitTesting(false)
      }
      .frame(maxWidth: .infinity)
      Button {
        openSearch = false
        managing = true
      } label: {
        Image(systemName: "info.circle.fill").font(.system(size: 18)).frame(width: 48, height: 48)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain).accessibilityLabel(L10n.text("Manage Stocks")).accessibilityIdentifier(
        "manage-stocks")
    }
    .frame(height: footerHeight)
    .background {
      LinearGradient(
        colors: [
          Color(red: 0.20, green: 0.30, blue: 0.44), Color(red: 0.07, green: 0.17, blue: 0.33),
        ], startPoint: .top, endPoint: .bottom
      )
      .ignoresSafeArea(.container, edges: .bottom)
    }
    .overlay(alignment: .top) { Color.white.opacity(0.3).frame(height: 0.5) }
  }
  private var footerStatus: String {
    L10n.text(
      store.demo
        ? "Demo Data"
        : store.refreshing
          ? "Updating"
          : store.quoteFailures.isEmpty ? "Quotes May Be Delayed" : "Cached or Unavailable")
  }
  private func refreshQuotes() {
    Task {
      await store.refresh()
      await store.loadChart(force: true)
    }
  }
  private var financeURL: URL {
    var components = URLComponents(string: "https://finance.yahoo.com")!
    components.path = store.selectedSymbol.isEmpty ? "/" : "/quote/\(store.selectedSymbol)/"
    return components.url!
  }
  private var landscape: some View {
    VStack(spacing: 0) {
      HStack {
        Text(store.selectedStock?.displaySymbol ?? L10n.text("Stocks")).font(
          StockTheme.font(16, bold: true))
        if let quote = store.selectedQuote {
          Text(StockFormat.number(quote.price)).font(StockTheme.font(16, bold: true))
          Text(quote.changeText(.percent)).font(StockTheme.font(14)).foregroundStyle(
            (quote.change ?? 0) >= 0
              ? Color(red: 0.66, green: 0.91, blue: 0.41) : Color(red: 1, green: 0.59, blue: 0.56))
        }
        Spacer()
        Text(L10n.text(store.demo ? "Demo Data" : "Quotes May Be Delayed")).font(
          StockTheme.font(10))
        Button {
          openSearch = false
          managing = true
        } label: {
          Image(systemName: "info.circle.fill").frame(width: 44, height: 44)
        }
        .accessibilityLabel(L10n.text("Manage Stocks")).accessibilityIdentifier("manage-stocks")
      }
      .padding(.horizontal, 12).frame(height: 40)
      .background(
        LinearGradient(
          colors: [Color(red: 0.34, green: 0.43, blue: 0.57), StockTheme.blue], startPoint: .top,
          endPoint: .bottom))
      ranges
      if let chart = store.selectedChart {
        StockChartView(chart: chart, range: store.range, expanded: true)
      } else {
        StockEmptyPanel(
          title: L10n.text("No Chart Data"), retry: { Task { await store.loadChart(force: true) } })
      }
    }
  }
}

private struct StockRow: View {
  let stock: Stock
  let quote: StockQuote?
  let selected: Bool
  let alternate: Bool
  let display: ChangeDisplay
  let height: Double
  let failed: Bool
  let select: () -> Void
  let cycle: () -> Void
  var body: some View {
    HStack(spacing: 0) {
      Button(action: select) {
        HStack(spacing: 8) {
          Text(stock.displaySymbol).font(StockTheme.font(21, bold: true)).lineLimit(1)
            .minimumScaleFactor(0.65)
          Spacer(minLength: 4)
          Text(StockFormat.number(quote?.price)).font(StockTheme.font(20, bold: true)).lineLimit(1)
            .minimumScaleFactor(0.6)
        }
        .shadow(color: .black.opacity(0.55), radius: 0, y: 1)
        .padding(.leading, 9).padding(.trailing, 7)
        .frame(maxWidth: .infinity, minHeight: height).contentShape(Rectangle())
      }
      .accessibilityLabel("\(stock.displayName()), \(StockFormat.number(quote?.price))")
      .accessibilityAddTraits(selected ? .isSelected : [])
      .accessibilityIdentifier("stock-\(stock.symbol)")
      Button(action: cycle) {
        Text(quote?.changeText(display) ?? "—").font(StockTheme.font(17, bold: true))
          .lineLimit(1).minimumScaleFactor(0.65)
          .shadow(color: .black.opacity(0.6), radius: 0, y: 1)
          .frame(width: 88, height: 32)
          .background {
            let positive = (quote?.change ?? 0) >= 0
            RoundedRectangle(cornerRadius: 5).fill(
              LinearGradient(
                colors: quote == nil
                  ? [Color(white: 0.45), Color(white: 0.25)]
                  : positive
                    ? [
                      Color(red: 0.53, green: 0.74, blue: 0.28),
                      Color(red: 0.24, green: 0.47, blue: 0.06),
                    ]
                    : [
                      Color(red: 0.88, green: 0.27, blue: 0.28),
                      Color(red: 0.61, green: 0.07, blue: 0.09),
                    ], startPoint: .top, endPoint: .bottom)
            )
            .overlay(alignment: .top) {
              RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.20)).frame(height: 15)
                .padding(1)
            }
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(.black.opacity(0.6), lineWidth: 1))
            .shadow(color: .white.opacity(0.3), radius: 0, y: 1)
          }
          .frame(width: 96, height: height).contentShape(Rectangle())
      }
      .accessibilityLabel(
        L10n.format(
          "%@, %@", display.title,
          quote?.changeText(display) ?? L10n.text(failed ? "Unavailable" : "Loading"))
      )
      .accessibilityHint(L10n.text("Change Display Hint"))
      .accessibilityIdentifier("change-\(stock.symbol)")
    }
    .buttonStyle(.plain)
    .background {
      if selected {
        LinearGradient(
          stops: [
            .init(color: Color(red: 0.25, green: 0.37, blue: 0.56), location: 0),
            .init(color: Color(red: 0.12, green: 0.25, blue: 0.44), location: 0.49),
            .init(color: Color(red: 0.035, green: 0.14, blue: 0.31), location: 0.51),
            .init(color: Color(red: 0.04, green: 0.17, blue: 0.36), location: 1),
          ], startPoint: .top, endPoint: .bottom)
      } else {
        (alternate ? StockTheme.quoteRowSlate : StockTheme.quoteRowBlue)
          .overlay {
            LinearGradient(
              colors: [.white.opacity(0.035), .black.opacity(0.025)],
              startPoint: .top, endPoint: .bottom)
          }
      }
    }
    .overlay(alignment: .top) { Color.white.opacity(0.40).frame(height: 0.5) }
    .overlay(alignment: .bottom) { Color.black.opacity(0.28).frame(height: 0.5) }
  }
}

struct StockEmptyPanel: View {
  let title: String
  var retry: (() -> Void)?
  var body: some View {
    VStack(spacing: 15) {
      Text(title).font(StockTheme.font(17, bold: true)).multilineTextAlignment(.center)
      if let retry {
        Button(L10n.text("Retry"), action: retry).buttonStyle(GlossyButtonStyle(blue: true))
      }
    }
    .padding(20).frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
