import SwiftUI

struct WeatherArtwork: View {
  var condition: WeatherCondition
  var isDay = true

  var body: some View {
    Canvas { context, size in
      let stageScale = min(size.width, size.height) / 160
      let anchor = bodyAnchor
      context.translateBy(
        x: size.width / 2, y: (size.height - 160 * stageScale) / 2 + 66 * stageScale)
      context.scaleBy(x: stageScale * bodyScale, y: stageScale * bodyScale)
      context.translateBy(x: -anchor.x, y: -anchor.y)
      switch condition {
      case .clear:
        if isDay {
          drawSun(in: context, center: CGPoint(x: 80, y: 63), radius: 32)
        } else {
          drawMoon(in: context, center: CGPoint(x: 80, y: 63), radius: 34)
        }
      case .partlyCloudy:
        if isDay {
          drawSun(in: context, center: CGPoint(x: 63, y: 47), radius: 29)
        } else {
          drawMoon(in: context, center: CGPoint(x: 63, y: 47), radius: 30)
        }
        drawCloud(in: context, center: CGPoint(x: 89, y: 74), scale: 0.8, storm: false)
      case .cloudy, .fog:
        drawCloud(in: context, center: CGPoint(x: 67, y: 53), scale: 0.7, storm: true)
        drawCloud(in: context, center: CGPoint(x: 88, y: 72), scale: 0.9, storm: false)
        if condition == .fog {
          for y in [92.0, 101, 110] {
            context.fill(
              Path(roundedRect: CGRect(x: 38, y: y, width: 85, height: 4), cornerRadius: 2),
              with: .color(.white.opacity(0.6)))
          }
        }
      case .rain, .snow, .thunderstorm:
        drawCloud(in: context, center: CGPoint(x: 79, y: 52), scale: 0.88, storm: true)
        if condition == .thunderstorm {
          var glowing = context
          glowing.addFilter(.shadow(color: .yellow.opacity(0.7), radius: 3))
          glowing.fill(
            Self.lightningPath,
            with: .linearGradient(
              Gradient(colors: [.white, .yellow, Color(hex: 0xff9600)]),
              startPoint: CGPoint(x: 75, y: 80), endPoint: CGPoint(x: 82, y: 120)))
        } else {
          for index in 0..<7 {
            let x = 43.0 + Double(index) * 12
            let y = 81.0 + Double(index % 3) * 7
            if condition == .snow {
              var flake = Path()
              for angle in stride(from: 0.0, to: Double.pi, by: Double.pi / 3) {
                flake.move(to: CGPoint(x: x - cos(angle) * 4, y: y - sin(angle) * 4))
                flake.addLine(to: CGPoint(x: x + cos(angle) * 4, y: y + sin(angle) * 4))
              }
              context.stroke(flake, with: .color(.white), lineWidth: 1.5)
            } else {
              var drop = Path()
              drop.move(to: CGPoint(x: x + 3, y: y))
              drop.addQuadCurve(to: CGPoint(x: x, y: y + 19), control: CGPoint(x: x - 8, y: y + 20))
              drop.addQuadCurve(to: CGPoint(x: x + 3, y: y), control: CGPoint(x: x + 7, y: y + 16))
              context.fill(
                drop,
                with: .linearGradient(
                  Gradient(colors: [.white.opacity(0), Color(hex: 0xaee1ff), .white]),
                  startPoint: CGPoint(x: x, y: y), endPoint: CGPoint(x: x, y: y + 20)))
            }
          }
        }
      }
    }
    .aspectRatio(160.0 / 130.0, contentMode: .fit)
    .clipped()
    .accessibilityLabel(condition == .clear && !isDay ? "Clear night" : condition.description)
  }

  static var lightningPath: Path {
    Path { path in
      // addLines starts a new subpath at its first point, so include the upper tip.
      path.addLines([
        CGPoint(x: 88, y: 73), CGPoint(x: 65, y: 101), CGPoint(x: 79, y: 98),
        CGPoint(x: 69, y: 123), CGPoint(x: 100, y: 88), CGPoint(x: 83, y: 92),
      ])
      path.closeSubpath()
    }
  }

  private var bodyScale: CGFloat {
    // Match the visible sun, moon, and cloud mass; decorations do not change their size.
    switch condition {
    case .clear: isDay ? 1.33 : 1.25
    case .partlyCloudy: isDay ? 1 : 0.98
    case .cloudy, .fog: 0.95
    case .rain, .snow, .thunderstorm: 1.07
    }
  }

  private var bodyAnchor: CGPoint {
    // Align the main silhouettes, leaving a shared lower area for precipitation.
    switch condition {
    case .clear: CGPoint(x: 80, y: 63)
    case .partlyCloudy: CGPoint(x: 84.5, y: 61)
    case .cloudy, .fog: CGPoint(x: 83.5, y: 63)
    case .rain, .snow, .thunderstorm: CGPoint(x: 79.5, y: 47.5)
    }
  }

  private func drawSun(in context: GraphicsContext, center: CGPoint, radius: CGFloat) {
    var glow = context
    glow.addFilter(.blur(radius: 4))
    glow.fill(
      Path(
        ellipseIn: CGRect(
          x: center.x - radius * 1.42, y: center.y - radius * 1.42, width: radius * 2.84,
          height: radius * 2.84)),
      with: .radialGradient(
        Gradient(colors: [
          Color(hex: 0xffd900).opacity(0.75), Color(hex: 0xffa500).opacity(0.20), .clear,
        ]), center: center, startRadius: radius * 0.5, endRadius: radius * 1.42))
    for index in 0..<56 {
      let angle = Double(index) * .pi * 2 / 56
      let outer = radius * (index.isMultiple(of: 3) ? 1.45 : 1.26)
      let spread = 0.018
      var ray = Path()
      ray.move(
        to: CGPoint(
          x: center.x + cos(angle - spread) * radius * 0.8,
          y: center.y + sin(angle - spread) * radius * 0.8))
      ray.addLine(to: CGPoint(x: center.x + cos(angle) * outer, y: center.y + sin(angle) * outer))
      ray.addLine(
        to: CGPoint(
          x: center.x + cos(angle + spread) * radius * 0.8,
          y: center.y + sin(angle + spread) * radius * 0.8))
      ray.closeSubpath()
      var rays = context
      rays.addFilter(.blur(radius: 0.7))
      rays.fill(
        ray,
        with: .radialGradient(
          Gradient(colors: [
            Color(hex: 0xfff359).opacity(0.8), Color(hex: 0xffad00).opacity(0.5), .clear,
          ]), center: center, startRadius: radius, endRadius: outer))
    }
    let disc = Path(
      ellipseIn: CGRect(
        x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    context.fill(
      disc,
      with: .linearGradient(
        Gradient(stops: [
          .init(color: Color(hex: 0xfffae1), location: 0),
          .init(color: Color(hex: 0xffb838), location: 0.25),
          .init(color: Color(hex: 0xffd831), location: 0.65),
          .init(color: Color(hex: 0xffff00), location: 1),
        ]), startPoint: CGPoint(x: center.x, y: center.y - radius),
        endPoint: CGPoint(x: center.x, y: center.y + radius)))
    context.stroke(disc, with: .color(Color(hex: 0xfff6ad).opacity(0.9)), lineWidth: 1)
    var haze = context
    haze.addFilter(.blur(radius: 2))
    haze.clip(to: disc)
    for index in 0..<12 {
      let y = center.y - radius * 0.4 + Double(index) * 3
      haze.fill(
        Path(
          ellipseIn: CGRect(
            x: center.x - radius + Double(index % 3) * 9, y: y, width: radius * 1.5, height: 6)),
        with: .color(.white.opacity(index % 3 == 0 ? 0.25 : 0.10)))
    }
  }

  private func drawMoon(in context: GraphicsContext, center: CGPoint, radius: CGFloat) {
    let disc = Path(
      ellipseIn: CGRect(
        x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    var moon = context
    moon.addFilter(.shadow(color: .white.opacity(0.16), radius: 9))
    moon.fill(
      disc,
      with: .radialGradient(
        Gradient(colors: [.white, Color(hex: 0xc9c9c9), Color(hex: 0x747b89)]),
        center: CGPoint(x: center.x - 13, y: center.y - 14), startRadius: 1, endRadius: radius * 1.8
      ))
    moon.clip(to: disc)
    for index in 0..<48 {
      let angle = Double(index) * 2.39996
      let distance = sqrt(Double(index) / 48) * radius * 0.95
      let diameter = Double(index % 5 + 2) * 2.3
      let rect = CGRect(
        x: center.x + cos(angle) * distance - diameter / 2,
        y: center.y + sin(angle) * distance - diameter / 2, width: diameter, height: diameter)
      moon.fill(
        Path(ellipseIn: rect),
        with: .color(Color(hex: 0x505761).opacity(0.13 + Double(index % 3) * 0.05)))
      moon.stroke(
        Path(ellipseIn: rect.insetBy(dx: 0.4, dy: 0.4)), with: .color(.white.opacity(0.12)),
        lineWidth: 0.8)
    }
  }

  private func drawCloud(in context: GraphicsContext, center: CGPoint, scale: CGFloat, storm: Bool)
  {
    var cloud = context
    cloud.addFilter(.shadow(color: .black.opacity(0.35), radius: 4, y: 5))
    let circles: [(CGFloat, CGFloat, CGFloat)] = [
      (-38, 3, 19), (-20, -10, 25), (4, -17, 30), (30, -2, 22), (42, 8, 16), (-4, 10, 27),
    ]
    var silhouette = Path()
    for (x, y, r) in circles {
      silhouette.addEllipse(
        in: CGRect(
          x: center.x + (x - r) * scale, y: center.y + (y - r) * scale, width: r * 2 * scale,
          height: r * 2 * scale))
    }
    cloud.fill(
      silhouette,
      with: .linearGradient(
        Gradient(
          colors: storm
            ? [Color(hex: 0xe8edf3), Color(hex: 0x9aa7b7), Color(hex: 0x5e6e83)]
            : [.white, Color(hex: 0xf0f2f6), Color(hex: 0xaab8c8)]),
        startPoint: CGPoint(x: center.x, y: center.y - 43 * scale),
        endPoint: CGPoint(x: center.x, y: center.y + 33 * scale)))
    var highlights = context
    highlights.clip(to: silhouette)
    highlights.addFilter(.blur(radius: 5 * scale))
    for (x, y, r) in circles {
      highlights.fill(
        Path(
          ellipseIn: CGRect(
            x: center.x + (x - r * 0.65) * scale, y: center.y + (y - r * 0.85) * scale,
            width: r * 1.3 * scale, height: r * scale)),
        with: .color(.white.opacity(storm ? 0.20 : 0.45)))
    }
  }
}

#Preview("Weather artwork") {
  VStack {
    ForEach(WeatherCondition.allCases, id: \.self) { condition in
      WeatherArtwork(condition: condition).frame(width: 100, height: 75)
    }
  }.frame(maxWidth: .infinity).background(.black)
}
