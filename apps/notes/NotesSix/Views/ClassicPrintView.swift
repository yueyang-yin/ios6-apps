import SwiftUI

struct ClassicPrintView: View {
  let note: Note
  let dismiss: () -> Void
  @State private var model = ClassicPrintModel()
  @State private var choosingPrinter = false
  @State private var request: NoteExportRequest?
  @State private var failure: NoteExportFailure?

  var body: some View {
    VStack(spacing: 0) {
      ClassicPrintNavigationBar(
        title: L10n.text(choosingPrinter ? "Printers" : "Printer Options"),
        button: L10n.text(choosingPrinter ? "Printer Options" : "Cancel"),
        back: choosingPrinter, action: close,
        identifier: choosingPrinter ? "back-to-print-options" : "cancel-print")
      ScrollView {
        if choosingPrinter { printerList } else { options }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .background(PinstripeBackground().ignoresSafeArea())
    .preferredColorScheme(.light)
    .background {
      NoteExportPresenter(request: request) { error in
        request = nil
        if let error { failure = error } else { dismiss() }
      }
      .frame(width: 0, height: 0)
      .accessibilityHidden(true)
    }
    .allowsHitTesting(request == nil && failure == nil)
    .accessibilityHidden(request != nil || failure != nil)
    .overlay {
      ZStack {
        if let failure {
          ClassicExportNotice(failure: failure) { self.failure = nil }
        }
      }
      .allowsHitTesting(failure != nil)
    }
    .onChange(of: model.selectionVersion) { _, _ in
      choosingPrinter = false
      model.stopDiscovery()
    }
    .onDisappear { model.stopDiscovery() }
    .accessibilityAction(.escape, close)
  }

  private var options: some View {
    VStack(spacing: 28) {
      Button {
        choosingPrinter = true
        model.startDiscovery()
      } label: {
        HStack(spacing: 12) {
          Text(L10n.text("Printer")).font(.custom("HelveticaNeue-Bold", size: 17))
          Spacer(minLength: 8)
          Text(model.selectedName ?? L10n.text("Select Printer"))
            .font(.custom("HelveticaNeue", size: 17))
            .foregroundStyle(printBlue)
            .lineLimit(1)
          Image(systemName: "chevron.right")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(Color(white: 0.5))
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 14)
        .frame(minHeight: 49)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .classicPrintGroup()
      .accessibilityIdentifier("select-print-printer")

      HStack {
        Text(L10n.format(model.copies == 1 ? "%d Copy" : "%d Copies", model.copies))
          .font(.custom("HelveticaNeue-Bold", size: 17))
          .foregroundStyle(.black)
          .accessibilityIdentifier("print-copies")
        Spacer()
        ClassicCopiesStepper(
          decrease: { model.changeCopies(by: -1) }, increase: { model.changeCopies(by: 1) },
          canDecrease: model.copies > 1, canIncrease: model.copies < 99)
      }
      .padding(.horizontal, 14)
      .frame(minHeight: 49)
      .classicPrintGroup()

      Button(L10n.text("Print"), action: printNote)
        .buttonStyle(ClassicPrintActionStyle())
        .disabled(model.selectedPrinter == nil || request != nil)
        .accessibilityIdentifier("confirm-print")
    }
    .padding(.horizontal, 10)
    .padding(.top, 15)
    .padding(.bottom, 20)
  }

  private var printerList: some View {
    VStack(spacing: 18) {
      if !model.printers.isEmpty {
        VStack(spacing: 0) {
          ForEach(model.printers) { printer in
            Button {
              model.select(printer)
            } label: {
              HStack {
                Text(printer.name)
                  .font(.custom("HelveticaNeue-Bold", size: 17))
                  .foregroundStyle(.black)
                Spacer()
                if model.selectedName == printer.name {
                  Image(systemName: "checkmark").font(.system(size: 19, weight: .bold))
                    .foregroundStyle(printBlue)
                }
              }
              .padding(.horizontal, 14)
              .frame(minHeight: 49)
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(model.isConnecting)
            .accessibilityIdentifier("print-printer-" + printer.id)
            if printer.id != model.printers.last?.id {
              Color.gray.opacity(0.4).frame(height: 0.5)
            }
          }
        }
        .classicPrintGroup()
      }
      if model.isConnecting || model.searching {
        HStack(spacing: 9) {
          ProgressView().tint(printBlue)
          Text(L10n.text(model.isConnecting ? "Connecting to Printer…" : "Looking for Printers…"))
        }
      } else if model.printers.isEmpty {
        VStack(spacing: 12) {
          Text(L10n.text("No AirPrint Printers Found"))
            .font(.custom("HelveticaNeue-Bold", size: 17))
            .accessibilityIdentifier("no-print-printers")
          Text(
            L10n.text(
              model.discoveryFailed
                ? "Allow local network access for Notes in Settings, then try again."
                : "Connect this iPhone and your AirPrint printer to the same Wi-Fi network.")
          )
          .font(.custom("HelveticaNeue", size: 14))
          Button(L10n.text("Retry")) { model.startDiscovery() }
            .buttonStyle(ClassicPrintActionStyle())
            .accessibilityIdentifier("retry-print-discovery")
        }
        .padding(.horizontal, 12)
      }
      if model.selectionFailed {
        Text(L10n.text("Unable to connect to this printer. Try another printer."))
          .font(.custom("HelveticaNeue", size: 14))
          .accessibilityIdentifier("print-connection-error")
      }
    }
    .font(.custom("HelveticaNeue", size: 15))
    .foregroundStyle(printBlue)
    .shadow(color: .white.opacity(0.7), radius: 0, y: 1)
    .multilineTextAlignment(.center)
    .padding(.horizontal, 10)
    .padding(.top, 15)
    .padding(.bottom, 20)
  }

  private var printBlue: Color { Color(red: 0.23, green: 0.32, blue: 0.46) }

  private func close() {
    model.stopDiscovery()
    if choosingPrinter { choosingPrinter = false } else { dismiss() }
  }

  private func printNote() {
    guard let printer = model.selectedPrinter else { return }
    if model.selectedFixture {
      failure = .printUnavailable
      return
    }
    request = NoteExportRequest(note: note, action: .print, printer: printer, copies: model.copies)
  }
}

extension View {
  fileprivate func classicPrintGroup() -> some View {
    background(Color(white: 0.985), in: RoundedRectangle(cornerRadius: 10))
      .overlay { RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.62), lineWidth: 1) }
      .shadow(color: .white.opacity(0.6), radius: 0, y: 1)
  }
}

private struct ClassicPrintNavigationBar: View {
  let title: String
  let button: String
  let back: Bool
  let action: () -> Void
  let identifier: String

  var body: some View {
    ZStack {
      LinearGradient(
        stops: [
          .init(color: Color(red: 0.7, green: 0.75, blue: 0.82), location: 0),
          .init(color: Color(red: 0.51, green: 0.6, blue: 0.72), location: 0.49),
          .init(color: Color(red: 0.44, green: 0.53, blue: 0.66), location: 0.51),
          .init(color: Color(red: 0.38, green: 0.47, blue: 0.61), location: 1),
        ], startPoint: .top, endPoint: .bottom)
      Text(title)
        .font(.custom("HelveticaNeue-Bold", size: 20))
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.5), radius: 0, y: -1)
        .lineLimit(1)
        .padding(.horizontal, 95)
      HStack {
        Button(button, action: action)
          .font(.custom("HelveticaNeue-Bold", size: 13))
          .foregroundStyle(.white)
          .shadow(color: .black.opacity(0.5), radius: 0, y: -1)
          .padding(.leading, back ? 15 : 10)
          .padding(.trailing, 10)
          .frame(height: 29)
          .background {
            ClassicButtonShape(back: back)
              .fill(
                LinearGradient(
                  colors: [
                    Color(red: 0.55, green: 0.64, blue: 0.76),
                    Color(red: 0.24, green: 0.37, blue: 0.54),
                  ],
                  startPoint: .top, endPoint: .bottom)
              )
              .overlay {
                ClassicButtonShape(back: back).stroke(.black.opacity(0.45), lineWidth: 0.8)
              }
              .shadow(color: .white.opacity(0.3), radius: 0, y: 1)
          }
          .frame(minHeight: 44)
          .contentShape(Rectangle())
          .buttonStyle(.plain)
          .accessibilityIdentifier(identifier)
        Spacer()
      }
      .padding(.horizontal, 7)
    }
    .frame(height: 44)
    .overlay(alignment: .top) { Color.white.opacity(0.5).frame(height: 0.5) }
    .overlay(alignment: .bottom) { Color.black.opacity(0.4).frame(height: 1) }
  }
}

private struct ClassicCopiesStepper: View {
  let decrease: () -> Void
  let increase: () -> Void
  let canDecrease: Bool
  let canIncrease: Bool

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 5)
        .fill(
          LinearGradient(colors: [Color(white: 0.76), .white], startPoint: .top, endPoint: .bottom)
        )
        .overlay { RoundedRectangle(cornerRadius: 5).stroke(Color(white: 0.6), lineWidth: 1) }
        .frame(height: 31)
      HStack(spacing: 0) {
        control(
          "−", label: "Fewer Copies", id: "decrease-print-copies", enabled: canDecrease,
          action: decrease)
        Color.gray.opacity(0.35).frame(width: 0.5, height: 26)
        control(
          "+", label: "More Copies", id: "increase-print-copies", enabled: canIncrease,
          action: increase)
      }
    }
    .frame(width: 96, height: 44)
  }

  private func control(
    _ symbol: String, label: String, id: String, enabled: Bool, action: @escaping () -> Void
  ) -> some View {
    Button(symbol, action: action)
      .font(.custom("HelveticaNeue-Bold", size: 24))
      .foregroundStyle(Color(white: enabled ? 0.32 : 0.65))
      .shadow(color: .white, radius: 0, y: 1)
      .frame(maxWidth: .infinity, minHeight: 44)
      .contentShape(Rectangle())
      .buttonStyle(.plain)
      .disabled(!enabled)
      .accessibilityLabel(L10n.text(label))
      .accessibilityIdentifier(id)
  }
}

private struct ClassicPrintActionStyle: ButtonStyle {
  @Environment(\.isEnabled) private var enabled

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.custom("HelveticaNeue-Bold", size: 20))
      .foregroundStyle(.white.opacity(enabled ? 1 : 0.65))
      .shadow(color: .black.opacity(0.5), radius: 0, y: -1)
      .frame(maxWidth: .infinity, minHeight: 44)
      .background {
        RoundedRectangle(cornerRadius: 7)
          .fill(
            LinearGradient(
              colors: [
                Color(red: 0.35, green: 0.42, blue: 0.54),
                Color(red: 0.10, green: 0.17, blue: 0.29),
              ],
              startPoint: .top, endPoint: .bottom)
          )
          .overlay { RoundedRectangle(cornerRadius: 7).stroke(.black.opacity(0.45), lineWidth: 1) }
          .shadow(color: .white.opacity(0.7), radius: 0, y: 1)
      }
      .opacity(enabled ? 1 : 0.65)
      .brightness(configuration.isPressed ? -0.15 : 0)
  }
}
