import SwiftUI

struct PassHeader: View {
  var pass: PocketPass
  var body: some View {
    if pass.sampleStyle != nil {
      HistoricalPassHeader(pass: pass)
    } else {
      HStack(spacing: 10) {
        if let data = pass.logoData, let image = UIImage(data: data) {
          Image(uiImage: image).resizable().scaledToFit().frame(maxWidth: 140, maxHeight: 32)
            .accessibilityHidden(true)
        } else {
          Image(systemName: pass.kind.symbol).font(.system(size: 22, weight: .bold))
            .accessibilityHidden(true)
          Text(pass.organization).font(PassTheme.font(16, bold: true)).lineLimit(1)
            .minimumScaleFactor(0.65)
        }
        Spacer(minLength: 4)
        if let field = pass.header.first {
          VStack(alignment: .trailing, spacing: 0) {
            Text(pass.displayLabel(field.label)).font(PassTheme.font(9)).foregroundStyle(
              pass.labelColor)
            Text(pass.display(field.value)).font(PassTheme.font(17)).lineLimit(1)
              .minimumScaleFactor(
                0.7)
          }
        }
      }.foregroundStyle(pass.foreground).padding(.horizontal, 14).frame(minHeight: 56)
        .shadow(color: .black.opacity(pass.kind == .boardingPass ? 0 : 0.3), radius: 0, y: -1)
    }
  }
}

struct PassCard: View {
  var pass: PocketPass
  var compact = false
  var minimumHeight: CGFloat = 0
  var onInfo: (() -> Void)?
  var body: some View {
    VStack(spacing: 0) {
      PassHeader(pass: pass)
      if !compact {
        if let data = pass.stripData, let image = UIImage(data: data) {
          Image(uiImage: image).resizable().scaledToFill().frame(height: 112).clipped()
            .accessibilityHidden(true)
        } else if pass.isDemo,
          ["starbucks", "fandango", "w", "sheraton"].contains(pass.sampleStyle ?? "")
        {
          Image(
            pass.kind == .storeCard
              ? "CoffeeStrip" : pass.kind == .eventTicket ? "CinemaStrip" : "HotelStrip"
          )
          .resizable().scaledToFill().frame(height: 112).clipped().accessibilityHidden(true)
        }
        VStack(spacing: 22) {
          if !pass.primary.isEmpty { primaryFields }
          if !pass.secondary.isEmpty { fields(pass.secondary) }
          if !pass.auxiliary.isEmpty { fields(pass.auxiliary) }
        }.padding(.horizontal, 18).padding(.vertical, 22)
        if minimumHeight > 0 { Spacer(minLength: 0) }
        if let date = pass.relevantDate {
          Text(
            date.formatted(
              .dateTime.month().day().hour().minute().locale(AppLanguage.current.locale))
          )
          .font(PassTheme.font(13)).padding(.bottom, 16)
        }
        if let barcode = pass.barcode {
          BarcodeView(barcode: barcode)
            .frame(
              maxWidth: barcode.format == "PKBarcodeFormatQR"
                || barcode.format == "PKBarcodeFormatAztec" ? 140 : 290
            )
            .frame(
              height: barcode.format == "PKBarcodeFormatQR"
                || barcode.format == "PKBarcodeFormatAztec" ? 140 : 85
            )
            .padding(.horizontal, 24).padding(.bottom, 14)
        }
        HStack {
          if pass.isDemo {
            Text(L10n.text("DEMO PASS")).font(PassTheme.font(10, bold: true)).tracking(1.4)
          }
          if pass.expired() {
            Text(L10n.text("EXPIRED")).font(PassTheme.font(11, bold: true))
          }
          Spacer()
          if let onInfo {
            Button(action: onInfo) {
              Text("i").font(.system(size: 15, weight: .bold, design: .serif))
                .frame(width: 18, height: 18)
                .background(pass.foreground.opacity(0.18), in: Circle())
                .overlay(Circle().stroke(pass.foreground.opacity(0.4), lineWidth: 1))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }.buttonStyle(.plain).accessibilityLabel(L10n.text("Pass information"))
              .accessibilityIdentifier("pass-info")
          }
        }.foregroundStyle(pass.foreground.opacity(0.65)).padding(.leading, 18).padding(.trailing, 4)
      }
    }.foregroundStyle(pass.foreground)
      .frame(maxWidth: .infinity, minHeight: minimumHeight, alignment: .top)
      .background {
        if pass.sampleStyle != nil {
          HistoricalPassSurface(pass: pass)
        } else {
          LinearGradient(
            colors: [
              pass.background.mixWithWhite(0.08), pass.background,
              pass.background.mixWithBlack(0.08),
            ], startPoint: .top, endPoint: .bottom
          )
          .overlay(alignment: .top) { Color.white.opacity(0.3).frame(height: 1) }
        }
      }
      .clipShape(
        TicketSilhouette(kind: pass.sampleStyle == nil ? pass.kind : .generic),
        style: FillStyle(eoFill: true)
      )
      .overlay(RoundedRectangle(cornerRadius: 6).stroke(.black.opacity(0.3), lineWidth: 1))
      .shadow(color: .black.opacity(0.65), radius: 3, y: 2)
  }

  private var primaryFields: some View {
    HStack(alignment: .top, spacing: 12) {
      ForEach(pass.primary) { field in
        VStack(alignment: .leading, spacing: 5) {
          Text(pass.displayLabel(field.label)).font(PassTheme.font(11)).foregroundStyle(
            pass.labelColor)
          Text(pass.display(field.value))
            .font(PassTheme.font(pass.kind == .boardingPass || pass.kind == .coupon ? 44 : 25))
            .minimumScaleFactor(0.65).lineLimit(2)
        }.frame(maxWidth: .infinity, alignment: .leading)
        if pass.kind == .boardingPass, field.id == pass.primary.first?.id, pass.primary.count > 1 {
          Image(systemName: "airplane").font(.system(size: 24)).padding(.top, 24)
            .accessibilityHidden(true)
        }
      }
    }
  }

  private func fields(_ values: [PassField]) -> some View {
    HStack(alignment: .top, spacing: 10) {
      ForEach(values) { field in
        VStack(alignment: .leading, spacing: 3) {
          Text(pass.displayLabel(field.label)).font(PassTheme.font(10)).foregroundStyle(
            pass.labelColor)
          Text(pass.display(field.value)).font(PassTheme.font(17)).lineLimit(3).minimumScaleFactor(
            0.8)
        }.frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }
}

struct PassTray: View {
  var pass: PocketPass?
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      VStack(spacing: -3) {
        ForEach(0..<4, id: \.self) { index in
          RoundedRectangle(cornerRadius: 4)
            .fill(Color(passHex: ["E0B92B", "B43437", "DDD9DA", "95C1DA"][index]))
            .frame(height: 7).padding(.horizontal, CGFloat(10 - index * 2))
            .overlay(alignment: .top) {
              Color.white.opacity(0.4).frame(height: 1).padding(.horizontal, 12)
            }
        }
        Group {
          if let pass, pass.sampleStyle != nil {
            HistoricalPassHeader(pass: pass)
              .background(HistoricalPassSurface(pass: pass))
          } else {
            HStack {
              Image(systemName: pass?.kind.symbol ?? "rectangle.stack.fill")
              Text(pass?.organization ?? L10n.text("All Passes"))
                .font(PassTheme.font(14, bold: true)).lineLimit(1)
              Spacer()
              Image(systemName: "chevron.down").font(.system(size: 12, weight: .bold))
            }.padding(.horizontal, 14).frame(height: 44)
              .foregroundStyle(Color(passHex: "214D73"))
              .background(
                LinearGradient(
                  colors: [Color(passHex: "AEDAF4"), Color(passHex: "77B2D8")],
                  startPoint: .top, endPoint: .bottom))
          }
        }
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(.black.opacity(0.25), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.45), radius: 1, y: 1)
      }
    }.buttonStyle(.plain).accessibilityLabel(L10n.text("All Passes"))
      .accessibilityIdentifier("all-passes")
  }
}

struct CardFace: AnimatableModifier {
  var angle: Double
  var animatableData: Double {
    get { angle }
    set { angle = newValue }
  }
  func body(content: Content) -> some View {
    content.opacity(abs(angle) < 90 ? 1 : 0)
      .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.45)
  }
}

struct ShreddedPass: View {
  var pass: PocketPass
  var progress: Bool
  var body: some View {
    GeometryReader { geometry in
      let width = geometry.size.width / 14
      HStack(spacing: 0) {
        ForEach(0..<14, id: \.self) { index in
          PassCard(pass: pass).frame(width: geometry.size.width)
            .offset(x: -CGFloat(index) * width)
            .frame(width: width, alignment: .leading).clipped()
            .offset(y: progress ? geometry.size.height + CGFloat(index % 4) * 18 : 0)
            .rotationEffect(.degrees(progress ? Double(index % 3 - 1) * 9 : 0), anchor: .top)
        }
      }.opacity(progress ? 0 : 1)
    }.clipped().accessibilityHidden(true).allowsHitTesting(false)
  }
}
