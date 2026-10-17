import SwiftUI
import UIKit

struct ChartSelection: Equatable {
  var first: Double
  var second: Double?
  init(first: Double, second: Double? = nil) {
    self.first = second.map { min(first, $0) } ?? first
    self.second = second.map { max(first, $0) }
  }
}

struct StockChartView: View {
  let chart: StockChart
  let range: ChartRange
  var expanded = false
  @State private var selection: ChartSelection?

  private var points: [PricePoint] { chart.points }
  private func index(_ fraction: Double) -> Int {
    min(
      max(0, Int((fraction * Double(max(0, points.count - 1))).rounded())), max(0, points.count - 1)
    )
  }
  private var selectionText: String {
    guard let selection, !points.isEmpty else { return "" }
    let first = points[index(selection.first)]
    if let end = selection.second {
      let second = points[index(end)]
      let delta = second.close - first.close
      let percent = first.close == 0 ? 0 : delta / first.close * 100
      return "\(StockFormat.signed(delta)) (\(StockFormat.signed(percent))%)"
    }
    return
      "\(StockFormat.date(first.date, time: range == .day || range == .week))   \(StockFormat.number(first.close))"
  }
  var body: some View {
    GeometryReader { proxy in
      let plot = CGRect(
        x: 10, y: 26, width: max(1, proxy.size.width - 58), height: max(1, proxy.size.height - 51))
      ZStack(alignment: .top) {
        Canvas { context, size in
          draw(context: &context, size: size, plot: plot)
        }
        .accessibilityHidden(true)
        Text(selectionText.isEmpty ? " " : selectionText)
          .font(StockTheme.font(expanded ? 13 : 11, bold: true))
          .lineLimit(1).minimumScaleFactor(0.65)
          .foregroundStyle(
            selection?.second == nil ? .white : Color(red: 1, green: 0.87, blue: 0.26)
          )
          .padding(.horizontal, 5).padding(.top, 3)
          .accessibilityHidden(true)
        ChartTouchSurface { first, second in
          selection = ChartSelection(first: first, second: second)
        }
        .frame(width: plot.width, height: plot.height)
        .position(x: plot.midX, y: plot.midY)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.format("Chart for %@", chart.quote.symbol))
        .accessibilityValue(
          selectionText.isEmpty ? StockFormat.number(points.last?.close) : selectionText
        )
        .accessibilityHint(L10n.text("Chart Hint"))
        .accessibilityAdjustableAction { direction in
          let old = selection?.first ?? 0
          selection = ChartSelection(
            first: min(1, max(0, old + (direction == .increment ? 0.05 : -0.05))))
        }
        .accessibilityIdentifier(expanded ? "expanded-chart" : "stock-chart")
      }
      .background(
        LinearGradient(
          colors: [
            Color(red: 0.23, green: 0.32, blue: 0.48), Color(red: 0.05, green: 0.14, blue: 0.30),
          ], startPoint: .top, endPoint: .bottom))
    }
    .onChange(of: chart) { selection = nil }
    .onChange(of: range) { selection = nil }
  }

  private func draw(context: inout GraphicsContext, size: CGSize, plot: CGRect) {
    guard let minPrice = points.map(\.close).min(), let maxPrice = points.map(\.close).max(),
      !points.isEmpty
    else { return }
    let padding = max((maxPrice - minPrice) * 0.09, maxPrice * 0.001)
    let low = minPrice - padding
    let high = maxPrice + padding
    let span = max(0.001, high - low)
    let coordinates: [CGPoint] = points.enumerated().map { offset, point in
      CGPoint(
        x: plot.minX + CGFloat(offset) / CGFloat(max(1, points.count - 1)) * plot.width,
        y: plot.maxY - CGFloat((point.close - low) / span) * plot.height)
    }
    for step in 0...4 {
      let fraction = CGFloat(step) / 4
      let y = plot.minY + fraction * plot.height
      var line = Path()
      line.move(to: CGPoint(x: plot.minX, y: y))
      line.addLine(to: CGPoint(x: plot.maxX, y: y))
      context.stroke(line, with: .color(.white.opacity(0.24)), lineWidth: 0.5)
      let label = StockFormat.number(high - Double(fraction) * span, digits: high > 100 ? 0 : 2)
      context.draw(
        Text(label).font(StockTheme.font(expanded ? 12 : 10)).foregroundColor(.white),
        at: CGPoint(x: plot.maxX + 5, y: y), anchor: .leading)
    }
    for step in 0...6 {
      let x = plot.minX + CGFloat(step) / 6 * plot.width
      var line = Path()
      line.move(to: CGPoint(x: x, y: plot.minY))
      line.addLine(to: CGPoint(x: x, y: plot.maxY))
      context.stroke(line, with: .color(.white.opacity(0.26)), lineWidth: 0.5)
      if step < 6 {
        let point = points[
          min(points.count - 1, Int((Double(step) + 0.5) / 6 * Double(points.count - 1)))]
        let label: String
        if range == .day {
          label = point.date.formatted(.dateTime.hour().minute().locale(AppLanguage.current.locale))
        } else if range == .week || range == .month {
          label = point.date.formatted(
            .dateTime.month(.defaultDigits).day().locale(AppLanguage.current.locale))
        } else {
          label = point.date.formatted(
            .dateTime.month(.abbreviated).locale(AppLanguage.current.locale))
        }
        context.draw(
          Text(label).font(StockTheme.font(expanded ? 12 : 10)).foregroundColor(.white),
          at: CGPoint(x: plot.minX + (CGFloat(step) + 0.5) / 6 * plot.width, y: plot.maxY + 13))
      }
    }
    var line = Path()
    for (offset, point) in coordinates.enumerated() {
      if offset == 0 { line.move(to: point) } else { line.addLine(to: point) }
    }
    var area = line
    area.addLine(to: CGPoint(x: plot.maxX, y: plot.maxY))
    area.addLine(to: CGPoint(x: plot.minX, y: plot.maxY))
    area.closeSubpath()
    context.fill(
      area,
      with: .linearGradient(
        Gradient(colors: [.white.opacity(0.10), .white.opacity(0.015)]),
        startPoint: CGPoint(x: 0, y: plot.minY), endPoint: CGPoint(x: 0, y: plot.maxY)))
    let maxVolume = max(1, points.map(\.volume).max() ?? 1)
    for (offset, point) in points.enumerated() {
      let height = CGFloat(point.volume / maxVolume) * plot.height * 0.19
      let rect = CGRect(
        x: coordinates[offset].x, y: plot.maxY - height,
        width: max(0.5, plot.width / CGFloat(points.count) * 0.45), height: height)
      context.fill(Path(rect), with: .color(.white.opacity(0.66)))
    }
    context.stroke(line, with: .color(.black.opacity(0.65)), lineWidth: 2.7)
    context.stroke(line, with: .color(.white), lineWidth: expanded ? 1.5 : 1.2)
    if let selection {
      let firstIndex = index(selection.first)
      let secondIndex = selection.second.map(index)
      if let secondIndex {
        let start = min(firstIndex, secondIndex)
        let end = max(firstIndex, secondIndex)
        var highlighted = Path()
        for offset in start...end {
          if offset == start {
            highlighted.move(to: coordinates[offset])
          } else {
            highlighted.addLine(to: coordinates[offset])
          }
        }
        context.stroke(highlighted, with: .color(.yellow), lineWidth: 2)
      }
      for offset in [firstIndex, secondIndex].compactMap({ $0 }) {
        let point = coordinates[offset]
        var cursor = Path()
        cursor.move(to: CGPoint(x: point.x, y: plot.minY))
        cursor.addLine(to: CGPoint(x: point.x, y: plot.maxY))
        context.stroke(cursor, with: .color(.yellow.opacity(0.85)), lineWidth: 1)
        context.fill(
          Path(ellipseIn: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6)),
          with: .color(.white))
      }
    }
  }
}

// UIKit supplies two independent touch positions, which SwiftUI's DragGesture does not expose.
private struct ChartTouchSurface: UIViewRepresentable {
  let onSelection: (Double, Double?) -> Void
  func makeCoordinator() -> Coordinator { Coordinator(onSelection: onSelection) }
  func makeUIView(context: Context) -> UIView {
    let view = UIView()
    view.isMultipleTouchEnabled = true
    let hold = UILongPressGestureRecognizer(
      target: context.coordinator, action: #selector(Coordinator.hold(_:)))
    hold.minimumPressDuration = 0.15
    hold.delegate = context.coordinator
    view.addGestureRecognizer(hold)
    let compare = UILongPressGestureRecognizer(
      target: context.coordinator, action: #selector(Coordinator.compare(_:)))
    compare.minimumPressDuration = 0
    compare.numberOfTouchesRequired = 2
    compare.delegate = context.coordinator
    view.addGestureRecognizer(compare)
    return view
  }
  func updateUIView(_ uiView: UIView, context: Context) {
    context.coordinator.onSelection = onSelection
  }
  final class Coordinator: NSObject, UIGestureRecognizerDelegate {
    var onSelection: (Double, Double?) -> Void
    init(onSelection: @escaping (Double, Double?) -> Void) { self.onSelection = onSelection }
    private func fraction(_ x: CGFloat, in view: UIView) -> Double {
      min(1, max(0, Double(x / max(1, view.bounds.width))))
    }
    @objc func hold(_ gesture: UILongPressGestureRecognizer) {
      guard let view = gesture.view, gesture.numberOfTouches == 1,
        gesture.state == .began || gesture.state == .changed
      else {
        return
      }
      onSelection(fraction(gesture.location(in: view).x, in: view), nil)
    }
    func gestureRecognizer(
      _ gestureRecognizer: UIGestureRecognizer,
      shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
      gestureRecognizer.view === otherGestureRecognizer.view
    }
    @objc func compare(_ gesture: UILongPressGestureRecognizer) {
      guard let view = gesture.view, gesture.numberOfTouches >= 2 else { return }
      onSelection(
        fraction(gesture.location(ofTouch: 0, in: view).x, in: view),
        fraction(gesture.location(ofTouch: 1, in: view).x, in: view))
    }
  }
}
