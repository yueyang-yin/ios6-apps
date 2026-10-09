import SwiftUI
import UIKit

struct NotesRootView: View {
  let store: NotesStore
  @State private var selectedID: UUID?
  @State private var showingAccounts = false
  @State private var editing = false
  @State private var pageForward = true
  @State private var pendingDelete: UUID?
  @State private var showingSettings = false
  @State private var shareNote: Note?
  @State private var finishingShare = false
  @State private var exportRequest: NoteExportRequest?
  @State private var exportFailure: NoteExportFailure?
  @State private var printNote: Note?
  @State private var paperFrames: [String: CGRect] = [:]
  @State private var trashRequest: PaperTrashRequest?
  @State private var paperCaptured = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.scenePhase) private var scenePhase

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        if !showingSettings {
          VStack(spacing: 0) {
            if let id = selectedID, let note = store.note(id) {
              detail(note)
            } else if showingAccounts {
              AccountsView(
                count: store.notes.count, select: { navigate { showingAccounts = false } },
                back: { navigate { showingAccounts = false } },
                settings: { navigate { showingSettings = true } })
            } else {
              NotesListView(
                store: store, open: { id in navigate { selectedID = id } }, create: create,
                accounts: { navigate { showingAccounts = true } }, delete: requestDelete)
            }
          }
          .transition(.move(edge: .leading))
          .zIndex(0)
        }

        if showingSettings {
          NotesSettingsView(store: store) { navigate { showingSettings = false } }
            .transition(.move(edge: .trailing))
            .zIndex(1)
        }
      }
      .frame(height: geometry.size.height)
      .clipped()
      .background {
        Group {
          if showingAccounts {
            PinstripeBackground()
          } else {
            PaperBackground(
              ruled: true, rowHeight: selectedID == nil ? 53 : 28,
              margin: selectedID != nil, ruleOffset: selectedID == nil ? 44 : 0)
          }
        }
        .ignoresSafeArea(.container)
      }
    }
    .coordinateSpace(name: "notebook")
    .onPreferenceChange(PaperFramePreference.self) { frames in
      if trashRequest != nil, frames["page"] != paperFrames["page"] { finishDeletion() }
      paperFrames = frames
    }
    .background {
      NoteExportPresenter(request: exportRequest) { failure in
        exportRequest = nil
        exportFailure = failure
      }
      .frame(width: 0, height: 0)
      .accessibilityHidden(true)
    }
    .allowsHitTesting(
      trashRequest == nil && shareNote == nil && !finishingShare && exportRequest == nil
        && exportFailure == nil
    )
    .accessibilityHidden(
      pendingDelete != nil || trashRequest != nil || shareNote != nil || finishingShare
        || exportRequest != nil || exportFailure != nil
    )
    .overlay {
      ClassicShareOverlay(
        presented: shareNote != nil, cancel: { dismissShare() },
        select: exportNote)
    }
    .overlay {
      if let failure = exportFailure {
        ClassicExportNotice(failure: failure) { exportFailure = nil }
      }
    }
    .overlay {
      ZStack {
        if let id = pendingDelete {
          ClassicDeleteConfirmation(
            cancel: { navigate { pendingDelete = nil } },
            delete: { delete(id) }
          )
          .transition(.opacity)
        }
      }
      .allowsHitTesting(pendingDelete != nil)
    }
    .overlay {
      if let request = trashRequest {
        PaperTrashAnimation(
          request: request, previewProgress: trashPreviewProgress,
          captured: {
            if trashRequest?.id == request.id { paperCaptured = true }
          }, completion: finishDeletion
        )
        .id(request.id)
      }
    }
    .fullScreenCover(item: $printNote) { note in
      ClassicPrintView(note: note) { printNote = nil }
    }
    .overlay(alignment: .top) {
      if let error = store.storageError {
        VStack(spacing: 6) {
          Text(L10n.text("Unable to Save Notes")).font(.headline)
          Text(error).font(.footnote)
          if store.canWrite {
            Button(L10n.text("Retry")) { store.persist() }
              .accessibilityIdentifier("retry-save")
          }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .foregroundStyle(.black)
      }
    }
    .onChange(of: scenePhase) { _, phase in
      if phase != .active {
        shareNote = nil
        finishDeletion()
        store.persist()
      }
    }
    .onChange(of: reduceMotion) { _, enabled in
      if enabled { finishDeletion() }
    }
  }

  private func detail(_ note: Note) -> some View {
    let ids = store.sortedNotes.map(\.id)
    let index = ids.firstIndex(of: note.id) ?? 0
    return NoteDetailView(
      store: store, note: note, editing: $editing, pageForward: pageForward, back: back,
      create: create,
      previous: index > 0 ? { turnPage(ids[index - 1], forward: false) } : nil,
      next: index + 1 < ids.count ? { turnPage(ids[index + 1], forward: true) } : nil,
      share: { navigate { shareNote = note } }, delete: { requestDelete(note.id) },
      paperHidden: paperCaptured, trashOpen: trashRequest != nil)
  }

  private func create() {
    if let old = selectedID { store.discardEmpty(old) }
    guard let id = store.create() else { return }
    navigate {
      selectedID = id
      showingAccounts = false
      editing = true
    }
  }

  private func exportNote(_ action: NoteShareAction) {
    guard let note = shareNote, !finishingShare else { return }
    if action == .copy {
      UIPasteboard.general.setItems(
        [["public.utf8-plain-text": note.text]], options: [.localOnly: true])
      dismissShare()
      return
    }
    dismissShare {
      guard scenePhase == .active else { return }
      if action == .print {
        printNote = note
      } else {
        exportRequest = NoteExportRequest(note: note, action: action)
      }
    }
  }

  private func dismissShare(completion: @escaping () -> Void = {}) {
    guard shareNote != nil, !finishingShare else { return }
    finishingShare = true
    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2), completionCriteria: .removed) {
      shareNote = nil
    } completion: {
      finishingShare = false
      completion()
    }
  }

  private func back() {
    editing = false
    if let id = selectedID { store.discardEmpty(id) }
    navigate { selectedID = nil }
  }

  private func turnPage(_ id: UUID, forward: Bool) {
    editing = false
    pageForward = forward
    navigate { selectedID = id }
  }

  private func requestDelete(_ id: UUID) {
    editing = false
    navigate { pendingDelete = id }
  }

  private func delete(_ id: UUID) {
    guard trashRequest == nil else { return }
    pendingDelete = nil
    let arguments = ProcessInfo.processInfo.arguments
    let testReduceMotion =
      arguments.contains("--uitesting") && arguments.contains("--reduce-motion")
    if selectedID == id, !reduceMotion, !testReduceMotion,
      let page = paperFrames["page"], let trash = paperFrames["trash"],
      page.width > 0, page.height > 0
    {
      trashRequest = PaperTrashRequest(
        noteID: id, page: page, target: CGPoint(x: trash.midX, y: trash.midY))
    } else {
      completeDeletion(id)
    }
  }

  private var trashPreviewProgress: Double? {
    let arguments = ProcessInfo.processInfo.arguments
    guard arguments.contains("--uitesting"),
      let flag = arguments.first(where: { $0.hasPrefix("--trash-preview=") }),
      let value = Double(flag.dropFirst("--trash-preview=".count))
    else { return nil }
    return min(max(value, 0), 0.95)
  }

  private func finishDeletion() {
    guard let request = trashRequest else { return }
    trashRequest = nil
    paperCaptured = false
    completeDeletion(request.noteID)
  }

  private func completeDeletion(_ id: UUID) {
    let ids = store.sortedNotes.map(\.id)
    let index = ids.firstIndex(of: id) ?? 0
    store.delete(id)
    navigate {
      pendingDelete = nil
      if selectedID == id {
        let remaining = store.sortedNotes
        selectedID = remaining.isEmpty ? nil : remaining[min(index, remaining.count - 1)].id
      }
    }
  }

  private func navigate(_ action: () -> Void) {
    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2), action)
  }
}

private struct ClassicDeleteConfirmation: View {
  let cancel: () -> Void
  let delete: () -> Void

  var body: some View {
    ZStack(alignment: .bottom) {
      Color.black.opacity(0.35)
        .ignoresSafeArea()
        .onTapGesture(perform: cancel)
        .accessibilityHidden(true)
      VStack(spacing: 12) {
        Text(L10n.text("Delete this note?"))
          .font(.custom("HelveticaNeue-Bold", size: 16))
        Text(L10n.text("This note will be permanently deleted from this iPhone."))
          .font(.custom("HelveticaNeue", size: 13))
          .multilineTextAlignment(.center)
        actionButton("Delete Note", identifier: "confirm-delete", destructive: true, action: delete)
        actionButton("Cancel", identifier: "cancel-delete", destructive: false, action: cancel)
      }
      .foregroundStyle(.white)
      .shadow(color: .black, radius: 0.5, y: -1)
      .padding(.horizontal, 16)
      .padding(.top, 20)
      .padding(.bottom, 28)
      .background {
        LinearGradient(
          colors: [Color(white: 0.45), Color(white: 0.18)], startPoint: .top, endPoint: .bottom
        )
        .overlay(alignment: .top) { Color.white.opacity(0.4).frame(height: 1) }
      }
      .accessibilityAddTraits(.isModal)
      .accessibilityElement(children: .contain)
    }
  }

  private func actionButton(
    _ title: String, identifier: String, destructive: Bool, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Text(L10n.text(title))
        .font(.custom("HelveticaNeue-Bold", size: 20))
        .foregroundStyle(destructive ? .white : .black)
        .shadow(
          color: destructive ? .black.opacity(0.7) : .white, radius: 0, y: destructive ? -1 : 1
        )
        .frame(maxWidth: .infinity)
        .frame(height: 47)
        .background {
          RoundedRectangle(cornerRadius: 8)
            .fill(
              LinearGradient(
                stops: [
                  .init(
                    color: destructive ? Color(red: 0.95, green: 0.44, blue: 0.44) : .white,
                    location: 0),
                  .init(
                    color: destructive
                      ? Color(red: 0.80, green: 0.12, blue: 0.14) : Color(white: 0.9), location: 0.5
                  ),
                  .init(
                    color: destructive
                      ? Color(red: 0.67, green: 0.02, blue: 0.03) : Color(white: 0.75),
                    location: 0.51),
                  .init(
                    color: destructive
                      ? Color(red: 0.80, green: 0.06, blue: 0.07) : Color(white: 0.85), location: 1),
                ], startPoint: .top, endPoint: .bottom)
            )
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black.opacity(0.8), lineWidth: 1))
        }
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier(identifier)
  }
}
