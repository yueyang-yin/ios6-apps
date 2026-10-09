import UIKit

@MainActor
enum NotePrintDocument {
  static func pdf(text: String) -> Data {
    let renderer = NotePageRenderer()
    let formatter = UISimpleTextPrintFormatter(text: text)
    formatter.font = .systemFont(ofSize: 16)
    formatter.color = .black
    renderer.addPrintFormatter(formatter, startingAtPageAt: 0)
    let count = max(renderer.numberOfPages, 1)
    renderer.prepare(forDrawingPages: NSRange(location: 0, length: count))
    return UIGraphicsPDFRenderer(bounds: renderer.paperRect).pdfData { context in
      for index in 0..<count {
        context.beginPage()
        renderer.drawPage(at: index, in: renderer.printableRect)
      }
    }
  }
}

private final class NotePageRenderer: UIPrintPageRenderer {
  override var paperRect: CGRect { CGRect(x: 0, y: 0, width: 595.2, height: 841.8) }
  override var printableRect: CGRect { paperRect.insetBy(dx: 36, dy: 36) }
}
