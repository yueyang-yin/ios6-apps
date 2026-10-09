import SwiftUI

struct NotesListView: View {
  let store: NotesStore
  let open: (UUID) -> Void
  let create: () -> Void
  let accounts: () -> Void
  let delete: (UUID) -> Void
  @State private var query = ""
  @FocusState private var searchFocused: Bool

  var body: some View {
    VStack(spacing: 0) {
      ClassicNavigationBar(title: L10n.text("Notes")) {
        Button(L10n.text("Accounts"), action: accounts)
          .buttonStyle(LeatherButtonStyle(back: true))
          .accessibilityIdentifier("accounts")
      } trailing: {
        Button(action: create) {
          Image(systemName: "plus").font(.system(size: 21, weight: .bold))
        }
        .buttonStyle(LeatherButtonStyle())
        .accessibilityLabel(L10n.text("New Note"))
        .accessibilityIdentifier("new-note")
        .disabled(!store.canWrite)
      }
      ZStack {
        PaperBackground(ruled: true, rowHeight: 53, ruleOffset: 44)
        ScrollView {
          LazyVStack(spacing: 0) {
            searchBar
            if store.matching(query).isEmpty {
              emptyState
            } else {
              ForEach(store.matching(query)) { note in
                NoteListRow(note: note, open: { open(note.id) }, delete: { delete(note.id) })
              }
            }
          }
        }
        .scrollDismissesKeyboard(.interactively)
        .accessibilityIdentifier("notes-list")
      }
      footer
    }
  }

  private var searchBar: some View {
    HStack(spacing: 8) {
      HStack(spacing: 7) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.gray)
        TextField(L10n.text("Search"), text: $query)
          .font(.custom("HelveticaNeue", size: 16))
          .foregroundStyle(.black)
          .focused($searchFocused)
          .autocorrectionDisabled()
          .textInputAutocapitalization(.never)
          .submitLabel(.search)
          .onSubmit { searchFocused = false }
          .accessibilityIdentifier("search-notes")
        if !query.isEmpty {
          Button {
            query = ""
          } label: {
            Image(systemName: "xmark.circle.fill").foregroundStyle(.gray)
          }
          .accessibilityLabel(L10n.text("Clear search"))
          .accessibilityIdentifier("clear-search")
        }
      }
      .padding(.horizontal, 10)
      .frame(height: 30)
      .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 15))
      .overlay(RoundedRectangle(cornerRadius: 15).stroke(.brown.opacity(0.35), lineWidth: 0.7))
      .shadow(color: .black.opacity(0.10), radius: 1, y: -1)
      if searchFocused {
        Button(L10n.text("Cancel")) {
          query = ""
          searchFocused = false
        }
        .font(.custom("HelveticaNeue-Bold", size: 14))
        .foregroundStyle(ClassicTheme.ink)
        .accessibilityIdentifier("cancel-search")
      }
    }
    .padding(.horizontal, 10)
    .frame(height: 44)
    .background {
      LinearGradient(
        colors: [Color(red: 0.86, green: 0.84, blue: 0.66), ClassicTheme.paper],
        startPoint: .top, endPoint: .bottom)
    }
    .overlay(alignment: .bottom) { ClassicTheme.rule.opacity(0.6).frame(height: 0.5) }
  }

  private var emptyState: some View {
    VStack(spacing: 10) {
      Text(L10n.text(query.isEmpty ? "No Notes" : "No Results"))
        .font(.custom("HelveticaNeue-Bold", size: 22))
      Text(L10n.text(query.isEmpty ? "Tap + to create a note." : "No notes match your search."))
        .font(.custom("HelveticaNeue", size: 15))
    }
    .foregroundStyle(ClassicTheme.ink.opacity(0.65))
    .multilineTextAlignment(.center)
    .padding(.horizontal, 24)
    .padding(.top, 85)
    .accessibilityIdentifier("empty-state")
  }

  private var footer: some View {
    Text(L10n.noteCount(store.matching(query).count))
      .font(.custom("HelveticaNeue", size: 14))
      .foregroundStyle(ClassicTheme.ink.opacity(0.75))
      .shadow(color: .white.opacity(0.7), radius: 0, y: 1)
      .frame(maxWidth: .infinity)
      .frame(height: 40)
      .background(PaperBackground())
      .overlay(alignment: .top) { ClassicTheme.rule.opacity(0.6).frame(height: 0.5) }
      .accessibilityIdentifier("note-count")
  }
}

private struct NoteListRow: View {
  let note: Note
  let open: () -> Void
  let delete: () -> Void
  @State private var revealsDelete = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    HStack(spacing: 0) {
      Button(action: open) {
        HStack(spacing: 10) {
          Text(note.title)
            .font(.custom("HelveticaNeue-Bold", size: 20))
            .lineLimit(1)
            .foregroundStyle(Color(red: 0.13, green: 0.10, blue: 0.05))
          Spacer(minLength: 4)
          Text(AppLanguage.current.listDate(note.modifiedAt))
            .font(.custom("HelveticaNeue", size: 14))
            .foregroundStyle(ClassicTheme.ink.opacity(0.65))
            .lineLimit(1)
            .fixedSize()
          Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(ClassicTheme.ink.opacity(0.5))
        }
        .padding(.leading, 18)
        .padding(.trailing, 14)
        .frame(height: 53)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("note-row-\(note.id)")
      .accessibilityAction(named: Text(L10n.text("Delete Note")), delete)
      if revealsDelete {
        Button(L10n.text("Delete Note"), action: delete)
          .font(.custom("HelveticaNeue-Bold", size: 13))
          .foregroundStyle(.white)
          .padding(.horizontal, 9)
          .frame(height: 31)
          .background {
            RoundedRectangle(cornerRadius: 5)
              .fill(
                LinearGradient(
                  colors: [.red.opacity(0.7), .red.opacity(0.95)], startPoint: .top,
                  endPoint: .bottom)
              )
              .overlay(RoundedRectangle(cornerRadius: 5).stroke(.black.opacity(0.3), lineWidth: 1))
          }
          .padding(.trailing, 9)
          .accessibilityIdentifier("row-delete")
      }
    }
    .background(PaperBackground())
    .overlay(alignment: .bottom) {
      VStack(spacing: 0) {
        ClassicTheme.rule.opacity(0.7).frame(height: 0.5)
        Color.white.opacity(0.5).frame(height: 0.5)
      }
    }
    .highPriorityGesture(
      DragGesture(minimumDistance: 30)
        .onEnded { value in
          guard abs(value.translation.width) > abs(value.translation.height) else { return }
          withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
            revealsDelete.toggle()
          }
        })
  }
}
