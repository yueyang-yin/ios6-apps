import SwiftUI

struct HistoricalPassHeader: View {
  var pass: PocketPass
  var body: some View {
    HStack(spacing: 0) {
      brand
      Spacer(minLength: 6)
      if let field = pass.header.first {
        VStack(alignment: .trailing, spacing: -1) {
          if !field.label.isEmpty {
            Text(pass.displayLabel(field.label)).font(PassTheme.font(10))
              .foregroundStyle(pass.labelColor.opacity(0.82))
          }
          Text(pass.display(field.value)).font(PassTheme.font(pass.sampleStyle == "spg" ? 23 : 20))
            .lineLimit(1).minimumScaleFactor(0.8)
        }
      }
    }.padding(.horizontal, 13).frame(maxWidth: .infinity, minHeight: 60)
      .foregroundStyle(pass.foreground)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(
        pass.organization
          + (pass.header.first.map {
            ", " + pass.displayLabel($0.label) + " " + pass.display($0.value)
          } ?? "")
      )
      .shadow(
        color: .black.opacity(
          pass.sampleStyle == "sheraton" || pass.sampleStyle == "baseball" ? 0.35 : 0), radius: 0,
        y: -1)
  }

  @ViewBuilder private var brand: some View {
    switch pass.sampleStyle {
    case "fandango":
      HStack(spacing: 3) {
        Text("F").font(.custom("HelveticaNeue-CondensedBlack", size: 32))
          .foregroundStyle(Color(passHex: "F27813")).rotationEffect(.degrees(-8))
          .shadow(color: Color(passHex: "AC3C11"), radius: 0, x: 1, y: 1)
        Text("FANDANGO").font(.custom("HelveticaNeue-CondensedBlack", size: 19))
          .tracking(1.1).foregroundStyle(Color(passHex: "3458A4"))
      }
    case "target":
      HStack(spacing: 8) {
        ZStack {
          Circle().fill(.white)
          Circle().fill(Color(passHex: "E71916")).padding(5)
          Circle().fill(.white).padding(10)
        }.frame(width: 30, height: 30)
        Text("TARGET").font(PassTheme.font(21, bold: true)).tracking(-0.6)
      }
    case "delta":
      VStack(alignment: .leading, spacing: 2) {
        Text("SKY PRIORITY").font(PassTheme.font(7, bold: true)).foregroundStyle(
          Color(passHex: "CF2930"))
        HStack(spacing: 5) {
          DeltaMark().fill(Color(passHex: "BE1933")).frame(width: 23, height: 22)
          Text("DELTA").font(PassTheme.font(20, bold: true)).tracking(2.7)
          Image(systemName: "globe.americas.fill").font(.system(size: 13))
            .foregroundStyle(Color(passHex: "56799A")).padding(.leading, 3)
        }
      }.foregroundStyle(Color(passHex: "12355B"))
    case "baseball":
      HStack(spacing: 14) {
        Text("P").font(.custom("Baskerville-Bold", size: 36)).foregroundStyle(
          Color(passHex: "F4C50F"))
        Text("vs.").font(.custom("Baskerville-Italic", size: 14)).foregroundStyle(
          Color(passHex: "D5BB7D"))
        ZStack {
          Text("N").offset(x: -2)
          Text("Y").offset(x: 3, y: 2)
        }.font(.custom("Baskerville-Bold", size: 30)).foregroundStyle(Color(passHex: "F58025"))
        Image(systemName: "baseball.diamond.bases").font(.system(size: 25))
          .foregroundStyle(Color(passHex: "092D77")).padding(.leading, 16)
      }
    case "w":
      VStack(alignment: .leading, spacing: -5) {
        Text("W").font(.custom("Bodoni 72 Smallcaps", size: 37))
        Text("HOTELS").font(PassTheme.font(6, bold: true)).tracking(2.5).padding(.leading, 2)
      }
    case "spg":
      HStack(alignment: .bottom, spacing: 6) {
        Text("spg").font(.custom("Baskerville", size: 38)).tracking(-2)
        Text("Starwood\nPreferred\nGuest").font(PassTheme.font(7)).lineSpacing(-1).padding(
          .bottom, 6)
      }
    case "sheraton":
      HStack(spacing: 7) {
        ZStack {
          Circle().stroke(.white.opacity(0.85), lineWidth: 1.2)
          Text("S").font(.custom("Baskerville-Bold", size: 22))
          Image(systemName: "laurel.leading").font(.system(size: 28)).offset(x: -11)
          Image(systemName: "laurel.trailing").font(.system(size: 28)).offset(x: 11)
        }.frame(width: 30, height: 30)
        VStack(alignment: .leading, spacing: -1) {
          Text("Sheraton").font(.custom("Baskerville-Bold", size: 21))
          Text("HOTELS & RESORTS").font(PassTheme.font(5, bold: true)).tracking(1.1)
        }
      }
    case "american":
      HStack(spacing: 6) {
        HStack(spacing: -5) {
          Text("A").foregroundStyle(Color(passHex: "BA192F"))
          Text("A").foregroundStyle(Color(passHex: "235A98"))
        }.font(.custom("HelveticaNeue-CondensedBold", size: 27))
        Text("American Airlines").font(PassTheme.font(17, bold: true)).tracking(-0.3)
      }
    case "starbucks":
      HStack(spacing: 8) {
        CoffeeMedallion().frame(width: 31, height: 31)
        Text("Starbucks Card").font(PassTheme.font(18, bold: true)).tracking(-0.5)
      }
    default:
      Text(pass.organization).font(PassTheme.font(17, bold: true))
    }
  }
}

private struct DeltaMark: Shape {
  func path(in rect: CGRect) -> Path {
    Path { path in
      path.move(to: CGPoint(x: rect.midX, y: rect.minY))
      path.addLines([
        CGPoint(x: rect.maxX, y: rect.maxY), CGPoint(x: rect.midX, y: rect.maxY * 0.72),
        CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.midX, y: rect.minY),
      ])
      path.move(to: CGPoint(x: rect.midX, y: rect.height * 0.47))
      path.addLines([
        CGPoint(x: rect.maxX * 0.79, y: rect.maxY * 0.9),
        CGPoint(x: rect.midX, y: rect.maxY * 0.72), CGPoint(x: rect.midX, y: rect.height * 0.47),
      ])
    }
  }
}

private struct CoffeeMedallion: View {
  var body: some View {
    Canvas { context, size in
      let scale = size.width / 32
      context.scaleBy(x: scale, y: scale)
      context.fill(
        Path(ellipseIn: CGRect(x: 0, y: 0, width: 32, height: 32)),
        with: .color(Color(passHex: "00734B")))
      context.stroke(
        Path(ellipseIn: CGRect(x: 1.5, y: 1.5, width: 29, height: 29)), with: .color(.white),
        lineWidth: 0.8)
      var crown = Path()
      crown.move(to: CGPoint(x: 10, y: 10))
      crown.addLines([
        CGPoint(x: 9, y: 4), CGPoint(x: 13, y: 7), CGPoint(x: 16, y: 2),
        CGPoint(x: 19, y: 7), CGPoint(x: 23, y: 4), CGPoint(x: 22, y: 10),
      ])
      crown.closeSubpath()
      context.fill(crown, with: .color(.white))
      context.fill(
        Path(ellipseIn: CGRect(x: 12, y: 10, width: 8, height: 10)), with: .color(.white))
      var hair = Path()
      for side in [-1.0, 1.0] {
        for offset in stride(from: 0.0, through: 6, by: 3) {
          hair.move(to: CGPoint(x: 16 + side * (7 + offset / 2), y: 11))
          hair.addCurve(
            to: CGPoint(x: 16 + side * (5 + offset), y: 28),
            control1: CGPoint(x: 16 + side * (2 + offset), y: 18),
            control2: CGPoint(x: 16 + side * (15 - offset / 2), y: 22))
        }
      }
      context.stroke(hair, with: .color(.white), lineWidth: 1.4)
    }.accessibilityHidden(true)
  }
}

struct HistoricalPassSurface: View {
  var pass: PocketPass
  var body: some View {
    LinearGradient(
      colors: [
        pass.background.mixWithWhite(0.12), pass.background, pass.background.mixWithBlack(0.14),
      ],
      startPoint: .top, endPoint: .bottom
    )
    .overlay {
      if ["fandango", "target", "baseball", "w", "spg", "sheraton"].contains(pass.sampleStyle ?? "")
      {
        Canvas { context, size in
          var facet = Path()
          facet.move(to: CGPoint(x: size.width * 0.18, y: 0))
          facet.addLines([
            CGPoint(x: size.width * 0.54, y: 0),
            CGPoint(x: size.width * 0.67, y: size.height),
            CGPoint(x: size.width * 0.42, y: size.height),
          ])
          facet.closeSubpath()
          context.fill(facet, with: .color(.white.opacity(0.07)))
        }
      }
    }
    .overlay(alignment: .top) { Color.white.opacity(0.4).frame(height: 1) }
    .overlay(alignment: .bottom) { Color.black.opacity(0.2).frame(height: 1) }
    .accessibilityHidden(true)
  }
}
