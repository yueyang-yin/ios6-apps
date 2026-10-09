import SwiftUI
import UIKit

enum ClassicTheme {
  static let paper = Color(red: 1, green: 0.98, blue: 0.73)
  static let ink = Color(red: 0.24, green: 0.15, blue: 0.09)
  static let rule = Color(red: 0.67, green: 0.66, blue: 0.43)
  static let leather = Color(red: 0.35, green: 0.21, blue: 0.14)

  static func noteUIFont(_ font: NoteFont, size: CGFloat = 20) -> UIFont {
    UIFontMetrics(forTextStyle: .body).scaledFont(
      for: UIFont(name: font.postScriptName, size: size) ?? .systemFont(ofSize: size))
  }
}

struct PaperBackground: View {
  var ruled = false
  var rowHeight: CGFloat = 28
  var margin = false
  var ruleOffset: CGFloat = 0

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [ClassicTheme.paper, Color(red: 1, green: 0.98, blue: 0.76)],
        startPoint: .topLeading, endPoint: .bottomTrailing)
      Canvas { context, size in
        // Deterministic flecks keep the paper texture stable during editing.
        for index in 0..<1800 {
          let x = CGFloat((index * 73 + 19) % 997) / 997 * size.width
          let y = CGFloat((index * 131 + 31) % 991) / 991 * size.height
          context.fill(
            Path(CGRect(x: x, y: y, width: 0.7, height: 0.5)),
            with: .color(.brown.opacity(index.isMultiple(of: 3) ? 0.055 : 0.028)))
        }
        if ruled {
          var lines = Path()
          for y in stride(from: rowHeight + ruleOffset - 0.5, through: size.height, by: rowHeight) {
            lines.move(to: CGPoint(x: 0, y: y))
            lines.addLine(to: CGPoint(x: size.width, y: y))
          }
          context.stroke(lines, with: .color(ClassicTheme.rule.opacity(0.52)), lineWidth: 0.5)
        }
        if margin {
          var lines = Path()
          for x in [CGFloat(23), CGFloat(26)] {
            lines.move(to: CGPoint(x: x, y: 0))
            lines.addLine(to: CGPoint(x: x, y: size.height))
          }
          context.stroke(lines, with: .color(.brown.opacity(0.2)), lineWidth: 0.5)
        }
      }
    }
    .accessibilityHidden(true)
  }
}

struct LeatherBackground: View {
  var body: some View {
    ZStack {
      LinearGradient(
        stops: [
          .init(color: Color(red: 0.59, green: 0.43, blue: 0.33), location: 0),
          .init(color: Color(red: 0.42, green: 0.28, blue: 0.20), location: 0.48),
          .init(color: Color(red: 0.31, green: 0.19, blue: 0.12), location: 1),
        ], startPoint: .top, endPoint: .bottom)
      Canvas { context, size in
        for index in 0..<2200 {
          let x = CGFloat((index * 67 + 11) % 991) / 991 * size.width
          let y = CGFloat((index * 97 + 7) % 997) / 997 * size.height
          let rect = CGRect(x: x, y: y, width: 1.1, height: 0.8)
          context.fill(
            Path(ellipseIn: rect),
            with: .color(.black.opacity(index.isMultiple(of: 2) ? 0.10 : 0.05)))
          context.fill(
            Path(ellipseIn: rect.offsetBy(dx: 0, dy: 0.6)), with: .color(.white.opacity(0.06)))
        }
      }
      VStack {
        Color.white.opacity(0.22).frame(height: 0.5)
        Spacer()
        Color.black.opacity(0.55).frame(height: 1)
      }
    }
    .accessibilityHidden(true)
  }
}

struct ClassicButtonShape: Shape {
  var back = false
  func path(in rect: CGRect) -> Path {
    if !back { return Path(roundedRect: rect, cornerRadius: 5) }
    var path = Path()
    path.move(to: CGPoint(x: 0, y: rect.midY))
    path.addLine(to: CGPoint(x: 10, y: 2))
    path.addQuadCurve(to: CGPoint(x: 14, y: 0), control: CGPoint(x: 11, y: 0))
    path.addLine(to: CGPoint(x: rect.maxX - 4, y: 0))
    path.addQuadCurve(to: CGPoint(x: rect.maxX, y: 4), control: CGPoint(x: rect.maxX, y: 0))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 4))
    path.addQuadCurve(
      to: CGPoint(x: rect.maxX - 4, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
    path.addLine(to: CGPoint(x: 14, y: rect.maxY))
    path.addQuadCurve(to: CGPoint(x: 10, y: rect.maxY - 2), control: CGPoint(x: 11, y: rect.maxY))
    path.closeSubpath()
    return path
  }
}

struct LeatherButtonStyle: ButtonStyle {
  var back = false
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.custom("HelveticaNeue-Bold", size: 13))
      .foregroundStyle(.white)
      .shadow(color: .black.opacity(0.8), radius: 0.5, y: -1)
      .padding(.leading, back ? 15 : 10)
      .padding(.trailing, 10)
      .frame(minWidth: 30, minHeight: 29)
      .background {
        ClassicButtonShape(back: back)
          .fill(
            LinearGradient(
              colors: [Color(red: 0.55, green: 0.39, blue: 0.29), ClassicTheme.leather],
              startPoint: .top, endPoint: .bottom)
          )
          .overlay {
            ClassicButtonShape(back: back).strokeBorderless()
          }
          .shadow(color: .white.opacity(0.18), radius: 0, y: 1)
      }
      .brightness(configuration.isPressed ? -0.15 : 0)
      .frame(minHeight: 44)
      .contentShape(Rectangle())
  }
}

extension ClassicButtonShape {
  func strokeBorderless() -> some View {
    stroke(Color.black.opacity(0.5), lineWidth: 1)
      .overlay(stroke(Color.white.opacity(0.10), lineWidth: 0.4).padding(1))
  }
}

struct ClassicNavigationBar<Leading: View, Trailing: View>: View {
  let title: String
  @ViewBuilder var leading: Leading
  @ViewBuilder var trailing: Trailing

  var body: some View {
    ZStack {
      LeatherBackground()
      Text(title)
        .font(.custom("HelveticaNeue-Bold", size: 20))
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.75), radius: 0.5, y: -1)
        .lineLimit(1)
        .truncationMode(.tail)
        .padding(.horizontal, 105)
      HStack {
        leading
        Spacer(minLength: 8)
        trailing
      }
      .padding(.horizontal, 7)
    }
    .frame(height: 44)
    .shadow(color: .black.opacity(0.3), radius: 2, y: 2)
    .zIndex(1)
  }
}

struct TornPaperEdge: View {
  var body: some View {
    Canvas { context, size in
      var edge = Path()
      edge.move(to: .zero)
      edge.addLine(to: CGPoint(x: size.width, y: 0))
      for x in stride(from: size.width, through: 0, by: -3) {
        let y: CGFloat = Int(x).isMultiple(of: 2) ? 4 : 6
        edge.addLine(to: CGPoint(x: x, y: y))
      }
      edge.closeSubpath()
      context.fill(edge, with: .color(Color(red: 0.89, green: 0.83, blue: 0.57)))
      context.stroke(edge, with: .color(.brown.opacity(0.25)), lineWidth: 0.5)
    }
    .frame(height: 7)
    .accessibilityHidden(true)
  }
}

struct ClassicToolbarButton: View {
  let symbol: String
  let label: String
  let identifier: String
  var enabled = true
  let action: () -> Void
  var trashOpen = false

  var body: some View {
    Button(action: action) {
      Group {
        if symbol == "trash" {
          ClassicTrashIcon(open: trashOpen)
        } else {
          Image(systemName: symbol)
        }
      }
      .font(.system(size: 23, weight: .regular))
      .foregroundStyle(ClassicTheme.ink.opacity(enabled ? 0.85 : 0.25))
      .shadow(color: .white.opacity(0.75), radius: 0, y: 1)
      .frame(maxWidth: .infinity, minHeight: 44)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(!enabled)
    .accessibilityLabel(L10n.text(label))
    .accessibilityIdentifier(identifier)
  }
}

private struct ClassicTrashIcon: View {
  let open: Bool

  var body: some View {
    ZStack {
      Path { path in
        path.move(to: CGPoint(x: 5, y: 9))
        path.addLine(to: CGPoint(x: 6.5, y: 24))
        path.addQuadCurve(to: CGPoint(x: 9, y: 26), control: CGPoint(x: 7, y: 26))
        path.addLine(to: CGPoint(x: 19, y: 26))
        path.addQuadCurve(to: CGPoint(x: 21.5, y: 24), control: CGPoint(x: 21, y: 26))
        path.addLine(to: CGPoint(x: 23, y: 9))
        for x in [CGFloat(10), 14, 18] {
          path.move(to: CGPoint(x: x, y: 12))
          path.addLine(to: CGPoint(x: x, y: 23))
        }
      }
      .stroke(lineWidth: 1.5)
      Path { path in
        path.move(to: CGPoint(x: 3, y: 7))
        path.addLine(to: CGPoint(x: 25, y: 7))
        path.move(to: CGPoint(x: 10, y: 6))
        path.addLine(to: CGPoint(x: 10, y: 3))
        path.addLine(to: CGPoint(x: 18, y: 3))
        path.addLine(to: CGPoint(x: 18, y: 6))
      }
      .stroke(lineWidth: 1.5)
      .rotationEffect(.degrees(open ? -32 : 0), anchor: .init(x: 0.12, y: 0.25))
      .offset(x: open ? -4 : 0, y: open ? -5 : 0)
      .animation(.easeInOut(duration: 0.18), value: open)
    }
    .frame(width: 28, height: 28)
  }
}
