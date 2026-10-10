import SwiftUI
import UIKit

struct CalculatorRootView: View {
  let calculator: CalculatorEngine
  @Environment(\.scenePhase) private var scenePhase
  @State private var restored = false
  private let language = AppLanguage.current
  private var testing: Bool { ProcessInfo.processInfo.arguments.contains("--uitesting") }

  var body: some View {
    GeometryReader { geometry in
      let scientific = geometry.size.width > geometry.size.height
      let screenHeight =
        scientific ? max(57, geometry.size.height * 0.20) : geometry.size.height * 0.20
      VStack(spacing: 0) {
        CalculatorDisplay(calculator: calculator, scientific: scientific, language: language)
          .frame(height: screenHeight)
        CalculatorKeyboard(
          calculator: calculator, scientific: scientific, language: language,
          press: press)
      }
      .onChange(of: scientific, initial: true) { calculator.scientific = scientific }
    }
    .background { CalculatorBody().ignoresSafeArea() }
    .onAppear {
      guard !restored else { return }
      if !testing { calculator.restore(from: .standard) }
      restored = true
    }
    .onChange(of: scenePhase) {
      if !testing && scenePhase != .active { calculator.save(to: .standard) }
    }
  }

  private func press(_ key: String) {
    calculator.press(key)
    if !testing { calculator.save(to: .standard) }
  }
}

private struct CalculatorBody: View {
  var body: some View {
    Color(white: 0.10)
      .overlay {
        Canvas { context, size in
          for x in stride(from: 0.0, through: size.width, by: 3) {
            var line = Path()
            line.move(to: CGPoint(x: x, y: 0))
            line.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(line, with: .color(.white.opacity(0.025)), lineWidth: 1)
          }
          for y in stride(from: 0.0, through: size.height, by: 3) {
            var line = Path()
            line.move(to: CGPoint(x: 0, y: y))
            line.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(line, with: .color(.black.opacity(0.24)), lineWidth: 1)
          }
        }.accessibilityHidden(true)
      }
  }
}

private struct CalculatorDisplay: View {
  let calculator: CalculatorEngine
  let scientific: Bool
  let language: AppLanguage
  @ScaledMetric(relativeTo: .largeTitle) private var typeScale: CGFloat = 1

  var body: some View {
    GeometryReader { geometry in
      let horizontalInset: CGFloat = scientific ? 16 : 19
      let indicatorInset: CGFloat = scientific ? 38 : calculator.parenthesisDepth > 0 ? 28 : 0
      let expressionHeight =
        calculator.showingResult
        ? min((scientific ? 19 : 27) * typeScale, geometry.size.height * 0.24) : 0
      let primaryHeight = geometry.size.height - expressionHeight - (scientific ? 12 : 22)
      let primaryFontSize = min(primaryHeight * 0.72 * typeScale, primaryHeight * 0.80)
      ZStack(alignment: .bottomLeading) {
        LinearGradient(
          stops: [
            .init(color: Color(red: 0.92, green: 0.93, blue: 0.85), location: 0),
            .init(color: Color(red: 0.81, green: 0.84, blue: 0.68), location: 0.63),
            .init(color: Color(red: 0.91, green: 0.93, blue: 0.83), location: 1),
          ], startPoint: .top, endPoint: .bottom)
        VStack(spacing: 0) {
          Color.black.opacity(0.45).frame(height: 1)
          Color.white.opacity(0.4).frame(height: 1)
          LinearGradient(
            colors: [.black.opacity(0.07), .clear], startPoint: .top, endPoint: .bottom
          ).frame(height: scientific ? 5 : 9)
          Spacer(minLength: 0)
          Color.white.opacity(0.9).frame(height: 2)
          Color.black.opacity(0.9).frame(height: 2)
        }.accessibilityHidden(true)
        VStack(spacing: 0) {
          if calculator.showingResult {
            CalculatorLCDLine(
              text: calculator.expression, fontName: "HelveticaNeue",
              fontSize: min((scientific ? 14 : 18) * typeScale, expressionHeight * 0.76),
              minimumScale: 1, width: geometry.size.width - horizontalInset * 2,
              height: expressionHeight, secondary: true,
              label: L10n.text("Current expression", language: language),
              identifier: "calculator-expression", scrollIdentifier: "expression-scroll"
            )
            .frame(height: expressionHeight)
          }
          CalculatorLCDLine(
            text: calculator.primaryDisplay(language: language), fontName: "HelveticaNeue-Light",
            fontSize: primaryFontSize, minimumScale: calculator.showingResult ? 0.25 : 0.42,
            width: geometry.size.width - horizontalInset * 2 - indicatorInset,
            height: primaryHeight, secondary: false,
            label: L10n.text(
              calculator.showingResult ? "Display" : "Current expression", language: language),
            identifier: "calculator-display", scrollIdentifier: "calculator-input-scroll",
            deleteDigit: calculator.deleteDigit
          )
          .frame(height: primaryHeight)
          .padding(.leading, indicatorInset)
          .contextMenu {
            Button(L10n.text("Copy", language: language)) {
              UIPasteboard.general.string = calculator.input
            }
            .disabled(calculator.error)
            .accessibilityIdentifier("copy-result")
            Button(L10n.text("Paste", language: language)) {
              if let text = UIPasteboard.general.string { calculator.paste(text) }
            }
            .accessibilityIdentifier("paste-result")
          }
          .accessibilityAction(named: Text(L10n.text("Delete last digit", language: language))) {
            calculator.deleteDigit()
          }
        }
        .padding(.horizontal, horizontalInset)
        .padding(.top, scientific ? 5 : 8)
        .padding(.bottom, scientific ? 7 : 14)
        HStack(spacing: 12) {
          if scientific { Text(calculator.radians ? "Rad" : "Deg") }
          if calculator.parenthesisDepth > 0 { Text("(" + String(calculator.parenthesisDepth)) }
        }
        .font(
          .custom(
            "HelveticaNeue",
            fixedSize: min(
              (scientific ? 12 : 14) * typeScale,
              geometry.size.height * 0.23))
        )
        .foregroundStyle(Color(red: 0.16, green: 0.22, blue: 0.14))
        .padding(.leading, 12).padding(.bottom, 6)
        .accessibilityLabel(
          L10n.text(calculator.radians ? "Radians" : "Degrees", language: language))
      }
    }
  }
}

private struct CalculatorLCDLine: View {
  let text: String
  let fontName: String
  let fontSize: CGFloat
  let minimumScale: CGFloat
  let width: CGFloat
  let height: CGFloat
  let secondary: Bool
  let label: String
  let identifier: String
  let scrollIdentifier: String
  var deleteDigit: (() -> Void)?

  private var fittedFontSize: CGFloat {
    let font = UIFont(name: fontName, size: fontSize) ?? .systemFont(ofSize: fontSize)
    let measuredWidth = (text as NSString).size(withAttributes: [.font: font]).width
    return max(fontSize * minimumScale, min(fontSize, fontSize * width / max(1, measuredWidth)))
  }

  private var scrollable: Bool {
    let font = UIFont(name: fontName, size: fittedFontSize) ?? .systemFont(ofSize: fittedFontSize)
    return (text as NSString).size(withAttributes: [.font: font]).width > width + 0.5
  }

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView(.horizontal) {
        Text(text)
          .font(.custom(fontName, fixedSize: fittedFontSize))
          .foregroundStyle(
            secondary
              ? Color(red: 0.21, green: 0.27, blue: 0.17)
              : Color(red: 0.10, green: 0.17, blue: 0.10)
          )
          .shadow(color: .white.opacity(0.28), radius: 0, x: 0, y: 1)
          .lineLimit(1)
          .fixedSize(horizontal: true, vertical: false)
          .frame(minWidth: width, minHeight: height, alignment: .trailing)
          .id("lcd-end")
          .accessibilityLabel(label)
          .accessibilityValue(text)
          .accessibilityIdentifier(identifier)
      }
      .scrollIndicators(.hidden)
      .scrollDisabled(!scrollable)
      .accessibilityIdentifier(scrollIdentifier)
      .onChange(of: text, initial: true) { proxy.scrollTo("lcd-end", anchor: .trailing) }
      .onChange(of: width) { proxy.scrollTo("lcd-end", anchor: .trailing) }
      .simultaneousGesture(
        DragGesture(minimumDistance: 20).onEnded { value in
          if !scrollable && abs(value.translation.width) > abs(value.translation.height) {
            deleteDigit?()
          }
        })
    }
  }
}

private struct CalculatorKeyboard: View {
  let calculator: CalculatorEngine
  let scientific: Bool
  let language: AppLanguage
  let press: (String) -> Void
  @ScaledMetric(relativeTo: .title2) private var typeScale: CGFloat = 1

  var body: some View {
    GeometryReader { geometry in
      let columns = scientific ? 8 : 4
      let horizontal = scientific ? 5.0 : 12.0
      let gap = scientific ? 7.0 : 12.0
      let verticalGap = scientific ? 7.0 : min(21, geometry.size.height * 0.04)
      let top = scientific ? 7.0 : 14.0
      let bottom = scientific ? 6.0 : 12.0
      let width =
        (geometry.size.width - horizontal * 2 - gap * Double(columns - 1)) / Double(columns)
      let height = (geometry.size.height - top - bottom - verticalGap * 5) / 6
      ZStack(alignment: .topLeading) {
        ForEach(CalculatorKey.layout(scientific: scientific, calculator: calculator)) { key in
          let keyWidth = width * Double(key.columns) + gap * Double(key.columns - 1)
          let keyHeight = height * Double(key.rows) + verticalGap * Double(key.rows - 1)
          let selected =
            calculator.selectedOperator == key.id || (key.id == "second" && calculator.second)
          Button {
            press(key.id)
          } label: {
            Text(key.title)
              .font(
                .custom(
                  "HelveticaNeue-Bold",
                  fixedSize: min(fontSize(key, width: width) * typeScale, height * 0.70))
              )
              .lineLimit(1).minimumScaleFactor(0.45)
              .frame(
                maxWidth: .infinity, maxHeight: .infinity,
                alignment: key.id == "0" ? .leading : key.id == "equals" ? .bottom : .center
              )
              .padding(.horizontal, 3)
              .padding(.leading, key.id == "0" ? width * 0.40 : 0)
              .padding(.bottom, key.id == "equals" ? height * 0.14 : 0)
              .frame(width: keyWidth, height: keyHeight)
          }
          .buttonStyle(ClassicKeyStyle(material: key.material, selected: selected))
          .overlay {
            if key.id == "mr" && calculator.hasMemory {
              RoundedRectangle(cornerRadius: 4).inset(by: 3).stroke(
                .white.opacity(0.9), lineWidth: 2
              )
              .allowsHitTesting(false).accessibilityHidden(true)
            }
          }
          .accessibilityLabel(L10n.text(key.label, language: language))
          .accessibilityValue(
            key.id == "mr" && calculator.hasMemory
              ? L10n.text("Memory stored", language: language) : ""
          )
          .accessibilityAddTraits(selected ? .isSelected : [])
          .accessibilityIdentifier("key-" + key.id)
          .frame(width: keyWidth, height: max(44, keyHeight))
          .contentShape(Rectangle())
          .position(
            x: horizontal + Double(key.column) * (width + gap) + keyWidth / 2,
            y: top + Double(key.row) * (height + verticalGap) + keyHeight / 2)
        }
      }
    }
  }

  private func fontSize(_ key: CalculatorKey, width: CGFloat) -> CGFloat {
    if scientific {
      return key.material == .number || key.material == .equal
        ? min(25, width * 0.40) : min(19, width * 0.28)
    }
    return key.material == .memory ? min(26, width * 0.30) : min(39, width * 0.44)
  }
}
