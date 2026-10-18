import SwiftUI
import UniformTypeIdentifiers

struct PassbookRootView: View {
  @Bindable var store: PassStore
  @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
  @Namespace private var cards
  @State private var selectedID: String?
  @State private var flipped = false
  @State private var showCatalog = false
  @State private var showEditor = false
  @State private var showImporter = false
  @State private var showAbout = false
  @State private var confirmDelete = false
  @State private var shredding: PocketPass?
  @State private var shredProgress = false
  @State private var transitioning = false

  private var selected: PocketPass? { selectedID.flatMap { store.pass($0) } }
  private var reduceMotion: Bool {
    systemReduceMotion || ProcessInfo.processInfo.arguments.contains("--reduce-motion")
  }
  private var animation: Animation? {
    reduceMotion ? .easeOut(duration: 0.12) : .easeInOut(duration: 0.4)
  }

  var body: some View {
    ZStack {
      PocketBackground(subdued: !store.passes.isEmpty && !showCatalog && !showEditor)
      if showEditor {
        PassEditor(onClose: { showEditor = false }, onSave: add)
      } else if showCatalog {
        PassCatalog(
          onClose: { showCatalog = false }, onAdd: add,
          onImport: { showImporter = true }, onCreate: { showEditor = true },
          onSamples: {
            store.addSamples()
            showCatalog = false
          })
      } else {
        library
      }
      if let shredding {
        Group {
          if reduceMotion {
            PassCard(pass: shredding).opacity(shredProgress ? 0 : 1)
          } else {
            ShreddedPass(pass: shredding, progress: shredProgress)
          }
        }.frame(maxWidth: 420).padding(.horizontal, 12).padding(.top, 54)
      }
      if confirmDelete {
        ClassicPassAlert(
          title: L10n.text("Delete Pass"), message: L10n.text("Delete confirmation"),
          primary: "Delete", destructive: true, cancel: { confirmDelete = false }, action: delete)
      } else if store.errorMessage != nil {
        ClassicPassAlert(
          title: L10n.text("Passbook"), message: store.errorMessage ?? "", primary: "OK",
          action: { store.errorMessage = nil })
      } else if showAbout {
        ClassicPassAlert(
          title: L10n.text("Passbook"), message: L10n.text("About explanation"), primary: "Done",
          action: { showAbout = false })
      }
    }
    .environment(\.locale, AppLanguage.current.locale)
    .preferredColorScheme(.dark)
    .fileImporter(
      isPresented: $showImporter,
      allowedContentTypes: [UTType(filenameExtension: "pkpass") ?? .data]
    ) { result in
      switch result {
      case .success(let url):
        store.importPass(from: url)
        if store.errorMessage == nil { showCatalog = false }
      case .failure: store.errorMessage = L10n.text("Could not import pass")
      }
    }
    .onOpenURL { url in
      guard url.isFileURL else { return }
      store.importPass(from: url)
    }
    .accessibilityAction(.escape) {
      if confirmDelete {
        confirmDelete = false
      } else if showEditor {
        showEditor = false
      } else if showCatalog {
        showCatalog = false
      } else if flipped {
        flip(false)
      } else {
        closePass()
      }
    }
  }

  private var library: some View {
    VStack(spacing: 0) {
      if store.passes.isEmpty {
        WelcomeView { showCatalog = true }
      } else if let selected {
        HStack {
          Button(L10n.text("All Passes"), action: closePass).buttonStyle(ClassicButton())
          Spacer()
          Text(selected.isDemo ? L10n.text("DEMO PASS") : L10n.text(selected.kind.title))
            .font(PassTheme.font(12, bold: true)).foregroundStyle(.white.opacity(0.65)).lineLimit(1)
        }.padding(.horizontal, 12).frame(height: 48)
        ScrollViewReader { proxy in
          ScrollView {
            ZStack(alignment: .top) {
              PassCard(pass: selected, onInfo: { flip(true) })
                .matchedGeometryEffect(id: selected.id, in: cards)
                .modifier(CardFace(angle: reduceMotion ? 0 : flipped ? 180 : 0))
                .opacity(reduceMotion && flipped ? 0 : 1)
                .allowsHitTesting(!flipped).accessibilityHidden(flipped)
              PassBack(
                pass: selected, sourceURL: store.sourceURL(for: selected), onDone: { flip(false) },
                onDelete: { confirmDelete = true }, onMove: { store.move(selected.id, by: $0) },
                saveNote: { note in
                  var updated = selected
                  updated.userNote = note
                  store.save(updated)
                }
              )
              .modifier(CardFace(angle: reduceMotion ? 0 : flipped ? 0 : -180))
              .opacity(reduceMotion && !flipped ? 0 : 1)
              .allowsHitTesting(flipped).accessibilityHidden(!flipped)
            }.padding(.horizontal, 12).padding(.top, 4).padding(.bottom, 18)
              .frame(maxWidth: 460).frame(maxWidth: .infinity).id("pass-top")
          }.scrollIndicators(.hidden).scrollDismissesKeyboard(.interactively)
            .onChange(of: flipped) {
              withAnimation(animation) { proxy.scrollTo("pass-top", anchor: .top) }
            }
        }
        PassTray(pass: store.passes.last(where: { $0.id != selected.id }), action: closePass)
          .padding(.horizontal, 10).padding(.vertical, 8).frame(maxWidth: 460)
      } else {
        PassStackView(passes: store.passes, namespace: cards, select: openPass)
      }
      if selected == nil { toolbar }
    }.allowsHitTesting(
      shredding == nil && !confirmDelete && !showAbout && store.errorMessage == nil
    )
    .disabled(transitioning)
    .accessibilityHidden(confirmDelete || showAbout || store.errorMessage != nil)
  }

  private var toolbar: some View {
    HStack {
      Button {
        showAbout = true
      } label: {
        Image(systemName: "info.circle").font(.system(size: 21)).frame(width: 44, height: 44)
      }.accessibilityLabel(L10n.text("About Passbook"))
      Spacer()
      Text(
        store.passes.isEmpty ? L10n.text("Passbook") : L10n.format("%ld passes", store.passes.count)
      )
      .font(PassTheme.font(store.passes.isEmpty ? 20 : 12, bold: store.passes.isEmpty))
      .foregroundStyle(.white.opacity(0.5)).shadow(color: .black, radius: 0, y: -1)
      Spacer()
      Button {
        showCatalog = true
      } label: {
        Image(systemName: "plus").font(.system(size: 23, weight: .bold)).frame(
          width: 44, height: 44)
      }.accessibilityLabel(L10n.text("Add Passes")).accessibilityIdentifier("add-pass")
    }.buttonStyle(.plain).foregroundStyle(.white.opacity(0.7)).padding(.horizontal, 12).frame(
      height: 48)
  }

  private func add(_ pass: PocketPass) {
    guard store.save(pass) else { return }
    showEditor = false
    showCatalog = false
    openPass(pass.id)
  }
  private func openPass(_ id: String) {
    transition {
      selectedID = id
      flipped = false
    }
  }
  private func closePass() {
    transition {
      flipped = false
      selectedID = nil
    }
  }
  private func flip(_ value: Bool) {
    transition { flipped = value }
  }
  private func transition(_ change: () -> Void) {
    transitioning = true
    withAnimation(animation, change)
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(reduceMotion ? 140 : 440))
      transitioning = false
    }
  }
  private func delete() {
    confirmDelete = false
    guard let pass = selected, store.remove(pass.id) else { return }
    selectedID = nil
    flipped = false
    shredding = pass
    shredProgress = false
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(40))
      withAnimation(.easeIn(duration: reduceMotion ? 0.12 : 0.85)) { shredProgress = true }
      try? await Task.sleep(for: .milliseconds(reduceMotion ? 150 : 900))
      shredding = nil
      shredProgress = false
    }
  }
}

struct ClassicPassAlert: View {
  var title: String
  var message: String
  var primary: String
  var destructive = false
  var cancel: (() -> Void)?
  var action: () -> Void
  var body: some View {
    ZStack {
      Color.black.opacity(0.6).ignoresSafeArea()
      VStack(spacing: 15) {
        Text(title).font(PassTheme.font(21, bold: true))
        Text(message).font(PassTheme.font(15)).multilineTextAlignment(.center).lineSpacing(3)
        HStack {
          if let cancel {
            Button(L10n.text("Cancel"), action: cancel).buttonStyle(ClassicButton())
              .frame(maxWidth: .infinity)
          }
          Button(L10n.text(primary), action: action)
            .buttonStyle(ClassicButton(color: Color(passHex: destructive ? "9F3030" : "3D6187")))
            .frame(maxWidth: .infinity).accessibilityIdentifier("alert-primary")
        }
      }.foregroundStyle(.white).padding(22).frame(maxWidth: 310)
        .background {
          RoundedRectangle(cornerRadius: 12)
            .fill(
              LinearGradient(
                colors: [Color(passHex: "52637B"), Color(passHex: "27364E")],
                startPoint: .top, endPoint: .bottom)
            )
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.65), lineWidth: 2))
            .shadow(color: .black, radius: 15, y: 5)
        }
    }.accessibilityAddTraits(.isModal)
  }
}
