import SwiftUI

enum StockTheme {
  static let ink = Color(red: 0.08, green: 0.16, blue: 0.31)
  static let blue = Color(red: 0.13, green: 0.23, blue: 0.40)
  static let quoteRowBlue = Color(red: 0.535, green: 0.625, blue: 0.755)
  static let quoteRowSlate = Color(red: 0.667, green: 0.698, blue: 0.773)
  static func font(_ size: CGFloat, bold: Bool = false) -> Font {
    .custom(bold ? "HelveticaNeue-Bold" : "HelveticaNeue", size: size)
  }
}

struct StockSurface: View {
  var dark = false
  var body: some View {
    GeometryReader { proxy in
      Canvas { context, size in
        context.fill(
          Path(CGRect(origin: .zero, size: size)),
          with: .linearGradient(
            Gradient(
              colors: dark
                ? [Color(white: 0.20), Color(white: 0.11)]
                : [
                  Color(red: 0.60, green: 0.68, blue: 0.78),
                  Color(red: 0.43, green: 0.52, blue: 0.64),
                ]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
        for x in stride(from: 0.0, through: size.width, by: dark ? 3.0 : 5.0) {
          let path = Path(CGRect(x: x, y: 0, width: 1, height: size.height))
          context.fill(path, with: .color(.white.opacity(dark ? 0.025 : 0.06)))
        }
        if dark {
          for y in stride(from: 0.0, through: size.height, by: 3.0) {
            context.fill(
              Path(CGRect(x: 0, y: y, width: proxy.size.width, height: 1)),
              with: .color(.black.opacity(0.12)))
          }
        }
      }
    }
    .accessibilityHidden(true)
    .allowsHitTesting(false)
  }
}

struct GlossyButtonStyle: ButtonStyle {
  var blue = false
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(StockTheme.font(14, bold: true))
      .foregroundStyle(.white)
      .shadow(color: .black.opacity(0.8), radius: 0, y: -1)
      .padding(.horizontal, 12)
      .frame(minHeight: 31)
      .background {
        RoundedRectangle(cornerRadius: 5)
          .fill(
            LinearGradient(
              colors: blue
                ? [
                  Color(red: 0.40, green: 0.58, blue: 0.81),
                  Color(red: 0.13, green: 0.30, blue: 0.56),
                ] : [Color(white: 0.48), Color(white: 0.18)], startPoint: .top, endPoint: .bottom)
          )
          .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.14)).frame(height: 14).padding(
              1)
          }
          .overlay(RoundedRectangle(cornerRadius: 5).stroke(.black.opacity(0.7), lineWidth: 1))
          .shadow(color: .white.opacity(0.22), radius: 0, y: 1)
      }
      .brightness(configuration.isPressed ? -0.12 : 0)
      .frame(minWidth: 44, minHeight: 44)
      .contentShape(Rectangle())
  }
}

struct StockNavigationBar: View {
  let title: String
  let leading: String
  let trailing: String
  let leadingID: String
  let trailingID: String
  let onLeading: () -> Void
  let onTrailing: () -> Void
  var body: some View {
    ZStack {
      LinearGradient(
        stops: [
          .init(color: Color(white: 0.40), location: 0),
          .init(color: Color(white: 0.23), location: 0.49),
          .init(color: Color(white: 0.12), location: 0.51),
          .init(color: Color(white: 0.19), location: 1),
        ], startPoint: .top, endPoint: .bottom)
      Text(title).font(StockTheme.font(21, bold: true)).shadow(color: .black, radius: 0, y: -1)
        .accessibilityIdentifier("panel-title")
      HStack {
        Button(leading, action: onLeading).accessibilityLabel(
          leading == "+" ? L10n.text("Add Stock") : leading
        ).accessibilityIdentifier(leadingID)
        Spacer(minLength: 120)
        if !trailing.isEmpty {
          Button(trailing, action: onTrailing).accessibilityIdentifier(trailingID)
        }
      }
      .buttonStyle(GlossyButtonStyle())
      .padding(.horizontal, 9)
    }
    .frame(height: 48)
    .overlay(alignment: .bottom) { Color.black.opacity(0.8).frame(height: 1) }
  }
}
