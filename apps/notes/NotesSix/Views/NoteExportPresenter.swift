import MessageUI
import SwiftUI
import UIKit

struct NoteExportRequest: Identifiable {
  let id = UUID()
  let note: Note
  let action: NoteShareAction
  var printer: UIPrinter? = nil
  var copies = 1
}

enum NoteExportFailure {
  case mailUnavailable
  case mailFailed
  case printUnavailable
  case printFailed

  var title: String {
    switch self {
    case .mailUnavailable: "Mail Not Available"
    case .mailFailed: "Unable to Send Mail"
    case .printUnavailable, .printFailed: "Unable to Print"
    }
  }

  var message: String {
    switch self {
    case .mailUnavailable:
      "Set up a Mail account on this iPhone to email a note. You can also copy the note."
    case .mailFailed: "The email could not be prepared. Please try again."
    case .printUnavailable: "Printing is not available on this iPhone. You can still copy the note."
    case .printFailed: "The note could not be printed. Please check your printer and try again."
    }
  }
}

struct NoteExportPresenter: UIViewControllerRepresentable {
  let request: NoteExportRequest?
  let finished: (NoteExportFailure?) -> Void

  func makeUIViewController(context: Context) -> NoteExportController {
    NoteExportController()
  }

  func updateUIViewController(_ controller: NoteExportController, context: Context) {
    controller.finished = finished
    controller.request = request
    controller.presentPendingRequest()
  }

  static func dismantleUIViewController(_ controller: NoteExportController, coordinator: ()) {
    controller.finished = nil
    controller.dismiss(animated: false)
    controller.cancelPrint()
  }
}

final class NoteExportController: UIViewController, MFMailComposeViewControllerDelegate,
  UIAdaptivePresentationControllerDelegate
{
  var request: NoteExportRequest?
  var finished: ((NoteExportFailure?) -> Void)?
  private var handledID: UUID?
  private var completed = false
  private var printer: UIPrintInteractionController?

  override func loadView() {
    view = UIView()
    view.backgroundColor = .clear
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    presentPendingRequest()
  }

  func presentPendingRequest() {
    guard let request, request.id != handledID, viewIfLoaded?.window != nil else { return }
    handledID = request.id
    completed = false
    // Present after SwiftUI finishes updating the host's view hierarchy.
    DispatchQueue.main.async { [weak self] in
      guard let self, self.request?.id == request.id else { return }
      switch request.action {
      case .mail: self.compose(request.note)
      case .print: self.printNote(request)
      case .copy: self.complete(nil)
      }
    }
  }

  private func compose(_ note: Note) {
    guard MFMailComposeViewController.canSendMail() else {
      complete(.mailUnavailable)
      return
    }
    let mail = MFMailComposeViewController()
    mail.mailComposeDelegate = self
    mail.setSubject(note.title)
    mail.setMessageBody(note.text, isHTML: false)
    mail.overrideUserInterfaceStyle = .light
    present(mail, animated: true) {
      mail.presentationController?.delegate = self
    }
  }

  private func printNote(_ request: NoteExportRequest) {
    guard UIPrintInteractionController.isPrintingAvailable, let destination = request.printer else {
      complete(.printUnavailable)
      return
    }
    let controller = UIPrintInteractionController.shared
    let info = UIPrintInfo.printInfo()
    info.outputType = .general
    info.jobName = request.note.title
    controller.printInfo = info
    let document = NotePrintDocument.pdf(text: request.note.text)
    controller.printingItems = Array(repeating: document, count: min(max(request.copies, 1), 99))
    printer = controller
    if !controller.print(
      to: destination,
      completionHandler: { [weak self] _, _, error in
        self?.complete(error == nil ? nil : .printFailed)
      })
    {
      complete(.printUnavailable)
    }
  }

  func mailComposeController(
    _ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult,
    error: Error?
  ) {
    controller.dismiss(animated: true) { [weak self] in
      self?.complete(error != nil || result == .failed ? .mailFailed : nil)
    }
  }

  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    complete(nil)
  }

  func cancelPrint() {
    printer?.dismiss(animated: false)
    printer?.printingItems = nil
    printer = nil
  }

  private func complete(_ failure: NoteExportFailure?) {
    guard !completed else { return }
    completed = true
    printer?.printingItems = nil
    printer = nil
    finished?(failure)
  }
}
