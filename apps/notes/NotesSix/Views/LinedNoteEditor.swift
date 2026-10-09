import SwiftUI
import UIKit

struct LinedNoteEditor: UIViewRepresentable {
  @Binding var text: String
  @Binding var editing: Bool
  let noteID: UUID
  let font: NoteFont
  var enabled = true
  var pageForward = true
  var reduceMotion = false

  func makeUIView(context: Context) -> PaperTextView {
    let view = PaperTextView()
    view.delegate = context.coordinator
    view.backgroundColor = .clear
    view.alwaysBounceVertical = true
    view.contentInsetAdjustmentBehavior = .never
    view.textContainer.lineFragmentPadding = 0
    view.textContainerInset = UIEdgeInsets(top: 0, left: 33, bottom: 28, right: 14)
    view.keyboardAppearance = .light
    view.tintColor = UIColor(ClassicTheme.ink)
    view.accessibilityLabel = L10n.text("Note text")
    view.accessibilityIdentifier = "note-editor"
    view.text = text
    configure(view)
    return view
  }

  func updateUIView(_ view: PaperTextView, context: Context) {
    context.coordinator.parent = self
    if context.coordinator.noteID != noteID {
      context.coordinator.noteID = noteID
      let changePage = {
        view.text = text
        view.appliedFont = nil
        configure(view)
        view.selectedRange = NSRange(location: 0, length: 0)
        view.setContentOffset(.zero, animated: false)
        view.layoutIfNeeded()
      }
      if reduceMotion {
        changePage()
      } else {
        UIView.transition(
          with: view, duration: 0.35,
          options: [pageForward ? .transitionCurlUp : .transitionCurlDown, .beginFromCurrentState],
          animations: changePage)
      }
    } else if view.text != text {
      let selection = view.selectedRange
      view.text = text
      view.selectedRange = NSRange(
        location: min(selection.location, (text as NSString).length), length: 0)
    }
    // Reapplying attributes during marked-text composition can disrupt Chinese input.
    if view.markedTextRange == nil { configure(view) }
    view.isEditable = enabled
    if editing && !view.isFirstResponder {
      DispatchQueue.main.async { [weak view] in
        guard context.coordinator.parent.editing else { return }
        view?.becomeFirstResponder()
      }
    } else if !editing && view.isFirstResponder {
      view.resignFirstResponder()
    }
  }

  private func configure(_ view: PaperTextView) {
    let uiFont = ClassicTheme.noteUIFont(font)
    let lineHeight = max(28, ceil(uiFont.lineHeight + 3))
    guard view.appliedFont != uiFont || view.paper.lineHeight != lineHeight else { return }
    view.appliedFont = uiFont
    view.paper.lineHeight = lineHeight
    let paragraph = NSMutableParagraphStyle()
    paragraph.minimumLineHeight = lineHeight
    paragraph.maximumLineHeight = lineHeight
    let attributes: [NSAttributedString.Key: Any] = [
      .font: uiFont,
      .foregroundColor: UIColor(red: 0.10, green: 0.08, blue: 0.04, alpha: 1),
      .paragraphStyle: paragraph,
    ]
    let selection = view.selectedRange
    view.textStorage.addAttributes(
      attributes, range: NSRange(location: 0, length: view.textStorage.length))
    view.typingAttributes = attributes
    view.selectedRange = selection
    view.paper.setNeedsDisplay()
  }

  func makeCoordinator() -> Coordinator { Coordinator(self) }

  final class Coordinator: NSObject, UITextViewDelegate {
    var parent: LinedNoteEditor
    var noteID: UUID
    init(_ parent: LinedNoteEditor) {
      self.parent = parent
      noteID = parent.noteID
    }

    func textViewDidChange(_ textView: UITextView) {
      parent.text = textView.text
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
      if !parent.editing { parent.editing = true }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
      if parent.editing { parent.editing = false }
    }
  }
}

final class PaperTextView: UITextView {
  let paper = RuledPaperView()
  var appliedFont: UIFont?

  override init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
    paper.isUserInteractionEnabled = false
    paper.accessibilityElementsHidden = true
    insertSubview(paper, at: 0)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func layoutSubviews() {
    super.layoutSubviews()
    paper.frame = CGRect(
      x: 0, y: -max(0, bounds.height), width: bounds.width,
      height: max(contentSize.height, bounds.height) + max(0, bounds.height) * 2)
    paper.originOffset = max(0, bounds.height)
    paper.setNeedsDisplay()
    sendSubviewToBack(paper)
  }
}

final class RuledPaperView: UIView {
  var lineHeight: CGFloat = 28
  var originOffset: CGFloat = 0

  override func draw(_ rect: CGRect) {
    guard let context = UIGraphicsGetCurrentContext() else { return }
    UIColor(red: 1, green: 0.98, blue: 0.73, alpha: 1).setFill()
    context.fill(rect)
    for index in 0..<2400 {
      let x = CGFloat((index * 73 + 19) % 997) / 997 * bounds.width
      let y = CGFloat((index * 131 + 31) % 991) / 991 * bounds.height
      context.setFillColor(UIColor.brown.withAlphaComponent(0.035).cgColor)
      context.fill(CGRect(x: x, y: y, width: 0.7, height: 0.5))
    }
    context.setStrokeColor(UIColor(red: 0.64, green: 0.62, blue: 0.40, alpha: 0.55).cgColor)
    context.setLineWidth(0.5)
    let firstY = originOffset.truncatingRemainder(dividingBy: lineHeight) + lineHeight - 0.5
    for y in stride(from: firstY, through: bounds.height, by: lineHeight) {
      context.move(to: CGPoint(x: 0, y: y))
      context.addLine(to: CGPoint(x: bounds.width, y: y))
    }
    context.strokePath()
    context.setStrokeColor(UIColor.brown.withAlphaComponent(0.22).cgColor)
    for x in [CGFloat(23), CGFloat(26)] {
      context.move(to: CGPoint(x: x, y: 0))
      context.addLine(to: CGPoint(x: x, y: bounds.height))
    }
    context.strokePath()
  }
}
