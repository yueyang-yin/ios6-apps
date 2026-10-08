import SwiftUI

enum ClassicTheme {
  static func font(_ size: CGFloat, bold: Bool = false) -> Font {
    .custom(bold ? "HelveticaNeue-Bold" : "HelveticaNeue-Light", size: size)
  }

  static func blue(_ isDay: Bool) -> [Color] {
    isDay
      ? [Color(hex: 0x263750), Color(hex: 0x4f6c93)] : [Color(hex: 0x100e17), Color(hex: 0x4e3054)]
  }

  static let lowTemperature = Color(hex: 0x8eb8ee)
}

extension Color {
  init(hex: UInt32) {
    self.init(
      .sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255,
      blue: Double(hex & 255) / 255, opacity: 1)
  }
}

struct ClassicButtonStyle: ButtonStyle {
  var blue = false

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.custom("HelveticaNeue-Bold", size: 16))
      .foregroundStyle(.white)
      .padding(.horizontal, 13)
      .frame(minWidth: 42, minHeight: 34)
      .background {
        RoundedRectangle(cornerRadius: 6)
          .fill(
            LinearGradient(
              colors: blue
                ? [Color(hex: 0x8fb9ff), Color(hex: 0x367bed), Color(hex: 0x1452c7)]
                : [Color(hex: 0x6d6e74), Color(hex: 0x292a30), Color(hex: 0x111116)],
              startPoint: .top, endPoint: .bottom)
          )
          .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.3), lineWidth: 1)
          }
          .overlay { RoundedRectangle(cornerRadius: 6).stroke(.black.opacity(0.7), lineWidth: 1) }
          .shadow(color: .black.opacity(0.6), radius: 1, y: 1)
      }
      .brightness(configuration.isPressed ? -0.15 : 0)
      .shadow(color: .black.opacity(0.5), radius: 0, y: -1)
  }
}

struct ClassicNavigationBar<Leading: View, Trailing: View>: View {
  var title: String
  @ViewBuilder var leading: () -> Leading
  @ViewBuilder var trailing: () -> Trailing

  var body: some View {
    ZStack {
      LinearGradient(
        stops: [
          .init(color: Color(hex: 0x727378), location: 0),
          .init(color: Color(hex: 0x34353a), location: 0.49),
          .init(color: Color(hex: 0x17181d), location: 0.5),
          .init(color: Color(hex: 0x24252b), location: 1),
        ], startPoint: .top, endPoint: .bottom)
      Text(title).font(ClassicTheme.font(24, bold: true)).shadow(color: .black, radius: 1, y: -1)
      HStack {
        leading()
        Spacer()
        trailing()
      }.padding(.horizontal, 10)
    }
    .frame(height: 50)
    .overlay(alignment: .top) { Color.white.opacity(0.25).frame(height: 1) }
    .overlay(alignment: .bottom) { Color.black.frame(height: 1) }
  }
}

struct LinenBackground: View {
  var body: some View {
    Color(hex: 0x27282d).overlay {
      Canvas { context, size in
        for y in stride(from: 0.0, through: size.height, by: 3) {
          var line = Path()
          line.move(to: CGPoint(x: 0, y: y))
          line.addLine(to: CGPoint(x: size.width, y: y))
          context.stroke(
            line, with: .color(.white.opacity(Int(y) % 9 == 0 ? 0.07 : 0.025)), lineWidth: 0.5)
        }
        for x in stride(from: 0.0, through: size.width, by: 3) {
          var line = Path()
          line.move(to: CGPoint(x: x, y: 0))
          line.addLine(to: CGPoint(x: x, y: size.height))
          context.stroke(
            line, with: .color(.black.opacity(Int(x) % 9 == 0 ? 0.35 : 0.14)), lineWidth: 1)
        }
      }
    }.ignoresSafeArea()
  }
}

struct ClassicRule: View {
  var body: some View {
    VStack(spacing: 0) {
      Color.black.opacity(0.30).frame(height: 0.5)
      Color.white.opacity(0.20).frame(height: 0.5)
    }
  }
}
