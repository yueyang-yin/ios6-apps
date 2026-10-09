import QuartzCore
import SwiftUI
import UIKit

struct PaperFramePreference: PreferenceKey {
  static let defaultValue: [String: CGRect] = [:]
  static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
    value.merge(nextValue(), uniquingKeysWith: { _, newest in newest })
  }
}

struct PaperTrashRequest: Identifiable {
  let id = UUID()
  let noteID: UUID
  let page: CGRect
  let target: CGPoint
}

// A continuous mesh preserves the note's actual ink while its surface folds in three dimensions.
struct PaperTrashMesh {
  struct Vertex {
    let point: CGPoint
    let depth: CGFloat
  }

  let page: CGRect
  let target: CGPoint

  func vertex(u: CGFloat, v: CGFloat, progress: Double) -> Vertex {
    let p = CGFloat(min(max(progress, 0), 1))
    let fold = smooth((p - 0.02) / 0.57)
    let flight = smooth((p - 0.43) / 0.49)
    let vanish = 1 - smooth((p - 0.83) / 0.15)
    let radius: CGFloat = min(28, page.width * 0.075)
    let longitude = u * .pi * 2 + 0.35
    let latitude = v * .pi
    let ripple = 1 + 0.17 * sin(u * 43 + v * 31) + 0.09 * cos(v * 57 - u * 19)
    let ballX = sin(latitude) * sin(longitude) * radius * ripple
    let ballY = -cos(latitude) * radius * ripple
    let ballZ = sin(latitude) * cos(longitude) * radius * ripple
    var x = (u - 0.5) * page.width * (1 - fold) + ballX * fold
    var y = (v - 0.5) * page.height * (1 - fold) + ballY * fold
    let z = ballZ * fold + sin(u * 38 + v * 29) * radius * 0.35 * sin(fold * .pi)
    let angle = fold * 0.12 + flight * 2.3
    let rotatedX = x * cos(angle) - y * sin(angle)
    y = x * sin(angle) + y * cos(angle)
    x = rotatedX
    let perspective = 1 / (1 - z / 700)
    let center = center(progress: progress)
    return Vertex(
      point: CGPoint(
        x: center.x + x * perspective * vanish, y: center.y + y * perspective * vanish),
      depth: z * vanish)
  }

  func center(progress: Double) -> CGPoint {
    let travel = smooth((CGFloat(progress) - 0.43) / 0.49)
    return CGPoint(
      x: page.midX + (target.x - page.midX) * travel + sin(travel * .pi) * page.width * 0.12,
      y: page.midY + (target.y - page.midY) * travel - sin(travel * .pi) * 26)
  }

  private func smooth(_ value: CGFloat) -> CGFloat {
    let t = min(max(value, 0), 1)
    return t * t * (3 - 2 * t)
  }
}

struct PaperTrashAnimation: UIViewRepresentable {
  let request: PaperTrashRequest
  let previewProgress: Double?
  let captured: () -> Void
  let completion: () -> Void

  func makeUIView(context: Context) -> CrumpledPaperView {
    let view = CrumpledPaperView(
      request: request, previewProgress: previewProgress, captured: captured, completion: completion
    )
    return view
  }

  func updateUIView(_ view: CrumpledPaperView, context: Context) {}

  static func dismantleUIView(_ view: CrumpledPaperView, coordinator: ()) {
    view.stop()
  }
}

final class CrumpledPaperView: UIView {
  private struct Facet {
    let layer: CALayer
    let shade: CALayer
    let local: [CGPoint]
    let uv: [CGPoint]
  }

  private let request: PaperTrashRequest
  private let previewProgress: Double?
  private let captured: () -> Void
  private let completion: () -> Void
  private var facets: [Facet] = []
  private var displayLink: CADisplayLink?
  private var startTime: CFTimeInterval = 0
  private var started = false
  private var completed = false
  private let shadow = CAShapeLayer()
  private let duration: CFTimeInterval = 1.15

  init(
    request: PaperTrashRequest, previewProgress: Double?, captured: @escaping () -> Void,
    completion: @escaping () -> Void
  ) {
    self.request = request
    self.previewProgress = previewProgress
    self.captured = captured
    self.completion = completion
    super.init(frame: .zero)
    backgroundColor = .clear
    isOpaque = false
    isAccessibilityElement = true
    accessibilityLabel = L10n.text("Deleting Note")
    accessibilityIdentifier = "paper-trash-animation"
    shadow.fillColor = UIColor.black.withAlphaComponent(0.15).cgColor
    shadow.shadowColor = UIColor.black.cgColor
    shadow.shadowRadius = 9
    shadow.shadowOpacity = 0.2
    layer.addSublayer(shadow)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    guard window != nil, !started else { return }
    started = true
    // Wait for the confirmation panel to leave the hierarchy before capturing the page.
    DispatchQueue.main.async { [weak self] in self?.begin() }
  }

  private func begin() {
    guard let window, bounds.width > 0, bounds.height > 0 else {
      finish()
      return
    }
    let source = convert(request.page, to: window)
    let format = UIGraphicsImageRendererFormat()
    format.scale = window.screen.scale
    format.opaque = true
    let image = UIGraphicsImageRenderer(size: source.size, format: format).image { context in
      context.cgContext.translateBy(x: -source.minX, y: -source.minY)
      if !window.drawHierarchy(in: window.bounds, afterScreenUpdates: true) {
        window.layer.render(in: context.cgContext)
      }
    }
    guard let texture = image.cgImage else {
      finish()
      return
    }
    buildFacets(texture: texture)
    render(progress: previewProgress ?? 0)
    captured()
    if previewProgress != nil { return }
    startTime = CACurrentMediaTime()
    let target = PaperDisplayLinkTarget(owner: self)
    let link = CADisplayLink(target: target, selector: #selector(PaperDisplayLinkTarget.tick(_:)))
    link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
    link.add(to: .main, forMode: .common)
    displayLink = link
  }

  private func buildFacets(texture: CGImage) {
    let columns = 10
    let rows = 14
    let width = request.page.width / CGFloat(columns)
    let height = request.page.height / CGFloat(rows)
    for row in 0..<rows {
      for column in 0..<columns {
        let corners = [
          CGPoint(x: 0, y: 0), CGPoint(x: width, y: 0),
          CGPoint(x: width, y: height), CGPoint(x: 0, y: height),
        ]
        for indices in [[0, 1, 3], [1, 2, 3]] {
          let local = indices.map { corners[$0] }
          let uv = local.map {
            CGPoint(
              x: (CGFloat(column) + $0.x / width) / CGFloat(columns),
              y: (CGFloat(row) + $0.y / height) / CGFloat(rows))
          }
          let tile = CALayer()
          tile.anchorPoint = .zero
          tile.bounds = CGRect(x: 0, y: 0, width: width, height: height)
          tile.contents = texture
          tile.contentsGravity = .resize
          tile.contentsRect = CGRect(
            x: CGFloat(column) / CGFloat(columns), y: CGFloat(row) / CGFloat(rows),
            width: 1 / CGFloat(columns), height: 1 / CGFloat(rows))
          let path = CGMutablePath()
          path.addLines(between: local)
          path.closeSubpath()
          let mask = CAShapeLayer()
          mask.frame = tile.bounds
          mask.path = path
          mask.fillColor = UIColor.white.cgColor
          tile.mask = mask
          let shade = CALayer()
          shade.frame = tile.bounds
          shade.backgroundColor = UIColor.black.cgColor
          shade.opacity = 0
          tile.addSublayer(shade)
          layer.addSublayer(tile)
          facets.append(Facet(layer: tile, shade: shade, local: local, uv: uv))
        }
      }
    }
  }

  fileprivate func tick(_ link: CADisplayLink) {
    let progress = min((link.timestamp - startTime) / duration, 1)
    render(progress: progress)
    if progress >= 1 { finish() }
  }

  private func render(progress: Double) {
    let mesh = PaperTrashMesh(page: request.page, target: request.target)
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    for facet in facets {
      let vertices = facet.uv.map { mesh.vertex(u: $0.x, v: $0.y, progress: progress) }
      let transform = affine(from: facet.local, to: vertices.map(\.point))
      facet.layer.setAffineTransform(transform)
      facet.layer.zPosition = vertices.map(\.depth).reduce(0, +) / 3
      let a = vertices[0]
      let b = vertices[1]
      let c = vertices[2]
      let dx1 = b.point.x - a.point.x
      let dy1 = b.point.y - a.point.y
      let dz1 = b.depth - a.depth
      let dx2 = c.point.x - a.point.x
      let dy2 = c.point.y - a.point.y
      let dz2 = c.depth - a.depth
      let nx = dy1 * dz2 - dz1 * dy2
      let ny = dz1 * dx2 - dx1 * dz2
      let nz = dx1 * dy2 - dy1 * dx2
      let length = max(sqrt(nx * nx + ny * ny + nz * nz), 0.001)
      let light = abs((-nx * 0.35 - ny * 0.45 + nz) / (length * 1.15))
      let crease = CGFloat(min(max(progress / 0.45, 0), 1))
      facet.shade.opacity = Float((1 - min(light, 1)) * 0.48 * crease)
    }
    let center = mesh.center(progress: progress)
    let shadowSize = CGFloat(18 + 34 * (1 - min(progress / 0.6, 1)))
    shadow.path = CGPath(
      ellipseIn: CGRect(
        x: center.x - shadowSize, y: center.y + 24, width: shadowSize * 2, height: 12),
      transform: nil)
    shadow.opacity = Float(min(progress * 3, 1) * max(1 - progress, 0))
    CATransaction.commit()
  }

  private func affine(from source: [CGPoint], to destination: [CGPoint]) -> CGAffineTransform {
    let s1 = CGPoint(x: source[1].x - source[0].x, y: source[1].y - source[0].y)
    let s2 = CGPoint(x: source[2].x - source[0].x, y: source[2].y - source[0].y)
    let d1 = CGPoint(x: destination[1].x - destination[0].x, y: destination[1].y - destination[0].y)
    let d2 = CGPoint(x: destination[2].x - destination[0].x, y: destination[2].y - destination[0].y)
    let determinant = s1.x * s2.y - s2.x * s1.y
    let a = (d1.x * s2.y - d2.x * s1.y) / determinant
    let b = (d1.y * s2.y - d2.y * s1.y) / determinant
    let c = (d2.x * s1.x - d1.x * s2.x) / determinant
    let d = (d2.y * s1.x - d1.y * s2.x) / determinant
    return CGAffineTransform(
      a: a, b: b, c: c, d: d,
      tx: destination[0].x - a * source[0].x - c * source[0].y,
      ty: destination[0].y - b * source[0].x - d * source[0].y)
  }

  func stop() {
    displayLink?.invalidate()
    displayLink = nil
    facets.removeAll()
    for sublayer in layer.sublayers ?? [] { sublayer.removeFromSuperlayer() }
  }

  private func finish() {
    guard !completed else { return }
    completed = true
    stop()
    completion()
  }
}

private final class PaperDisplayLinkTarget: NSObject {
  weak var owner: CrumpledPaperView?
  init(owner: CrumpledPaperView) { self.owner = owner }
  @objc func tick(_ link: CADisplayLink) { owner?.tick(link) }
}
