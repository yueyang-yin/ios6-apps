import XCTest

@testable import CalculatorSix

final class CalculatorSixTests: XCTestCase {
  private func calculate(_ keys: [String], scientific: Bool = false) -> CalculatorEngine {
    let engine = CalculatorEngine()
    engine.scientific = scientific
    keys.forEach(engine.press)
    return engine
  }

  func testArithmeticAndRepeatedEquals() {
    for (operation, expected) in [("+", 10.0), ("−", 4), ("×", 21), ("÷", 7.0 / 3)] {
      let engine = calculate(["7", operation, "3", "equals"])
      XCTAssertEqual(engine.value, expected, accuracy: 1e-12)
    }
    let engine = calculate(["2", "+", "3", "equals", "equals", "equals"])
    XCTAssertEqual(engine.value, 11)
  }

  func testBasicImmediateAndScientificPrecedence() {
    XCTAssertEqual(calculate(["2", "+", "3", "×", "4", "equals"]).value, 20)
    let scientific = calculate(["2", "+", "3", "×", "4", "equals"], scientific: true)
    XCTAssertEqual(scientific.value, 14)
    scientific.press("equals")
    XCTAssertEqual(scientific.value, 26)
    XCTAssertEqual(
      calculate(["2", "power", "3", "power", "2", "equals"], scientific: true).value, 512)
  }

  func testOperatorReplacementAndMissingOperand() {
    XCTAssertEqual(calculate(["8", "+", "×", "2", "equals"]).value, 16)
    XCTAssertEqual(calculate(["5", "+", "equals"]).value, 10)
  }

  func testEntryClearAllClearAndMemorySurvival() {
    let engine = calculate(["9", "m+", "+", "7", "clear", "2", "equals"])
    XCTAssertEqual(engine.value, 11)
    engine.press("clear")
    XCTAssertEqual(engine.clearTitle, "AC")
    engine.press("clear")
    engine.press("mr")
    XCTAssertEqual(engine.value, 9)
    XCTAssertTrue(engine.hasMemory)
  }

  func testMemoryAddSubtractRecallAndClear() {
    let engine = calculate(["1", "2", "m+", "3", "m−", "mr"])
    XCTAssertEqual(engine.value, 9)
    engine.press("mc")
    XCTAssertFalse(engine.hasMemory)
    engine.press("mr")
    XCTAssertEqual(engine.value, 0)
  }

  func testDecimalsSignAndEntryLimit() {
    XCTAssertEqual(calculate([".", "1", "+", ".", "2", "equals"]).input, "0.3")
    let engine = calculate(["sign", "2", ".", ".", "5"])
    XCTAssertEqual(engine.input, "-2.5")
    for _ in 0..<20 { engine.press("1") }
    XCTAssertEqual(engine.input.filter(\.isNumber).count, 9)
    engine.press("sign")
    XCTAssertGreaterThan(engine.value, 0)
  }

  func testDeleteAndValidatedPaste() {
    let engine = calculate(["1", "2", "3"])
    engine.deleteDigit()
    XCTAssertEqual(engine.input, "12")
    engine.deleteDigit()
    engine.deleteDigit()
    XCTAssertEqual(engine.input, "0")
    engine.paste(" −1,234.5 ")
    XCTAssertEqual(engine.value, -1234.5)
    engine.paste("not a number")
    XCTAssertEqual(engine.value, -1234.5)
  }

  func testEqualsEndsEntryAndConstantsKeepPrecision() {
    XCTAssertEqual(calculate(["1", "2", "equals", "3"]).value, 3)
    let engine = calculate(["pi"], scientific: true)
    XCTAssertEqual(engine.value, Double.pi)
    engine.press("sign")
    XCTAssertEqual(engine.value, -Double.pi)
    engine.press("sin")
    XCTAssertEqual(engine.value, sin(-Double.pi * .pi / 180), accuracy: 1e-15)
  }

  func testNestedParenthesesAndImplicitMultiplication() {
    XCTAssertEqual(
      calculate(
        ["(", "2", "+", "(", "3", "×", "4", ")", ")", "×", "5", "equals"], scientific: true
      ).value, 70)
    XCTAssertEqual(calculate(["2", "(", "3", "+", "4", ")", "equals"], scientific: true).value, 14)
    XCTAssertEqual(calculate(["(", "2", "+", "3", "equals"], scientific: true).value, 5)
    XCTAssertEqual(calculate([")", "2", "equals"], scientific: true).value, 2)
  }

  func testPercentMarkupsDiscountsAndMultiplication() {
    for (operation, expected) in [("+", 540.0), ("−", 460), ("×", 40)] {
      XCTAssertEqual(
        calculate(["5", "0", "0", operation, "8", "percent", "equals"], scientific: true).value,
        expected)
    }
    XCTAssertEqual(calculate(["5", "percent"]).value, 0.05)
  }

  func testPowersRootsAndFactorial() {
    for (key, expected) in [
      ("square", 16.0), ("cube", 64), ("sqrt", 2), ("reciprocal", 0.25), ("factorial", 24),
    ] {
      XCTAssertEqual(calculate(["4", key], scientific: true).value, expected)
    }
    XCTAssertEqual(calculate(["0", "factorial"]).value, 1)
    XCTAssertEqual(
      calculate(["8", "1", "root", "4", "equals"], scientific: true).value, 3, accuracy: 1e-12)
    XCTAssertEqual(
      calculate(["8", "sign", "root", "3", "equals"], scientific: true).value, -2, accuracy: 1e-12)
  }

  func testDegreesRadiansAndInverseTrig() {
    XCTAssertEqual(calculate(["3", "0", "sin"], scientific: true).value, 0.5, accuracy: 1e-12)
    XCTAssertEqual(calculate(["6", "0", "cos"], scientific: true).value, 0.5, accuracy: 1e-12)
    XCTAssertEqual(calculate(["4", "5", "tan"], scientific: true).value, 1, accuracy: 1e-12)
    XCTAssertEqual(calculate(["angle", "pi", "sin"], scientific: true).value, 0)
    XCTAssertEqual(
      calculate([".", "5", "second", "sin"], scientific: true).value, 30, accuracy: 1e-12)
    XCTAssertEqual(
      calculate([".", "5", "second", "cos"], scientific: true).value, 60, accuracy: 1e-12)
    XCTAssertEqual(calculate(["1", "second", "tan"], scientific: true).value, 45, accuracy: 1e-12)
  }

  func testLogarithmsExponentialsAndHyperbolicFunctions() {
    XCTAssertEqual(calculate(["1", "0", "0", "log"]).value, 2)
    XCTAssertEqual(calculate(["1", "exp", "ln"]).value, 1, accuracy: 1e-12)
    XCTAssertEqual(calculate(["8", "second", "ln"]).value, 3)
    XCTAssertEqual(calculate(["3", "second", "exp"]).value, 8)
    for key in ["sinh", "cosh", "tanh"] {
      XCTAssertEqual(
        calculate(["1", key, "second", key], scientific: true).value, 1, accuracy: 1e-12)
    }
    let small = calculate(["1", "0", "0", "sign", "exp"])
    XCTAssertGreaterThan(small.value, 0)
  }

  func testExponentEntryAndRandomRange() {
    let engine = calculate(["2", "EE", "sign", "3"], scientific: true)
    XCTAssertEqual(engine.value, 0.002)
    engine.deleteDigit()
    XCTAssertTrue(engine.value.isFinite)
    for _ in 0..<100 {
      engine.press("rand")
      XCTAssertTrue((0..<1).contains(engine.value))
    }
    XCTAssertEqual(calculate(["4", "square", "EE", "2"]).value, 1600)
    XCTAssertTrue(calculate(["2", "EE", "9", "9", "9", "equals"]).error)
    XCTAssertTrue(calculate(["2", "EE", "9", "9", "9", "+"]).error)
    XCTAssertEqual(calculate(["2", "+", "3", "equals", "clear", "equals"]).value, 0)
  }

  func testInvalidDomainsOverflowAndRecovery() {
    for keys in [
      ["1", "÷", "0", "equals"], ["1", "sign", "sqrt"], ["0", "ln"],
      ["1", ".", "5", "factorial"], ["1", "7", "1", "factorial"], ["9", "0", "tan"],
      ["9", "9", "9", "exp"], ["2", "second", "sin"],
    ] {
      let engine = calculate(keys, scientific: true)
      XCTAssertTrue(engine.error, "\(keys)")
      XCTAssertEqual(engine.display(language: .english), "Error")
      XCTAssertEqual(engine.display(language: .chinese), "错误")
      engine.press("7")
      XCTAssertEqual(engine.value, 7)
      XCTAssertFalse(engine.error)
    }
  }

  func testStateRestorationPreservesExpressionAndPreferences() {
    let name = "CalculatorSixTests-" + UUID().uuidString
    let defaults = UserDefaults(suiteName: name)!
    defer { defaults.removePersistentDomain(forName: name) }
    let engine = calculate(["4", "m+", "angle", "second", "+", "2"])
    engine.save(to: defaults)
    let restored = CalculatorEngine()
    restored.restore(from: defaults)
    XCTAssertTrue(restored.radians)
    XCTAssertTrue(restored.second)
    XCTAssertEqual(restored.memory, 4)
    XCTAssertTrue(restored.hasMemory)
    restored.press("equals")
    XCTAssertEqual(restored.value, 6)
  }

  func testLanguageSelectionAndResourceCompleteness() {
    for identifier in ["zh", "zh-Hans", "zh-Hant-TW", "zh-CN"] {
      XCTAssertEqual(AppLanguage.preferred([identifier]), .chinese)
    }
    for languages in [["en"], ["fr", "zh-Hans"], []] {
      XCTAssertEqual(AppLanguage.preferred(languages), .english)
    }
    let engine = CalculatorEngine()
    for second in [false, true] {
      if second { engine.press("second") }
      for key in CalculatorKey.layout(scientific: true, calculator: engine) {
        if Int(key.label) == nil {
          XCTAssertNotEqual(L10n.text(key.label, language: .chinese), key.label)
        }
      }
    }
  }

  func testExpressionEntryEqualsRepeatAndNewCalculation() {
    let engine = calculate(["7", "×"])
    XCTAssertEqual(engine.expression, "7 ×")
    engine.press("7")
    XCTAssertEqual(engine.expression, "7 × 7")
    engine.press("equals")
    XCTAssertEqual(engine.expression, "7 × 7 =")
    XCTAssertEqual(engine.value, 49)
    engine.press("equals")
    XCTAssertEqual(engine.expression, "49 × 7 =")
    XCTAssertEqual(engine.value, 343)
    engine.press("+")
    XCTAssertEqual(engine.expression, "343 +")
    engine.press("2")
    engine.press("equals")
    engine.press("8")
    XCTAssertEqual(engine.expression, "8")
    XCTAssertEqual(engine.value, 8)
    XCTAssertEqual(calculate(["5", "+", "equals"]).expression, "5 + 5 =")
  }

  func testExpressionEditingClearAndOperatorReplacement() {
    let engine = calculate(["8", "+", "×", "2", "3"])
    XCTAssertEqual(engine.expression, "8 × 23")
    engine.deleteDigit()
    XCTAssertEqual(engine.expression, "8 × 2")
    engine.press("sign")
    XCTAssertEqual(engine.expression, "8 × −2")
    engine.press("clear")
    XCTAssertEqual(engine.expression, "8 × 0")
    engine.press("4")
    engine.press("equals")
    XCTAssertEqual(engine.expression, "8 × 4 =")
    XCTAssertEqual(engine.value, 32)
    engine.press("clear")
    engine.press("clear")
    XCTAssertEqual(engine.expression, "0")
    XCTAssertEqual(calculate(["2", "EE", "sign", "3"]).expression, "2e−3")
    XCTAssertEqual(calculate(["4", "square", "EE", "2"]).expression, "16e2")
  }

  func testExpressionMatchesImmediateAndScientificEvaluation() {
    let basic = calculate(["2", "+", "3", "×", "4", "equals"])
    XCTAssertEqual(basic.expression, "2 + 3 × 4 =")
    XCTAssertEqual(basic.value, 20)
    let science = calculate(["2", "+", "3", "×", "4", "equals"], scientific: true)
    XCTAssertEqual(science.expression, "2 + 3 × 4 =")
    XCTAssertEqual(science.value, 14)
    XCTAssertEqual(
      calculate(["2", "power", "3", "power", "2", "equals"], scientific: true).expression,
      "2 ^ 3 ^ 2 =")
    XCTAssertEqual(
      calculate(["8", "1", "root", "4", "equals"], scientific: true).expression,
      "81 ^ (1 ÷ 4) =")
  }

  func testExpressionParenthesesScientificFunctionsAndPercentage() {
    let engine = calculate(["(", "2", "+", "3", ")", "×", "4"], scientific: true)
    XCTAssertEqual(engine.expression, "(2 + 3) × 4")
    engine.press("equals")
    XCTAssertEqual(engine.expression, "(2 + 3) × 4 =")
    XCTAssertEqual(calculate(["(", "(", "2", "+", "3", "equals"]).expression, "((2 + 3)) =")
    XCTAssertEqual(calculate(["2", "(", "3", "+", "4", ")", "equals"]).value, 14)
    XCTAssertEqual(calculate(["3", "0", "sin"]).expression, "sin(30)")
    XCTAssertEqual(calculate([".", "5", "second", "sin"]).expression, "sin⁻¹(0.5)")
    XCTAssertEqual(calculate(["pi", "+", "2"]).expression, "π + 2")
    XCTAssertEqual(calculate(["5", "0", "0", "+", "8", "percent"]).expression, "500 + (8)%")
    XCTAssertEqual(calculate(["4", "square", "sign", "sign"]).expression, "(4)²")
  }

  func testExpressionMemoryPasteAndErrorRecovery() {
    let engine = calculate(["9", "m+", "clear", "clear", "2", "+", "mr"])
    XCTAssertEqual(engine.expression, "2 + 9")
    engine.paste("1,234")
    XCTAssertEqual(engine.expression, "2 + 1234")
    engine.press("equals")
    XCTAssertEqual(engine.value, 1236)
    let failed = calculate(["1", "÷", "0", "equals"])
    XCTAssertTrue(failed.error)
    XCTAssertEqual(failed.expression, "1 ÷ 0 =")
    failed.press("7")
    XCTAssertEqual(failed.expression, "7")
    XCTAssertEqual(calculate(["1", "sign", "sqrt"]).expression, "√(−1)")
  }

  func testExpressionRestorationAndLegacyStateMigration() throws {
    let name = "CalculatorSixExpressionTests-" + UUID().uuidString
    let defaults = UserDefaults(suiteName: name)!
    defer { defaults.removePersistentDomain(forName: name) }
    let engine = calculate(["2", "+", "3", "×", "4"])
    engine.save(to: defaults)
    let restored = CalculatorEngine()
    restored.restore(from: defaults)
    XCTAssertEqual(restored.expression, "2 + 3 × 4")
    restored.press("equals")
    XCTAssertEqual(restored.value, 20)
    restored.save(to: defaults)
    let completed = CalculatorEngine()
    completed.restore(from: defaults)
    XCTAssertEqual(completed.expression, "2 + 3 × 4 =")
    var legacy = try XCTUnwrap(
      JSONSerialization.jsonObject(with: XCTUnwrap(defaults.data(forKey: "calculator-state-v1")))
        as? [String: Any])
    for key in ["expressionValues", "expressionOperand", "completedExpression", "showingResult"] {
      legacy.removeValue(forKey: key)
    }
    defaults.set(try JSONSerialization.data(withJSONObject: legacy), forKey: "calculator-state-v1")
    let migrated = CalculatorEngine()
    migrated.restore(from: defaults)
    XCTAssertEqual(migrated.value, 20)
    migrated.press("equals")
    XCTAssertEqual(migrated.expression, "20 × 4 =")
    XCTAssertEqual(migrated.value, 80)
  }

  func testLCDInputAndResultPhases() {
    let engine = calculate(["7", "×", "7"])
    XCTAssertFalse(engine.showingResult)
    XCTAssertEqual(engine.primaryDisplay(), "7 × 7")
    engine.press("equals")
    XCTAssertTrue(engine.showingResult)
    XCTAssertEqual(engine.primaryDisplay(), "49")
    XCTAssertEqual(engine.expression, "7 × 7 =")
    engine.press("equals")
    XCTAssertEqual(engine.primaryDisplay(), "343")
    engine.press("+")
    XCTAssertFalse(engine.showingResult)
    XCTAssertEqual(engine.primaryDisplay(), "343 +")
    engine.press("2")
    engine.press("clear")
    XCTAssertEqual(engine.primaryDisplay(), "343 + 0")
    engine.press("clear")
    XCTAssertFalse(engine.showingResult)
    XCTAssertEqual(engine.primaryDisplay(), "0")
    let scientific = calculate(["2", "+", "3", "0", "sin"], scientific: true)
    XCTAssertFalse(scientific.showingResult)
    XCTAssertEqual(scientific.primaryDisplay(), "2 + sin(30)")
    scientific.press("equals")
    XCTAssertTrue(scientific.showingResult)
    XCTAssertEqual(scientific.primaryDisplay(), "2.5")
    XCTAssertTrue(calculate(["3", "0", "sin"]).showingResult)
    XCTAssertFalse(calculate(["pi"]).showingResult)
    let failed = calculate(["1", "÷", "0", "equals"])
    XCTAssertTrue(failed.showingResult)
    XCTAssertEqual(failed.primaryDisplay(language: .chinese), "错误")
    failed.press("7")
    XCTAssertFalse(failed.showingResult)
  }

  func testChainedExpressionKeepsOnlyUserParentheses() {
    let chained = calculate(["1", "+", "2", "+", "3", "×", "4", "−", "5", "equals"])
    XCTAssertEqual(chained.expression, "1 + 2 + 3 × 4 − 5 =")
    XCTAssertEqual(chained.value, 19)
    let grouped = calculate(["(", "(", "2", "+", "3", ")", ")", "×", "4", "equals"])
    XCTAssertEqual(grouped.expression, "((2 + 3)) × 4 =")
    XCTAssertEqual(grouped.value, 20)
  }

  func testLCDPhaseRestoration() {
    let name = "CalculatorSixLCDTests-" + UUID().uuidString
    let defaults = UserDefaults(suiteName: name)!
    defer { defaults.removePersistentDomain(forName: name) }
    let engine = calculate(["7", "×", "7"])
    let restored = CalculatorEngine()
    engine.save(to: defaults)
    restored.restore(from: defaults)
    XCTAssertFalse(restored.showingResult)
    XCTAssertEqual(restored.primaryDisplay(), "7 × 7")
    engine.press("equals")
    engine.save(to: defaults)
    restored.restore(from: defaults)
    XCTAssertTrue(restored.showingResult)
    XCTAssertEqual(restored.primaryDisplay(), "49")
    let sine = calculate(["3", "0", "sin"])
    sine.save(to: defaults)
    restored.restore(from: defaults)
    XCTAssertTrue(restored.showingResult)
    XCTAssertEqual(restored.primaryDisplay(), "0.5")
    restored.paste("12")
    XCTAssertFalse(restored.showingResult)
    XCTAssertEqual(restored.primaryDisplay(), "12")
  }
}
