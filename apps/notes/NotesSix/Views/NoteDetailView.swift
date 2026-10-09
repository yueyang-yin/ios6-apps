import SwiftUI

struct NoteDetailView: View {
  let store: NotesStore
  let note: Note
  @Binding var editing: Bool
  var pageForward = true
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let back: () -> Void
  let create: () -> Void
  let previous: (() -> Void)?
  let next: (() -> Void)?
  let share: () -> Void
  let delete: () -> Void
  var paperHidden = false
  var trashOpen = false

  var body: some View {
    VStack(spacing: 0) {
      ClassicNavigationBar(title: note.title) {
        Button(L10n.text("Notes"), action: back)
          .buttonStyle(LeatherButtonStyle(back: true))
          .accessibilityIdentifier("back-to-notes")
      } trailing: {
        if editing {
          Button(L10n.text("Done")) { editing = false }
            .buttonStyle(LeatherButtonStyle())
            .accessibilityIdentifier("done-editing")
        } else {
          Button(action: create) {
            Image(systemName: "plus").font(.system(size: 21, weight: .bold))
          }
          .buttonStyle(LeatherButtonStyle())
          .accessibilityLabel(L10n.text("New Note"))
          .accessibilityIdentifier("new-note")
          .disabled(!store.canWrite)
        }
      }
      ZStack(alignment: .top) {
        PaperBackground(margin: true)
        VStack(spacing: 0) {
          TornPaperEdge()
          HStack(spacing: 8) {
            Text(AppLanguage.current.relativeDate(note.modifiedAt))
              .font(.custom("HelveticaNeue-Bold", size: 12))
            Spacer(minLength: 4)
            Text(AppLanguage.current.timestamp(note.modifiedAt))
              .font(.custom("HelveticaNeue", size: 12))
              .lineLimit(1)
          }
          .foregroundStyle(Color(red: 0.54, green: 0.25, blue: 0.13))
          .padding(.leading, 33)
          .padding(.trailing, 13)
          .frame(height: 24)
          .accessibilityIdentifier("note-date")
          LinedNoteEditor(
            text: Binding(
              get: { store.note(note.id)?.text ?? "" }, set: { store.update(note.id, text: $0) }),
            editing: $editing, noteID: note.id, font: store.font, enabled: store.canWrite,
            pageForward: pageForward, reduceMotion: reduceMotion
          )
        }
      }
      .opacity(paperHidden ? 0 : 1)
      .background(PaperBackground(ruled: true, margin: true, ruleOffset: 3))
      .background {
        GeometryReader { geometry in
          Color.clear.preference(
            key: PaperFramePreference.self,
            value: ["page": geometry.frame(in: .named("notebook"))])
        }
      }
      if !editing {
        HStack(spacing: 0) {
          ClassicToolbarButton(
            symbol: "arrow.left.circle", label: "Previous Note", identifier: "previous-note",
            enabled: previous != nil, action: { previous?() })
          ClassicToolbarButton(
            symbol: "square.and.arrow.up", label: "Share Note", identifier: "share-note",
            enabled: !note.isEmpty, action: share)
          ClassicToolbarButton(
            symbol: "trash", label: "Delete Note", identifier: "delete-note",
            enabled: store.canWrite, action: delete, trashOpen: trashOpen
          )
          .background {
            GeometryReader { geometry in
              Color.clear.preference(
                key: PaperFramePreference.self,
                value: ["trash": geometry.frame(in: .named("notebook"))])
            }
          }
          ClassicToolbarButton(
            symbol: "arrow.right.circle", label: "Next Note", identifier: "next-note",
            enabled: next != nil, action: { next?() })
        }
        .background(PaperBackground(margin: true))
        .overlay(alignment: .top) { ClassicTheme.rule.opacity(0.2).frame(height: 0.5) }
      }
    }
  }
}
