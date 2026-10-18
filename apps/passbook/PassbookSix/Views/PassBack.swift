import PassKit
import SwiftUI

struct PassBack: View {
  var pass: PocketPass
  var sourceURL: URL?
  var onDone: () -> Void
  var onDelete: () -> Void
  var onMove: (Int) -> Void
  var saveNote: (String) -> Void
  @State private var note: String
  @State private var walletPass: PKPass?
  @State private var showWallet = false
  init(
    pass: PocketPass, sourceURL: URL?, onDone: @escaping () -> Void, onDelete: @escaping () -> Void,
    onMove: @escaping (Int) -> Void, saveNote: @escaping (String) -> Void
  ) {
    self.pass = pass
    self.sourceURL = sourceURL
    self.onDone = onDone
    self.onDelete = onDelete
    self.onMove = onMove
    self.saveNote = saveNote
    _note = State(initialValue: pass.userNote)
  }
  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Button(action: onDelete) {
          Image(systemName: "trash.fill").font(.system(size: 19)).frame(width: 44, height: 44)
        }.buttonStyle(ClassicButton()).accessibilityLabel(L10n.text("Delete Pass"))
          .accessibilityIdentifier("delete-pass")
        Spacer()
        Text(L10n.text("Information")).font(PassTheme.font(18, bold: true))
        Spacer()
        Button(L10n.text("Done"), action: onDone).buttonStyle(ClassicButton())
          .accessibilityIdentifier("flip-done")
      }.padding(10)
      VStack(alignment: .leading, spacing: 16) {
        Text(pass.organization).font(PassTheme.font(20, bold: true))
        Text(pass.display(pass.title)).font(PassTheme.font(16)).foregroundStyle(.white.opacity(0.8))
        ForEach(pass.back) { field in
          VStack(alignment: .leading, spacing: 6) {
            Text(pass.displayLabel(field.label)).font(PassTheme.font(13, bold: true))
              .foregroundStyle(.white.opacity(0.6))
            Text(pass.display(field.value)).font(PassTheme.font(15)).textSelection(.enabled)
              .fixedSize(horizontal: false, vertical: true)
          }
          Divider().overlay(.white.opacity(0.1))
        }
        if let expiration = pass.expirationDate {
          Text(
            L10n.text("Expires") + ": "
              + expiration.formatted(
                .dateTime.year().month().day().locale(AppLanguage.current.locale))
          )
          .font(PassTheme.font(14))
        }
        Text(L10n.text("Notes")).font(PassTheme.font(13, bold: true)).foregroundStyle(
          .white.opacity(0.6))
        TextEditor(text: $note).scrollContentBackground(.hidden).frame(height: 90)
          .padding(6).background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 5))
          .accessibilityLabel(L10n.text("Notes"))
          .onChange(of: note) { saveNote(note) }
        HStack {
          Button(L10n.text("Move Up")) { onMove(-1) }.buttonStyle(ClassicButton())
          Spacer()
          Button(L10n.text("Move Down")) { onMove(1) }.buttonStyle(ClassicButton())
        }
        HStack {
          if let sourceURL {
            ShareLink(item: sourceURL) {
              Label(L10n.text("Share Pass"), systemImage: "square.and.arrow.up")
            }
            .buttonStyle(ClassicButton())
          } else {
            ShareLink(item: pass.shareText) {
              Label(L10n.text("Share Pass"), systemImage: "square.and.arrow.up")
            }
            .buttonStyle(ClassicButton())
          }
        }
        if sourceURL != nil {
          if walletPass != nil, PKAddPassesViewController.canAddPasses() {
            Button(L10n.text("Add to Apple Wallet")) { showWallet = true }
              .buttonStyle(ClassicButton(color: Color(passHex: "3265A5")))
          }
          Text(L10n.text("Wallet integration explanation")).font(PassTheme.font(12))
            .foregroundStyle(.white.opacity(0.6))
        } else if !pass.isDemo {
          Text(L10n.text("Local pass explanation")).font(PassTheme.font(12)).foregroundStyle(
            .white.opacity(0.6))
        }
      }.padding(.horizontal, 18).padding(.bottom, 24)
    }.foregroundStyle(.white)
      .background {
        LinearGradient(
          colors: [Color(passHex: "535759"), Color(passHex: "373B3D")],
          startPoint: .top, endPoint: .bottom)
      }
      .clipShape(RoundedRectangle(cornerRadius: 7))
      .overlay(RoundedRectangle(cornerRadius: 7).stroke(.white.opacity(0.18), lineWidth: 1))
      .shadow(color: .black.opacity(0.7), radius: 4, y: 2)
      .task(id: sourceURL) {
        if let sourceURL, let data = try? Data(contentsOf: sourceURL) {
          walletPass = try? PKPass(data: data)
        }
      }
      .sheet(isPresented: $showWallet) {
        if let walletPass { WalletAddView(pass: walletPass) }
      }
  }
}

private struct WalletAddView: UIViewControllerRepresentable {
  var pass: PKPass
  @Environment(\.dismiss) private var dismiss
  func makeCoordinator() -> Coordinator { Coordinator { dismiss() } }
  func makeUIViewController(context: Context) -> UIViewController {
    guard let controller = PKAddPassesViewController(pass: pass) else { return UIViewController() }
    controller.delegate = context.coordinator
    return controller
  }
  func updateUIViewController(_ controller: UIViewController, context: Context) {}
  final class Coordinator: NSObject, PKAddPassesViewControllerDelegate {
    let done: () -> Void
    init(done: @escaping () -> Void) { self.done = done }
    func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) { done() }
  }
}
