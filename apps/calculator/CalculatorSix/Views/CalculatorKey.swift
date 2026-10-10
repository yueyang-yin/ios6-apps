import SwiftUI

struct CalculatorKey: Identifiable {
  enum Material { case number, memory, operation, equal }
  let id: String
  let title: String
  let label: String
  let column: Int
  let row: Int
  var columns = 1
  var rows = 1
  var material: Material = .memory

  static func layout(scientific: Bool, calculator: CalculatorEngine) -> [Self] {
    let offset = scientific ? 4 : 0
    var keys: [Self] = []
    func add(
      _ id: String, _ title: String, _ label: String, _ column: Int, _ row: Int,
      _ material: Material = .memory, columns: Int = 1, rows: Int = 1
    ) {
      keys.append(
        Self(
          id: id, title: title, label: label, column: column, row: row,
          columns: columns, rows: rows, material: material))
    }
    for (column, id, title, label) in [
      (0, "mc", "mc", "Clear memory"), (1, "m+", "m+", "Add to memory"),
      (2, "m−", "m−", "Subtract from memory"), (3, "mr", "mr", "Recall memory"),
    ] { add(id, title, label, offset + column, 0) }
    for (column, id, title, label) in [
      (
        0, "clear", calculator.clearTitle,
        calculator.clearTitle == "AC" ? "All clear" : "Clear entry"
      ),
      (1, "sign", "+/−", "Change sign"), (2, "÷", "÷", "Divide"), (3, "×", "×", "Multiply"),
    ] { add(id, title, label, offset + column, 1, .operation) }
    for row in 2...4 {
      for column in 0...2 {
        let digit = String((4 - row) * 3 + column + 1)
        add(digit, digit, digit, offset + column, row, .number)
      }
    }
    add("−", "−", "Subtract", offset + 3, 2, .operation)
    add("+", "+", "Add", offset + 3, 3, .operation)
    add("equals", "=", "Equals", offset + 3, 4, .equal, rows: 2)
    add("0", "0", "0", offset, 5, .number, columns: 2)
    add(".", ".", "Decimal point", offset + 2, 5, .number)
    if scientific {
      let second = calculator.second
      let science: [(String, String, String)] = [
        ("second", "2nd", "Second functions"), ("(", "(", "Open parenthesis"),
        (")", ")", "Close parenthesis"), ("percent", "%", "Percent"),
        ("reciprocal", "1/x", "Reciprocal"), ("square", "x²", "Square"),
        ("cube", "x³", "Cube"), ("power", "yˣ", "Power"),
        ("factorial", "x!", "Factorial"), ("sqrt", "√", "Square root"),
        ("root", "ˣ√y", "Nth root"), ("log", "log", "Base ten logarithm"),
        ("sin", second ? "sin⁻¹" : "sin", second ? "Inverse sine" : "Sine"),
        ("cos", second ? "cos⁻¹" : "cos", second ? "Inverse cosine" : "Cosine"),
        ("tan", second ? "tan⁻¹" : "tan", second ? "Inverse tangent" : "Tangent"),
        ("ln", second ? "log₂" : "ln", second ? "Base two logarithm" : "Natural logarithm"),
        (
          "sinh", second ? "sinh⁻¹" : "sinh", second ? "Inverse hyperbolic sine" : "Hyperbolic sine"
        ),
        (
          "cosh", second ? "cosh⁻¹" : "cosh",
          second ? "Inverse hyperbolic cosine" : "Hyperbolic cosine"
        ),
        (
          "tanh", second ? "tanh⁻¹" : "tanh",
          second ? "Inverse hyperbolic tangent" : "Hyperbolic tangent"
        ),
        ("exp", second ? "2ˣ" : "eˣ", second ? "Power of two" : "Exponential"),
        (
          "angle", calculator.radians ? "Deg" : "Rad",
          calculator.radians ? "Use degrees" : "Use radians"
        ),
        ("pi", "π", "Pi"), ("EE", "EE", "Enter exponent"), ("rand", "Rand", "Random number"),
      ]
      for (index, key) in science.enumerated() { add(key.0, key.1, key.2, index % 4, index / 4) }
    }
    return keys
  }
}

struct ClassicKeyStyle: ButtonStyle {
  let material: CalculatorKey.Material
  let selected: Bool
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private var colors: [Color] {
    switch material {
    case .number: return [Color(white: 0.31), Color(white: 0.13), .black, Color(white: 0.025)]
    case .memory:
      return [Color(white: 0.63), Color(white: 0.43), Color(white: 0.30), Color(white: 0.36)]
    case .operation:
      return [
        Color(red: 0.70, green: 0.66, blue: 0.62),
        Color(red: 0.46, green: 0.41, blue: 0.37), Color(red: 0.35, green: 0.30, blue: 0.27),
        Color(red: 0.42, green: 0.37, blue: 0.33),
      ]
    case .equal:
      return [
        Color(red: 1, green: 0.73, blue: 0.42),
        Color(red: 0.96, green: 0.49, blue: 0.13), Color(red: 0.90, green: 0.40, blue: 0.07),
        Color(red: 0.97, green: 0.52, blue: 0.14),
      ]
    }
  }

  func makeBody(configuration: Configuration) -> some View {
    let depressed = configuration.isPressed || selected
    configuration.label
      .foregroundStyle(.white)
      .shadow(color: .black.opacity(0.7), radius: 0, x: 0, y: -1)
      .background {
        RoundedRectangle(cornerRadius: 6)
          .fill(
            LinearGradient(
              stops: [
                .init(color: colors[0], location: 0), .init(color: colors[1], location: 0.44),
                .init(color: colors[2], location: 0.51), .init(color: colors[3], location: 1),
              ], startPoint: .top, endPoint: .bottom)
          )
          .overlay { RoundedRectangle(cornerRadius: 6).stroke(.black.opacity(0.9), lineWidth: 1) }
          .overlay {
            RoundedRectangle(cornerRadius: 5).inset(by: 1)
              .stroke(
                LinearGradient(
                  colors: [.white.opacity(0.5), .white.opacity(0.04)],
                  startPoint: .top, endPoint: .bottom), lineWidth: 1)
          }
          .overlay { RoundedRectangle(cornerRadius: 6).fill(.black.opacity(depressed ? 0.25 : 0)) }
          .overlay {
            if selected {
              RoundedRectangle(cornerRadius: 5).inset(by: 2).stroke(
                .white.opacity(0.8), lineWidth: 1.5)
            }
          }
          .shadow(color: .black.opacity(0.8), radius: depressed ? 0 : 1, x: 0, y: depressed ? 0 : 3)
      }
      .offset(y: configuration.isPressed ? 1 : 0)
      .animation(reduceMotion ? nil : .easeOut(duration: 0.07), value: configuration.isPressed)
  }
}
