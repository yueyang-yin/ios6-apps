import Network
import Observation
import UIKit

struct NearbyPrinter: Identifiable {
  let id: String
  let name: String
  let endpoint: NWEndpoint?
  let resourcePath: String
  let secure: Bool
}

@MainActor
@Observable
final class ClassicPrintModel {
  private(set) var printers: [NearbyPrinter] = []
  private(set) var selectedPrinter: UIPrinter?
  private(set) var selectedName: String?
  private(set) var isConnecting = false
  private(set) var searching = false
  private(set) var discoveryFailed = false
  private(set) var selectionFailed = false
  private(set) var copies = 1
  private(set) var selectedFixture = false
  private(set) var selectionVersion = 0
  @ObservationIgnored private var browsers: [NWBrowser] = []
  @ObservationIgnored private var results: [String: Set<NWBrowser.Result>] = [:]
  @ObservationIgnored private var connection: NWConnection?
  @ObservationIgnored private var session = UUID()
  @ObservationIgnored private var selection = UUID()
  @ObservationIgnored private var searchTimeout: Task<Void, Never>?
  @ObservationIgnored private var selectionTimeout: Task<Void, Never>?

  func changeCopies(by delta: Int) {
    copies = min(max(copies + delta, 1), 99)
  }

  func startDiscovery() {
    stopDiscovery()
    printers = []
    results = [:]
    discoveryFailed = false
    selectionFailed = false
    let arguments = ProcessInfo.processInfo.arguments
    if arguments.contains("--uitesting") {
      if arguments.contains("--print-fixtures") {
        printers = [
          NearbyPrinter(
            id: "office", name: "Office LaserJet", endpoint: nil, resourcePath: "", secure: false),
          NearbyPrinter(
            id: "studio", name: "Studio Printer", endpoint: nil, resourcePath: "", secure: false),
        ]
        return
      }
      if arguments.contains("--print-empty") { return }
    }
    searching = true
    let current = session
    for type in ["_ipp._tcp", "_ipps._tcp"] {
      let browser = NWBrowser(for: .bonjourWithTXTRecord(type: type, domain: nil), using: .tcp)
      browser.browseResultsChangedHandler = { [weak self] found, _ in
        Task { @MainActor in
          guard let self, self.session == current else { return }
          self.results[type] = found
          self.updatePrinters()
        }
      }
      browser.stateUpdateHandler = { [weak self] state in
        Task { @MainActor in
          guard let self, self.session == current else { return }
          switch state {
          case .waiting, .failed:
            self.discoveryFailed = true
            self.searching = false
          default: break
          }
        }
      }
      browsers.append(browser)
      browser.start(queue: .main)
    }
    searchTimeout = Task { [weak self] in
      try? await Task.sleep(for: .seconds(5))
      guard !Task.isCancelled, let self, self.session == current else { return }
      self.searching = false
    }
  }

  func stopDiscovery() {
    session = UUID()
    selection = UUID()
    searchTimeout?.cancel()
    selectionTimeout?.cancel()
    for browser in browsers { browser.cancel() }
    browsers = []
    connection?.cancel()
    connection = nil
    searching = false
    isConnecting = false
  }

  func select(_ nearby: NearbyPrinter) {
    guard !isConnecting else { return }
    selectionFailed = false
    guard let endpoint = nearby.endpoint else {
      let arguments = ProcessInfo.processInfo.arguments
      guard arguments.contains("--uitesting"), arguments.contains("--print-fixtures") else {
        return
      }
      selectedPrinter = UIPrinter(url: URL(string: "ipp://127.0.0.1:9/test")!)
      selectedName = nearby.name
      selectedFixture = true
      selectionVersion += 1
      return
    }
    isConnecting = true
    let current = UUID()
    selection = current
    let resolver = NWConnection(to: endpoint, using: .tcp)
    connection = resolver
    resolver.stateUpdateHandler = { [weak self, weak resolver] state in
      Task { @MainActor in
        guard let self, let resolver, self.selection == current else { return }
        switch state {
        case .ready:
          guard case .hostPort(let host, let port) = resolver.currentPath?.remoteEndpoint,
            let url = Self.printerURL(
              host: host, port: port, path: nearby.resourcePath, secure: nearby.secure)
          else {
            self.failSelection(current)
            return
          }
          resolver.stateUpdateHandler = nil
          resolver.cancel()
          self.connection = nil
          let printer = UIPrinter(url: url)
          let available = await printer.contactPrinter()
          guard self.selection == current else { return }
          if available {
            self.selectionTimeout?.cancel()
            self.selectedPrinter = printer
            self.selectedName = printer.displayName.isEmpty ? nearby.name : printer.displayName
            self.selectedFixture = false
            self.isConnecting = false
            self.selectionVersion += 1
          } else {
            self.failSelection(current)
          }
        case .failed: self.failSelection(current)
        default: break
        }
      }
    }
    resolver.start(queue: .main)
    selectionTimeout = Task { [weak self] in
      try? await Task.sleep(for: .seconds(35))
      guard !Task.isCancelled else { return }
      self?.failSelection(current)
    }
  }

  private func failSelection(_ current: UUID) {
    guard selection == current else { return }
    selection = UUID()
    connection?.cancel()
    connection = nil
    selectionTimeout?.cancel()
    selectionFailed = true
    isConnecting = false
  }

  private func updatePrinters() {
    var found: [String: NearbyPrinter] = [:]
    for result in results.values.flatMap({ $0 }) {
      guard case .service(let name, let type, let domain, _) = result.endpoint else { continue }
      let id = name + "." + domain
      let secure = type.hasPrefix("_ipps")
      if found[id]?.secure == true { continue }
      var resourcePath = "ipp/print"
      if case .bonjour(let record) = result.metadata,
        case .string(let path) = record.getEntry(for: "rp"), !path.isEmpty
      {
        resourcePath = path
      }
      found[id] = NearbyPrinter(
        id: id, name: name, endpoint: result.endpoint, resourcePath: resourcePath, secure: secure)
    }
    printers = found.values.sorted {
      $0.name.localizedStandardCompare($1.name) == .orderedAscending
    }
    if !printers.isEmpty { searching = false }
  }

  static func printerURL(host: NWEndpoint.Host, port: NWEndpoint.Port, path: String, secure: Bool)
    -> URL?
  {
    var components = URLComponents()
    components.scheme = secure ? "ipps" : "ipp"
    let address = host.debugDescription
    components.host =
      address.contains(":") && !address.hasPrefix("[") ? "[" + address + "]" : address
    components.port = Int(port.rawValue)
    components.path = "/" + path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    return components.url
  }
}
