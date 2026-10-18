import SwiftUI

struct PassStackView: View {
  var passes: [PocketPass]
  var namespace: Namespace.ID
  var select: (String) -> Void
  @ScaledMetric(relativeTo: .body) private var headerHeight: CGFloat = 60
  @ScaledMetric(relativeTo: .body) private var minimumCardHeight: CGFloat = 520
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var scrollOrigin: CGFloat = 0
  @State private var suppressSelection = false
  @State private var selectionReset: Task<Void, Never>?
  @GestureState(
    resetTransaction: Transaction(animation: .spring(response: 0.36, dampingFraction: 0.84))
  ) private var pull = StackPullState()

  var body: some View {
    GeometryReader { geometry in
      let layout = PassStackLayout(
        count: passes.count,
        availableHeight: max(0, geometry.size.height - 14), headerHeight: headerHeight,
        minimumCardHeight: minimumCardHeight, pullDistance: pull.distance)
      ScrollView {
        ZStack(alignment: .top) {
          ForEach(Array(passes.enumerated()), id: \.element.id) { index, pass in
            ZStack(alignment: .top) {
              PassCard(pass: pass, minimumHeight: layout.cardHeight(at: index))
                .matchedGeometryEffect(id: pass.id, in: namespace)
                .frame(height: layout.cardHeight(at: index), alignment: .top)
                .clipped().allowsHitTesting(false).accessibilityHidden(true)
              // Only exposed paper is interactive; covered card centers must not steal taps.
              Button {
                guard !suppressSelection && !pull.active else { return }
                select(pass.id)
              } label: {
                Color.clear.frame(height: layout.exposedHeight(at: index))
                  .contentShape(Rectangle())
              }.buttonStyle(.plain)
                .disabled(suppressSelection)
                .accessibilityLabel(pass.organization + ", " + pass.display(pass.title))
                .accessibilityHint(L10n.text("Open this pass"))
                .accessibilityIdentifier("pass-\(pass.id)")
            }.frame(height: layout.cardHeight(at: index), alignment: .top)
              .offset(y: layout.top(at: index)).zIndex(Double(index))
          }
        }.frame(height: layout.contentHeight, alignment: .top)
          .background {
            GeometryReader { content in
              Color.clear.preference(
                key: StackScrollOrigin.self,
                value: content.frame(in: .named("pass-stack-scroll")).minY)
            }
          }
          .padding(.horizontal, 10).padding(.top, 8).padding(.bottom, 6)
      }
      .coordinateSpace(name: "pass-stack-scroll")
      .onPreferenceChange(StackScrollOrigin.self) { scrollOrigin = $0 }
      .scrollBounceBehavior(.basedOnSize)
      .simultaneousGesture(
        DragGesture(minimumDistance: 8)
          .updating($pull) { value, state, transaction in
            transaction.animation = nil
            state.active = true
            if state.remainingScroll == nil {
              state.remainingScroll = max(
                0, layout.contentHeight - geometry.size.height + scrollOrigin + 6)
            }
            state.distance = max(0, -value.translation.height - (state.remainingScroll ?? 0))
          }
      )
      .onChange(of: pull.active) { _, active in
        selectionReset?.cancel()
        if active {
          suppressSelection = true
        } else {
          selectionReset = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            suppressSelection = false
          }
        }
      }
      .onDisappear { selectionReset?.cancel() }
      .transaction { transaction in
        if reduceMotion || ProcessInfo.processInfo.arguments.contains("--reduce-motion") {
          transaction.animation = nil
        }
      }
      .scrollIndicators(.hidden).accessibilityIdentifier("pass-stack")
    }
  }
}

private struct StackPullState {
  var active = false
  var remainingScroll: CGFloat?
  var distance: CGFloat = 0
}

private struct StackScrollOrigin: PreferenceKey {
  static var defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
