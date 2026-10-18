import SwiftUI

enum PassTheme {
  static func font(_ size: CGFloat, bold: Bool = false) -> Font {
    .custom(bold ? "HelveticaNeue-Bold" : "HelveticaNeue", size: size, relativeTo: .body)
  }
}

struct PocketBackground: View {
  var subdued = false
  var body: some View {
    GeometryReader { geometry in
      RadialGradient(
        colors: [
          Color(passHex: subdued ? "303334" : "525454"),
          Color(passHex: subdued ? "17191A" : "242627"), .black,
        ],
        center: .init(x: 0.5, y: 0.48), startRadius: 10,
        endRadius: max(geometry.size.width, geometry.size.height) * 0.72
      )
      .overlay {
        Canvas { context, size in
          var horizontal = Path()
          for y in stride(from: 0.0, through: size.height, by: 3) {
            horizontal.move(to: CGPoint(x: 0, y: y))
            horizontal.addLine(to: CGPoint(x: size.width, y: y))
          }
          context.stroke(horizontal, with: .color(.white.opacity(0.018)), lineWidth: 0.5)
          var vertical = Path()
          for x in stride(from: 0.0, through: size.width, by: 3) {
            vertical.move(to: CGPoint(x: x, y: 0))
            vertical.addLine(to: CGPoint(x: x, y: size.height))
          }
          context.stroke(vertical, with: .color(.black.opacity(0.07)), lineWidth: 0.5)
        }
      }
    }.ignoresSafeArea().accessibilityHidden(true).allowsHitTesting(false)
  }
}

struct ClassicButton: ButtonStyle {
  var color: Color = Color(passHex: "4D5358")
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(PassTheme.font(15, bold: true))
      .foregroundStyle(.white)
      .shadow(color: .black.opacity(0.8), radius: 0, y: -1)
      .padding(.horizontal, 13).frame(minHeight: 32)
      .background {
        RoundedRectangle(cornerRadius: 5)
          .fill(
            LinearGradient(
              colors: [color.opacity(0.8), color, color.opacity(0.65)],
              startPoint: .top, endPoint: .bottom)
          )
          .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 5).stroke(.white.opacity(0.2), lineWidth: 1).padding(1)
          }
          .overlay(RoundedRectangle(cornerRadius: 5).stroke(.black.opacity(0.8), lineWidth: 1))
          .shadow(color: .black.opacity(0.4), radius: 1, y: 1)
      }
      .brightness(configuration.isPressed ? -0.18 : 0)
      .frame(minHeight: 44).contentShape(Rectangle())
  }
}

struct PassNavigation: View {
  var title: String
  var leading: String = "Cancel"
  var trailing: String = "Done"
  var onLeading: () -> Void
  var onTrailing: (() -> Void)?
  var trailingEnabled = true
  var body: some View {
    HStack {
      Button(L10n.text(leading), action: onLeading).buttonStyle(ClassicButton())
      Spacer(minLength: 4)
      Text(title).font(PassTheme.font(20, bold: true)).lineLimit(1).minimumScaleFactor(0.75)
        .shadow(color: .black, radius: 0, y: -1)
      Spacer(minLength: 4)
      if let onTrailing {
        Button(L10n.text(trailing), action: onTrailing)
          .buttonStyle(ClassicButton(color: Color(passHex: "3265A5")))
          .disabled(!trailingEnabled).opacity(trailingEnabled ? 1 : 0.45)
      } else {
        Color.clear.frame(width: 62, height: 44).accessibilityHidden(true)
      }
    }.padding(.horizontal, 9).frame(height: 48).foregroundStyle(.white)
      .background {
        LinearGradient(
          colors: [Color(passHex: "5E6162"), Color(passHex: "303335"), Color(passHex: "141617")],
          startPoint: .top, endPoint: .bottom
        )
        .overlay(alignment: .top) { Color.white.opacity(0.16).frame(height: 1) }
        .overlay(alignment: .bottom) { Color.black.frame(height: 1) }
      }
  }
}

struct TicketSilhouette: Shape {
  var kind: PassKind
  func path(in rect: CGRect) -> Path {
    let paper = Path(roundedRect: rect, cornerRadius: 6)
    var cutouts = Path()
    if kind == .eventTicket {
      cutouts.addEllipse(in: CGRect(x: rect.midX - 11, y: rect.minY - 11, width: 22, height: 22))
    }
    if kind == .boardingPass {
      for x in [rect.minX, rect.maxX] {
        cutouts.addEllipse(in: CGRect(x: x - 5, y: rect.minY + 23, width: 10, height: 10))
      }
    }
    if kind == .coupon {
      for x in stride(from: rect.minX + 8, to: rect.maxX, by: 12) {
        cutouts.addEllipse(in: CGRect(x: x - 4, y: rect.minY - 4, width: 8, height: 8))
        cutouts.addEllipse(in: CGRect(x: x - 4, y: rect.maxY - 4, width: 8, height: 8))
      }
    }
    return paper.subtracting(cutouts)
  }
}

struct MiniTicket: View {
  var kind: PassKind
  var body: some View {
    VStack(spacing: 8) {
      Group {
        switch kind {
        case .boardingPass: Image(systemName: "airplane").font(.system(size: 25, weight: .bold))
        case .eventTicket: Text("7:00").font(PassTheme.font(23))
        case .storeCard: Text("$25").font(PassTheme.font(24))
        case .coupon: Text("50%").font(PassTheme.font(24))
        case .generic: Image(systemName: "bed.double.fill").font(.system(size: 24))
        }
      }.shadow(color: .black.opacity(0.4), radius: 0, y: 1)
      BarcodeView(
        barcode: .init(
          message: "DEMO",
          format: kind == .eventTicket || kind == .coupon
            ? "PKBarcodeFormatCode128" : "PKBarcodeFormatQR", alternateText: ""), compact: true
      )
      .frame(width: kind == .eventTicket || kind == .coupon ? 40 : 25, height: 25)
    }.foregroundStyle(kind == .boardingPass ? Color(passHex: "A2812C") : .white)
      .frame(width: 65, height: 85)
      .background {
        LinearGradient(
          colors: [
            Color(passHex: kind.hex).mixWithWhite(0.4), Color(passHex: kind.hex),
            Color(passHex: kind.hex).mixWithBlack(0.2),
          ], startPoint: .top, endPoint: .bottom)
      }
      .overlay(alignment: .top) {
        Ellipse().fill(.white.opacity(0.15)).frame(width: 100, height: 38).offset(y: -17)
      }
      .clipShape(TicketSilhouette(kind: kind))
      .overlay(TicketSilhouette(kind: kind).stroke(.white.opacity(0.22), lineWidth: 1))
      .compositingGroup()
      .clipShape(TicketSilhouette(kind: kind))
      .shadow(color: .black.opacity(0.8), radius: 2, y: 2)
      .accessibilityHidden(true)
  }
}

extension Color {
  func mixWithWhite(_ opacity: Double) -> Color { mix(with: .white, amount: opacity) }
  func mixWithBlack(_ opacity: Double) -> Color { mix(with: .black, amount: opacity) }
  private func mix(with other: UIColor, amount: Double) -> Color {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    other.getRed(&r, green: &g, blue: &b, alpha: &a)
    return Color(
      red: red * (1 - amount) + r * amount,
      green: green * (1 - amount) + g * amount, blue: blue * (1 - amount) + b * amount)
  }
}

struct BarcodeView: View {
  var barcode: PassBarcode
  var compact = false
  @State private var bitmap: UIImage?
  var body: some View {
    VStack(spacing: compact ? 0 : 5) {
      if let bitmap {
        Image(uiImage: bitmap).interpolation(.none).resizable().scaledToFit()
      } else {
        Text(L10n.text("Barcode unavailable")).font(PassTheme.font(12)).foregroundStyle(.black)
      }
      if !compact, !barcode.alternateText.isEmpty {
        Text(barcode.alternateText).font(PassTheme.font(10)).foregroundStyle(.black).lineLimit(2)
      }
    }.padding(compact ? 2 : 10).background(.white)
      .task(id: barcode) { bitmap = BarcodeRenderer.image(barcode) }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(L10n.text("Pass barcode"))
      .accessibilityValue(barcode.alternateText)
  }
}
