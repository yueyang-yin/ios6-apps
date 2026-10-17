import SwiftUI

struct StockManagerView: View {
  let store: StocksStore
  let done: () -> Void
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var searching = false
  init(store: StocksStore, startSearching: Bool = false, done: @escaping () -> Void) {
    self.store = store
    self.done = done
    // A one-time seed lets the empty-state action open search directly.
    _searching = State(initialValue: startSearching)
  }
  var body: some View {
    ZStack {
      StockSurface(dark: true).ignoresSafeArea()
      if searching {
        StockSearchView(store: store) { searching = false }
          .transition(reduceMotion ? .opacity : .move(edge: .trailing))
      } else {
        VStack(spacing: 0) {
          StockNavigationBar(
            title: L10n.text("Stocks"), leading: "+", trailing: L10n.text("Done"),
            leadingID: "add-stock", trailingID: "manager-done", onLeading: { searching = true },
            onTrailing: done)
          ScrollView {
            VStack(spacing: 0) {
              ForEach(store.watchlist) { stock in
                managerRow(stock)
                  .draggable(stock.symbol)
                  .dropDestination(for: String.self) { symbols, _ in
                    guard let symbol = symbols.first else { return false }
                    store.move(symbol, before: stock.symbol)
                    return true
                  }
              }
              if store.watchlist.isEmpty {
                Text(L10n.text("Add Stocks Hint")).font(StockTheme.font(17)).multilineTextAlignment(
                  .center
                ).padding(35)
              }
            }
            .padding(.top, 12)
            Text(L10n.text("Reorder Hint")).font(StockTheme.font(12)).foregroundStyle(
              .white.opacity(0.65)
            ).multilineTextAlignment(.center).padding(20)
            HStack(spacing: 0) {
              ForEach(ChangeDisplay.allCases, id: \.rawValue) { display in
                Button {
                  store.changeDisplay = display
                } label: {
                  Text(display.title).font(StockTheme.font(12, bold: true)).lineLimit(2)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(
                      store.changeDisplay == display
                        ? Color.white.opacity(0.25) : .black.opacity(0.3)
                    )
                    .overlay(Rectangle().stroke(.black.opacity(0.6), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(store.changeDisplay == display ? .isSelected : [])
                .accessibilityIdentifier("display-\(display.rawValue)")
              }
            }
            .clipShape(RoundedRectangle(cornerRadius: 7)).padding(.horizontal, 16)
            VStack(spacing: 10) {
              Text(L10n.text("Data Attribution")).font(StockTheme.font(12, bold: true))
              Text(L10n.text("Data Notice")).font(StockTheme.font(12))
              Text(L10n.text("Local Watchlist Notice")).font(StockTheme.font(12))
              Text(L10n.text("Language Notice")).font(StockTheme.font(12))
            }
            .foregroundStyle(.white.opacity(0.65)).multilineTextAlignment(.center).padding(24)
          }
          .accessibilityIdentifier("managed-watchlist")
        }
      }
    }
    .animation(reduceMotion ? nil : .easeInOut(duration: 0.23), value: searching)
    .accessibilityAction(.escape) { if searching { searching = false } else { done() } }
    .onDisappear { Task { await store.refresh() } }
  }
  private func managerRow(_ stock: Stock) -> some View {
    HStack(spacing: 0) {
      Button {
        store.remove(stock.symbol)
      } label: {
        Image(systemName: "minus").font(.system(size: 12, weight: .black))
          .frame(width: 23, height: 23)
          .background(
            Circle().fill(
              LinearGradient(
                colors: [
                  Color(red: 0.96, green: 0.38, blue: 0.38),
                  Color(red: 0.65, green: 0.03, blue: 0.05),
                ], startPoint: .top, endPoint: .bottom))
          )
          .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 1.5))
          .shadow(color: .black, radius: 1, y: 1).frame(width: 49, height: 54)
      }
      .buttonStyle(.plain).accessibilityLabel(L10n.format("Delete %@", stock.displayName()))
      .accessibilityIdentifier("delete-\(stock.symbol)")
      VStack(alignment: .leading, spacing: 2) {
        Text(stock.displaySymbol).font(StockTheme.font(19, bold: true))
        Text(stock.displayName()).font(StockTheme.font(12)).foregroundStyle(.white.opacity(0.7))
          .lineLimit(1)
      }
      Spacer(minLength: 5)
      Image(systemName: "line.3.horizontal").font(.system(size: 22, weight: .bold))
        .foregroundStyle(.white.opacity(0.6)).shadow(color: .black, radius: 0, y: -1)
        .frame(width: 44, height: 54).accessibilityHidden(true)
    }
    .background(
      LinearGradient(
        colors: [Color(white: 0.35), Color(white: 0.21)], startPoint: .top, endPoint: .bottom)
    )
    .overlay(alignment: .top) { Color.white.opacity(0.18).frame(height: 1) }
    .overlay(alignment: .bottom) { Color.black.opacity(0.7).frame(height: 1) }
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("managed-\(stock.symbol)")
    .accessibilityAction(named: L10n.text("Move Up")) { store.move(stock.symbol, offset: -1) }
    .accessibilityAction(named: L10n.text("Move Down")) { store.move(stock.symbol, offset: 1) }
  }
}

private struct StockSearchView: View {
  let store: StocksStore
  let done: () -> Void
  @State private var query = ""
  @State private var results: [Stock] = []
  @State private var loading = false
  @State private var failed = false
  @FocusState private var focused: Bool
  var body: some View {
    VStack(spacing: 0) {
      StockNavigationBar(
        title: L10n.text("Add Stock"), leading: L10n.text("Cancel"), trailing: "",
        leadingID: "search-cancel", trailingID: "search-unused", onLeading: done, onTrailing: {})
      HStack(spacing: 7) {
        Image(systemName: "magnifyingglass").foregroundStyle(.gray)
        TextField(L10n.text("Search Placeholder"), text: $query)
          .font(StockTheme.font(16)).foregroundStyle(.black)
          .autocorrectionDisabled().textInputAutocapitalization(.characters).submitLabel(.search)
          .focused($focused).accessibilityIdentifier("stock-search")
        if !query.isEmpty {
          Button {
            query = ""
          } label: {
            Image(systemName: "xmark.circle.fill").foregroundStyle(.gray).frame(
              width: 44, height: 44)
          }
          .accessibilityLabel(L10n.text("Clear Search"))
        }
      }
      .padding(.horizontal, 10).frame(height: 39)
      .background(
        RoundedRectangle(cornerRadius: 20).fill(.white).shadow(
          color: .black.opacity(0.6), radius: 2, y: 1)
      )
      .padding(10)
      if loading { ProgressView().padding(8).accessibilityLabel(L10n.text("Searching")) }
      ScrollView {
        LazyVStack(spacing: 0) {
          ForEach(results) { stock in
            Button {
              store.add(stock)
              focused = false
              done()
            } label: {
              HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                  Text(stock.symbol).font(StockTheme.font(18, bold: true))
                  Text(stock.displayName()).font(StockTheme.font(14)).foregroundStyle(
                    .white.opacity(0.7))
                }
                Spacer()
                Text(
                  store.watchlist.contains(where: { $0.symbol == stock.symbol })
                    ? L10n.text("Added") : stock.exchange
                )
                .font(StockTheme.font(11)).foregroundStyle(.white.opacity(0.6))
              }
              .padding(14).frame(maxWidth: .infinity, minHeight: 60).contentShape(Rectangle())
              .background(.white.opacity(0.06))
              .overlay(alignment: .bottom) { Color.black.opacity(0.6).frame(height: 1) }
            }
            .buttonStyle(.plain).accessibilityIdentifier("result-\(stock.symbol)")
          }
          if results.isEmpty && !loading {
            Text(
              L10n.text(
                query.isEmpty ? "Search Hint" : failed ? "Search Unavailable" : "No Results")
            )
            .font(StockTheme.font(16)).multilineTextAlignment(.center).foregroundStyle(
              .white.opacity(0.65)
            ).padding(28)
          }
          if failed && !results.isEmpty {
            Text(L10n.text("Local Search Notice")).font(StockTheme.font(12)).foregroundStyle(
              .white.opacity(0.65)
            ).padding(16)
          }
        }
      }
      .scrollDismissesKeyboard(.interactively)
    }
    .background { StockSurface(dark: true).ignoresSafeArea() }
    .task { focused = true }
    .task(id: query) { await search() }
  }
  private func search() async {
    let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
    failed = false
    guard !term.isEmpty else {
      results = []
      loading = false
      return
    }
    results = Stock.localSearch(term)
    loading = true
    do {
      try await Task.sleep(for: .milliseconds(350))
      let remote = try await store.search(term)
      guard !Task.isCancelled else { return }
      var seen = Set<String>()
      results = (results + remote).filter { seen.insert($0.symbol).inserted }
      loading = false
    } catch {
      guard !Task.isCancelled else { return }
      failed = true
      loading = false
    }
  }
}
