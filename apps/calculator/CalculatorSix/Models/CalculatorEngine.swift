import Foundation
import Observation

@Observable
final class CalculatorEngine {
  private(set) var input = "0"
  private(set) var memory: Double = 0
  private(set) var hasMemory = false
  private(set) var radians = false
  private(set) var second = false
  private(set) var error = false
  private(set) var awaitingOperand = false
  private(set) var showingResult = false
  private var values: [Double] = []
  private var operators: [String] = []
  private var expressionValues: [String] = []
  private var expressionOperand: String?
  private var completedExpression: String?
  private var freshResult = true
  private var repeatOperation: String?
  private var repeatOperand: Double?
  private var entryCleared = true
  private var resultValue: Double?
  var scientific = false

  var value: Double { resultValue ?? Double(input) ?? 0 }
  var clearTitle: String { entryCleared ? "AC" : "C" }
  var parenthesisDepth: Int { operators.filter { $0 == "(" }.count }
  var selectedOperator: String? { awaitingOperand ? operators.last : nil }
  var expression: String { completedExpression ?? pendingExpression() }

  func primaryDisplay(language: AppLanguage = .current) -> String {
    showingResult ? display(language: language) : expression
  }

  private var operandExpression: String {
    expressionOperand
      ?? input.replacingOccurrences(of: "-", with: "−")
      .replacingOccurrences(of: "e+", with: "e")
  }

  private func pendingExpression(includeAwaitingOperand: Bool = false) -> String {
    var parts: [String] = []
    var index = 0
    var roots = 0
    for operation in operators {
      if operation == "(" {
        parts.append("(")
      } else {
        if index < expressionValues.count { parts.append(expressionValues[index]) }
        index += 1
        parts.append(operation == "root" ? "^ (1 ÷" : Self.expressionOperator(operation))
        if operation == "root" { roots += 1 }
      }
    }
    if !awaitingOperand || includeAwaitingOperand {
      parts.append(awaitingOperand ? display(language: .english) : operandExpression)
      parts.append(contentsOf: Array(repeating: ")", count: roots))
    }
    return parts.joined(separator: " ")
      .replacingOccurrences(of: "( ", with: "(")
      .replacingOccurrences(of: " )", with: ")")
  }

  private static func expressionOperator(_ operation: String) -> String {
    operation == "power" ? "^" : operation
  }

  private static func combinedExpression(_ lhs: String, _ operation: String, _ rhs: String)
    -> String
  {
    operation == "root"
      ? "\(lhs) ^ (1 ÷ \(rhs))"
      : "\(lhs) \(expressionOperator(operation)) \(rhs)"
  }

  func display(language: AppLanguage = .current) -> String {
    if error { return L10n.text("Error", language: language) }
    return input.replacingOccurrences(of: "-", with: "−")
      .replacingOccurrences(of: "e+", with: "e")
  }

  func press(_ key: String) {
    if let digit = Int(key), (0...9).contains(digit) {
      enter(key)
      return
    }
    switch key {
    case ".": enter(".")
    case "clear": clear()
    case "sign": changeSign()
    case "+", "−", "×", "÷", "power", "root": binary(key)
    case "equals": equals()
    case "mc":
      memory = 0
      hasMemory = false
    case "m+", "m−":
      guard !error else { return }
      let updated = memory + (key == "m+" ? value : -value)
      guard updated.isFinite else {
        fail()
        return
      }
      memory = updated
      hasMemory = true
      freshResult = true
    case "mr": setValue(memory)
    case "second": second.toggle()
    case "angle": radians.toggle()
    case "(": openParenthesis()
    case ")": closeParenthesis()
    case "percent": percentage()
    case "EE":
      guard !error, !input.contains("e") else { return }
      if awaitingOperand {
        prepareEntry()
        input = "1"
      } else if freshResult {
        resultValue = nil
        freshResult = false
        if input == "0" { input = "1" }
      }
      input += "e0"
      expressionOperand = nil
      completedExpression = nil
      showingResult = false
      freshResult = false
      entryCleared = false
    case "pi": setValue(.pi, expression: "π")
    case "rand": setValue(Double.random(in: 0..<1))
    default: unary(key)
    }
  }

  func deleteDigit() {
    guard !error, !awaitingOperand, !freshResult else { return }
    input.removeLast()
    expressionOperand = nil
    completedExpression = nil
    showingResult = false
    resultValue = nil
    if input.isEmpty || input == "-" { input = "0" }
    if input.last == "e" { input.removeLast() }
    entryCleared = input == "0"
  }

  func paste(_ text: String) {
    let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: "−", with: "-")
      .replacingOccurrences(of: ",", with: "")
    guard let number = Double(normalized), number.isFinite else { return }
    setValue(number)
  }

  private func prepareEntry() {
    if error { reset() }
    if freshResult && !awaitingOperand && operators.isEmpty {
      values = []
      expressionValues = []
    }
    if freshResult || awaitingOperand {
      input = "0"
      expressionOperand = nil
    }
    completedExpression = nil
    showingResult = false
    freshResult = false
    awaitingOperand = false
    resultValue = nil
    repeatOperation = nil
    repeatOperand = nil
  }

  private func enter(_ character: String) {
    prepareEntry()
    if input.contains("e") {
      guard character != "." else { return }
      let parts = input.components(separatedBy: "e")
      let exponent = parts[1]
      guard exponent.filter(\.isNumber).count < 3 else { return }
      input =
        parts[0] + "e"
        + (exponent == "0" ? character : exponent == "-0" ? "-" + character : exponent + character)
    } else if character == "." {
      if !input.contains(".") { input += "." }
    } else {
      let maximum = scientific ? 16 : 9
      guard input.filter(\.isNumber).count < maximum || input == "0" else { return }
      input = input == "0" ? character : input == "-0" ? "-" + character : input + character
    }
    entryCleared = false
  }

  private func changeSign() {
    guard !error else { return }
    if awaitingOperand { prepareEntry() }
    completedExpression = nil
    showingResult = false
    if let operand = expressionOperand {
      expressionOperand =
        operand.hasPrefix("−(") && operand.hasSuffix(")")
        ? String(operand.dropFirst(2).dropLast()) : "−(\(operand))"
    }
    if !freshResult, let index = input.firstIndex(of: "e") {
      let next = input.index(after: index)
      if input[next...].hasPrefix("-") {
        input.remove(at: next)
      } else {
        input.insert("-", at: next)
      }
    } else {
      if let result = resultValue { resultValue = -result }
      if input.hasPrefix("-") { input.removeFirst() } else { input = "-" + input }
    }
    if value == 0 { freshResult = false }
    entryCleared = false
  }

  private func priority(_ operation: String) -> Int {
    if operation == "(" { return 0 }
    if !scientific { return 1 }
    if operation == "power" || operation == "root" { return 3 }
    return operation == "×" || operation == "÷" ? 2 : 1
  }

  private func binary(_ operation: String) {
    guard !error else { return }
    guard value.isFinite else {
      fail()
      return
    }
    if awaitingOperand, let last = operators.last, last != "(" {
      operators.removeLast()
    } else if !awaitingOperand || values.isEmpty {
      values.append(value)
      expressionValues.append(operandExpression)
    }
    completedExpression = nil
    showingResult = false
    while let last = operators.last, last != "(",
      priority(last) >= priority(operation), !(last == "power" && operation == "power")
    {
      guard reduce() else { return }
    }
    operators.append(operation)
    if let result = values.last {
      input = Self.string(result)
      resultValue = result
    }
    awaitingOperand = true
    freshResult = false
    repeatOperation = nil
    repeatOperand = nil
    entryCleared = false
  }

  private func apply(_ operation: String, _ lhs: Double, _ rhs: Double) -> Double {
    switch operation {
    case "+": return lhs + rhs
    case "−": return lhs - rhs
    case "×": return lhs * rhs
    case "÷": return rhs == 0 ? .nan : lhs / rhs
    case "power": return pow(lhs, rhs)
    case "root":
      if lhs < 0, rhs.truncatingRemainder(dividingBy: 2) == 1 {
        return -pow(-lhs, 1 / rhs)
      }
      return pow(lhs, 1 / rhs)
    default: return .nan
    }
  }

  @discardableResult
  private func reduce() -> Bool {
    let failedExpression = expression
    guard values.count >= 2, let operation = operators.popLast(), operation != "(" else {
      fail()
      return false
    }
    let rhs = values.removeLast()
    let lhs = values.removeLast()
    let rhsExpression = expressionValues.removeLast()
    let lhsExpression = expressionValues.removeLast()
    let result = apply(operation, lhs, rhs)
    guard result.isFinite else {
      fail()
      completedExpression = failedExpression
      return false
    }
    values.append(result)
    expressionValues.append(Self.combinedExpression(lhsExpression, operation, rhsExpression))
    return true
  }

  private func equals() {
    guard !error else { return }
    if operators.isEmpty {
      if let operation = repeatOperation, let rhs = repeatOperand {
        let equation = Self.combinedExpression(
          display(language: .english), operation, Self.string(rhs))
        setValue(apply(operation, value, rhs), preserveRepeat: true)
        completedExpression = equation + " ="
      } else {
        guard value.isFinite else {
          fail()
          return
        }
        freshResult = true
        entryCleared = false
        values = []
        expressionValues = []
        if completedExpression == nil { completedExpression = operandExpression + " =" }
      }
      showingResult = true
      return
    }
    let equation =
      pendingExpression(includeAwaitingOperand: true)
      + String(repeating: ")", count: parenthesisDepth) + " ="
    values.append(value)
    expressionValues.append(awaitingOperand ? display(language: .english) : operandExpression)
    while let last = operators.last {
      if last == "(" {
        operators.removeLast()
      } else {
        repeatOperation = last
        repeatOperand = values.last
        if !reduce() {
          completedExpression = equation
          return
        }
      }
    }
    if let result = values.last { setValue(result, preserveRepeat: true) }
    values = []
    expressionValues = []
    completedExpression = equation
    showingResult = true
  }

  private func openParenthesis() {
    guard !error, parenthesisDepth < 32 else { return }
    if !awaitingOperand && !freshResult { binary("×") }
    completedExpression = nil
    showingResult = false
    operators.append("(")
    input = "0"
    expressionOperand = nil
    resultValue = nil
    awaitingOperand = true
    freshResult = false
  }

  private func closeParenthesis() {
    guard !error, parenthesisDepth > 0, !awaitingOperand else { return }
    values.append(value)
    expressionValues.append(operandExpression)
    while let last = operators.last, last != "(" {
      guard reduce() else { return }
    }
    operators.removeLast()
    if let result = values.popLast() {
      input = Self.string(result)
      resultValue = result
      expressionOperand = "(" + expressionValues.removeLast() + ")"
    }
    awaitingOperand = false
    freshResult = false
  }

  private func percentage() {
    guard !error else { return }
    let factor = operators.last == "+" || operators.last == "−" ? (values.last ?? 1) : 1
    setValue(
      factor * value / 100, expression: "(\(operandExpression))%", asResult: operators.isEmpty)
  }

  private func unary(_ key: String) {
    guard !error else { return }
    let x = value
    let angle = radians ? x : x * .pi / 180
    let inverseFactor = radians ? 1.0 : 180 / Double.pi
    let result: Double
    let operand = operandExpression
    completedExpression = nil
    switch key {
    case "square": expressionOperand = "(\(operand))²"
    case "cube": expressionOperand = "(\(operand))³"
    case "sqrt": expressionOperand = "√(\(operand))"
    case "reciprocal": expressionOperand = "(1 ÷ (\(operand)))"
    case "factorial": expressionOperand = "(\(operand))!"
    case "exp": expressionOperand = "\(second ? "2" : "e")^(\(operand))"
    case "ln": expressionOperand = "\(second ? "log₂" : "ln")(\(operand))"
    case "log": expressionOperand = "log(\(operand))"
    case "sin", "cos", "tan", "sinh", "cosh", "tanh":
      expressionOperand = "\(key)\(second ? "⁻¹" : "")(\(operand))"
    default: return
    }
    switch key {
    case "reciprocal": result = x == 0 ? .nan : 1 / x
    case "square": result = x * x
    case "cube": result = x * x * x
    case "sqrt": result = sqrt(x)
    case "factorial":
      guard x >= 0, x <= 170, x.rounded(.towardZero) == x else {
        fail()
        return
      }
      result = x < 2 ? 1 : (2...Int(x)).reduce(1.0) { $0 * Double($1) }
    case "log": result = log10(x)
    case "ln": result = second ? log2(x) : log(x)
    case "exp": result = pow(second ? 2 : M_E, x)
    case "sin": result = second ? asin(x) * inverseFactor : sin(angle)
    case "cos": result = second ? acos(x) * inverseFactor : cos(angle)
    case "tan":
      if !second && abs(cos(angle)) < 1e-14 {
        fail()
        return
      }
      result = second ? atan(x) * inverseFactor : tan(angle)
    case "sinh": result = second ? asinh(x) : sinh(x)
    case "cosh": result = second ? acosh(x) : cosh(x)
    case "tanh": result = second ? atanh(x) : tanh(x)
    default: return
    }
    let trigonometric = ["sin", "cos", "tan"].contains(key)
    setValue(
      trigonometric && abs(result) < 1e-15 ? 0 : result, expression: expressionOperand,
      asResult: operators.isEmpty)
  }

  private func setValue(
    _ result: Double, preserveRepeat: Bool = false, expression: String? = nil,
    asResult: Bool = false
  ) {
    expressionOperand = expression
    completedExpression = nil
    showingResult = asResult
    guard result.isFinite else {
      fail()
      return
    }
    input = Self.string(result)
    resultValue = result
    error = false
    awaitingOperand = false
    freshResult = true
    entryCleared = false
    if !preserveRepeat {
      repeatOperation = nil
      repeatOperand = nil
    }
  }

  private func clear() {
    repeatOperation = nil
    repeatOperand = nil
    if entryCleared || error {
      reset()
    } else {
      input = "0"
      expressionOperand = nil
      completedExpression = nil
      showingResult = false
      resultValue = nil
      awaitingOperand = false
      freshResult = false
      entryCleared = true
    }
  }

  private func reset() {
    input = "0"
    values = []
    operators = []
    expressionValues = []
    expressionOperand = nil
    completedExpression = nil
    showingResult = false
    error = false
    resultValue = nil
    freshResult = true
    awaitingOperand = false
    entryCleared = true
    repeatOperation = nil
    repeatOperand = nil
  }

  private func fail() {
    let failedExpression = expression
    reset()
    error = true
    showingResult = true
    completedExpression = failedExpression
  }

  private static func string(_ number: Double) -> String {
    if number == 0 { return "0" }
    return String(format: "%.15g", locale: Locale(identifier: "en_US_POSIX"), number)
  }

  private struct SavedState: Codable {
    let input: String
    let memory: Double
    let hasMemory: Bool
    let radians: Bool
    let second: Bool
    let error: Bool
    let awaitingOperand: Bool
    let values: [Double]
    let operators: [String]
    let freshResult: Bool
    let entryCleared: Bool
    let repeatOperation: String?
    let repeatOperand: Double?
    let resultValue: Double?
    let expressionValues: [String]?
    let expressionOperand: String?
    let completedExpression: String?
    let showingResult: Bool?
  }

  func save(to defaults: UserDefaults) {
    let state = SavedState(
      input: input, memory: memory, hasMemory: hasMemory, radians: radians,
      second: second, error: error, awaitingOperand: awaitingOperand, values: values,
      operators: operators, freshResult: freshResult, entryCleared: entryCleared,
      repeatOperation: repeatOperation, repeatOperand: repeatOperand, resultValue: resultValue,
      expressionValues: expressionValues, expressionOperand: expressionOperand,
      completedExpression: completedExpression, showingResult: showingResult)
    if let data = try? JSONEncoder().encode(state) {
      defaults.set(data, forKey: "calculator-state-v1")
    }
  }

  func restore(from defaults: UserDefaults) {
    guard let data = defaults.data(forKey: "calculator-state-v1"),
      let state = try? JSONDecoder().decode(SavedState.self, from: data)
    else { return }
    input = state.input
    memory = state.memory
    hasMemory = state.hasMemory
    radians = state.radians
    second = state.second
    error = state.error
    awaitingOperand = state.awaitingOperand
    values = state.values
    operators = state.operators
    freshResult = state.freshResult
    entryCleared = state.entryCleared
    repeatOperation = state.repeatOperation
    repeatOperand = state.repeatOperand
    resultValue = state.resultValue
    expressionValues =
      state.expressionValues?.count == state.values.count
      ? state.expressionValues! : state.values.map(Self.string)
    expressionOperand = state.expressionOperand
    completedExpression = state.completedExpression
    showingResult = state.showingResult ?? (state.completedExpression != nil)
  }
}
