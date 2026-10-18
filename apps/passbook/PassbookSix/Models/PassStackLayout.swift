import Foundation

struct PassStackLayout {
  let count: Int
  let headerHeight: CGFloat
  let stackHeight: CGFloat
  let fullCardHeight: CGFloat
  let contentHeight: CGFloat
  let step: CGFloat
  let reveal: CGFloat

  init(
    count: Int, availableHeight: CGFloat, headerHeight: CGFloat = 60,
    minimumCardHeight: CGFloat = 520, pullDistance: CGFloat = 0
  ) {
    self.count = max(0, count)
    self.headerHeight = max(44, headerHeight)
    stackHeight = max(availableHeight, CGFloat(max(1, count)) * self.headerHeight)
    step = count > 1 ? (stackHeight - self.headerHeight) / CGFloat(count - 1) : 0
    fullCardHeight = max(availableHeight, minimumCardHeight, self.headerHeight)
    contentHeight = stackHeight
    let maximumReveal = count > 1 ? max(0, availableHeight - self.headerHeight) : 0
    reveal = min(max(0, pullDistance), maximumReveal)
  }
  func top(at index: Int) -> CGFloat {
    let fraction = count > 1 ? CGFloat(index) / CGFloat(count - 1) : 0
    return CGFloat(index) * step - reveal * fraction
  }
  func cardHeight(at index: Int) -> CGFloat { fullCardHeight }
  func exposedHeight(at index: Int) -> CGFloat {
    if count == 1 { return stackHeight }
    return index == count - 1 ? headerHeight + reveal : step - reveal / CGFloat(count - 1)
  }
}
