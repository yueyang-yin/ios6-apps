import SwiftUI

enum NoteShareAction: String, CaseIterable {
  case mail = "Mail"
  case print = "Print"
  case copy = "Copy"

  var identifier: String { "share-" + rawValue.lowercased() }
}

struct ClassicShareOverlay: View {
  let presented: Bool
  let cancel: () -> Void
  let select: (NoteShareAction) -> Void
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .bottom) {
        if presented {
          Color.black.opacity(0.38)
            .ignoresSafeArea()
            .onTapGesture(perform: cancel)
            .accessibilityHidden(true)
            .transition(.opacity)
          VStack(spacing: 22) {
            HStack(alignment: .top, spacing: 0) {
              ForEach(NoteShareAction.allCases, id: \.self) { action in
                Button {
                  select(action)
                } label: {
                  VStack(spacing: 7) {
                    ClassicShareIcon(action: action).frame(width: 60, height: 60)
                    Text(L10n.text(action.rawValue))
                      .font(.custom("HelveticaNeue-Bold", size: 14))
                      .foregroundStyle(.white)
                      .shadow(color: .black, radius: 0.5, y: 1)
                  }
                  .frame(maxWidth: .infinity)
                  .contentShape(Rectangle())
                }
                .buttonStyle(ClassicShareTileStyle())
                .accessibilityIdentifier(action.identifier)
              }
            }
            Button(L10n.text("Cancel"), action: cancel)
              .buttonStyle(ClassicShareCancelStyle())
              .accessibilityIdentifier("cancel-share")
          }
          .padding(.horizontal, 21)
          .padding(.top, 26)
          .padding(.bottom, max(geometry.safeAreaInsets.bottom, 12) + 12)
          .background(ClassicShareBackground())
          .offset(y: geometry.safeAreaInsets.bottom)
          .accessibilityElement(children: .contain)
          .accessibilityAddTraits(.isModal)
          .accessibilityLabel(L10n.text("Share Note"))
          .accessibilityIdentifier("share-panel")
          .accessibilityAction(.escape, cancel)
          .transition(reduceMotion ? .opacity : .move(edge: .bottom))
        }
      }
    }
    .allowsHitTesting(presented)
  }
}

private struct ClassicShareTileStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label.opacity(configuration.isPressed ? 0.65 : 1)
  }
}

struct ClassicShareCancelStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.custom("HelveticaNeue-Bold", size: 21))
      .foregroundStyle(.white)
      .shadow(color: .black, radius: 0.5, y: -1)
      .frame(maxWidth: .infinity, minHeight: 47)
      .background {
        RoundedRectangle(cornerRadius: 10)
          .fill(
            LinearGradient(
              stops: [
                .init(color: Color(white: 0.42), location: 0),
                .init(color: Color(white: 0.24), location: 0.48),
                .init(color: Color(white: 0.07), location: 0.51),
                .init(color: Color(white: 0.015), location: 1),
              ], startPoint: .top, endPoint: .bottom)
          )
          .overlay {
            RoundedRectangle(cornerRadius: 10).stroke(.black.opacity(0.9), lineWidth: 1.5)
            RoundedRectangle(cornerRadius: 9).stroke(.white.opacity(0.16), lineWidth: 0.7)
              .padding(1)
          }
          .shadow(color: .black.opacity(0.5), radius: 1, y: 1)
      }
      .brightness(configuration.isPressed ? -0.15 : 0)
  }
}

private struct ClassicShareBackground: View {
  var body: some View {
    LinearGradient(
      stops: [
        .init(color: Color(red: 0.34, green: 0.38, blue: 0.40), location: 0),
        .init(color: Color(red: 0.12, green: 0.16, blue: 0.19), location: 0.22),
        .init(color: Color(red: 0.055, green: 0.07, blue: 0.09), location: 1),
      ], startPoint: .top, endPoint: .bottom
    )
    .overlay {
      Canvas { context, size in
        for y in stride(from: CGFloat(2), to: size.height, by: 3) {
          context.fill(
            Path(CGRect(x: 0, y: y, width: size.width, height: 0.5)),
            with: .color(.black.opacity(0.05)))
        }
      }
    }
    .overlay(alignment: .top) {
      VStack(spacing: 0) {
        Color.black.opacity(0.65).frame(height: 1)
        Color.white.opacity(0.5).frame(height: 1)
      }
    }
    .shadow(color: .black.opacity(0.45), radius: 5, y: -3)
    .accessibilityHidden(true)
  }
}

private struct ClassicShareIcon: View {
  let action: NoteShareAction

  var body: some View {
    ZStack {
      if action == .mail {
        LinearGradient(
          colors: [
            Color(red: 0.41, green: 0.66, blue: 0.96), Color(red: 0.1, green: 0.48, blue: 0.8),
          ],
          startPoint: .top, endPoint: .bottom)
      } else {
        LinearGradient(
          colors: [Color(white: 0.43), Color(white: 0.19)], startPoint: .top, endPoint: .bottom)
      }
      Canvas { context, size in
        context.scaleBy(x: size.width / 60, y: size.height / 60)
        if action == .mail {
          drawClouds(in: context)
          drawEnvelope(in: context)
        } else {
          drawPerforations(in: context)
          if action == .print { drawPrinter(in: context) } else { drawCopy(in: context) }
        }
      }
      VStack(spacing: 0) {
        LinearGradient(
          colors: [.white.opacity(0.40), .white.opacity(0.04)], startPoint: .top, endPoint: .bottom)
        Color.clear
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 11))
    .overlay {
      RoundedRectangle(cornerRadius: 11)
        .stroke(action == .mail ? .white.opacity(0.6) : Color(white: 0.83), lineWidth: 2.5)
      RoundedRectangle(cornerRadius: 9).stroke(.black.opacity(0.45), lineWidth: 0.7).padding(2)
    }
    .shadow(color: .black.opacity(0.6), radius: 2, y: 2)
    .accessibilityHidden(true)
  }

  private func drawClouds(in context: GraphicsContext) {
    for (x, y, width, height) in [
      (-8.0, 46.0, 28.0, 13.0), (5, 41, 24, 16), (23, 49, 35, 16), (43, 39, 25, 13),
    ] {
      context.fill(
        Path(ellipseIn: CGRect(x: x, y: y, width: width, height: height)),
        with: .color(.white.opacity(0.28)))
    }
  }

  private func drawPerforations(in context: GraphicsContext) {
    for row in 0..<20 {
      for column in 0..<20 {
        let x = CGFloat(column * 4 + (row.isMultiple(of: 2) ? 0 : 2))
        let y = CGFloat(row * 3)
        context.fill(
          Path(ellipseIn: CGRect(x: x, y: y + 0.7, width: 1.9, height: 1.9)),
          with: .color(.white.opacity(0.18)))
        context.fill(
          Path(ellipseIn: CGRect(x: x, y: y, width: 1.9, height: 1.9)),
          with: .color(.black.opacity(0.75)))
      }
    }
  }

  private func metal(
    _ rect: CGRect, in context: GraphicsContext, radius: CGFloat = 0,
    top: Double = 0.97, bottom: Double = 0.55
  ) {
    let path = Path(roundedRect: rect, cornerRadius: radius)
    context.fill(
      path,
      with: .linearGradient(
        Gradient(colors: [Color(white: top), Color(white: bottom)]),
        startPoint: CGPoint(x: rect.midX, y: rect.minY),
        endPoint: CGPoint(x: rect.midX, y: rect.maxY)))
    context.stroke(path, with: .color(.black.opacity(0.6)), lineWidth: 0.8)
  }

  private func drawEnvelope(in context: GraphicsContext) {
    metal(CGRect(x: 10, y: 19, width: 40, height: 28), in: context, bottom: 0.8)
    var lowerFold = Path()
    lowerFold.move(to: CGPoint(x: 10, y: 46))
    lowerFold.addLine(to: CGPoint(x: 30, y: 29))
    lowerFold.addLine(to: CGPoint(x: 50, y: 46))
    context.stroke(lowerFold, with: .color(.gray.opacity(0.55)), lineWidth: 0.8)
    var flap = Path()
    flap.move(to: CGPoint(x: 10, y: 19))
    flap.addLine(to: CGPoint(x: 30, y: 35))
    flap.addLine(to: CGPoint(x: 50, y: 19))
    flap.closeSubpath()
    var shadow = context
    shadow.addFilter(.shadow(color: .black.opacity(0.45), radius: 0.8, y: 1.5))
    shadow.fill(flap, with: .color(Color(white: 0.98)))
  }

  private func drawPrinter(in context: GraphicsContext) {
    metal(CGRect(x: 16, y: 11, width: 28, height: 19), in: context, bottom: 0.85)
    metal(
      CGRect(x: 9, y: 24, width: 42, height: 24), in: context, radius: 3, top: 0.85, bottom: 0.4)
    metal(
      CGRect(x: 11, y: 25, width: 38, height: 9), in: context, radius: 2, top: 0.96, bottom: 0.62)
    context.fill(Path(CGRect(x: 15, y: 38, width: 30, height: 7)), with: .color(Color(white: 0.08)))
    metal(CGRect(x: 18, y: 40, width: 24, height: 14), in: context, top: 0.98, bottom: 0.69)
    for y in stride(from: CGFloat(44), through: 50, by: 3) {
      context.fill(Path(CGRect(x: 21, y: y, width: 18, height: 0.7)), with: .color(.gray))
    }
    context.fill(
      Path(ellipseIn: CGRect(x: 13, y: 28, width: 2, height: 2)),
      with: .color(Color(red: 0.3, green: 0.43, blue: 0.28)))
    context.fill(Path(CGRect(x: 18, y: 28, width: 8, height: 1)), with: .color(.gray))
  }

  private func drawCopy(in context: GraphicsContext) {
    metal(CGRect(x: 14, y: 10, width: 25, height: 36), in: context, bottom: 0.75)
    metal(CGRect(x: 19, y: 15, width: 26, height: 38), in: context, top: 0.82, bottom: 0.42)
    var corner = Path()
    corner.move(to: CGPoint(x: 35, y: 15))
    corner.addLine(to: CGPoint(x: 45, y: 25))
    corner.addLine(to: CGPoint(x: 35, y: 25))
    corner.closeSubpath()
    context.fill(corner, with: .color(Color(white: 0.95)))
    context.stroke(corner, with: .color(.black.opacity(0.5)), lineWidth: 0.7)
    let plus = Path(CGRect(x: 29, y: 31, width: 6, height: 17))
      .union(Path(CGRect(x: 24, y: 36, width: 16, height: 6)))
    var shadow = context
    shadow.addFilter(.shadow(color: .white.opacity(0.5), radius: 0, y: 1))
    shadow.fill(plus, with: .color(Color(white: 0.22)))
  }
}

struct ClassicExportNotice: View {
  let failure: NoteExportFailure
  let dismiss: () -> Void

  var body: some View {
    ZStack {
      Color.black.opacity(0.4).ignoresSafeArea().accessibilityHidden(true)
      VStack(spacing: 14) {
        Text(L10n.text(failure.title)).font(.custom("HelveticaNeue-Bold", size: 18))
        Text(L10n.text(failure.message)).font(.custom("HelveticaNeue", size: 14))
        Button(L10n.text("OK"), action: dismiss)
          .buttonStyle(ClassicShareCancelStyle())
          .accessibilityIdentifier("dismiss-share-error")
      }
      .multilineTextAlignment(.center)
      .foregroundStyle(.white)
      .shadow(color: .black.opacity(0.8), radius: 0.5, y: -1)
      .padding(18)
      .frame(maxWidth: 300)
      .background {
        RoundedRectangle(cornerRadius: 12)
          .fill(
            LinearGradient(
              colors: [
                Color(red: 0.38, green: 0.46, blue: 0.59), Color(red: 0.14, green: 0.2, blue: 0.32),
              ],
              startPoint: .top, endPoint: .bottom)
          )
          .overlay {
            RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.55), lineWidth: 1.5)
          }
          .shadow(color: .black.opacity(0.5), radius: 8, y: 4)
      }
      .padding(20)
      .accessibilityElement(children: .contain)
      .accessibilityAddTraits(.isModal)
      .accessibilityIdentifier("share-error")
      .accessibilityAction(.escape, dismiss)
    }
  }
}
