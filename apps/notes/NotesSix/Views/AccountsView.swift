import SwiftUI

struct AccountsView: View {
  let count: Int
  let select: () -> Void
  let back: () -> Void
  let settings: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      ClassicNavigationBar(title: L10n.text("Accounts")) {
        Button(L10n.text("Notes"), action: back)
          .buttonStyle(LeatherButtonStyle(back: true))
          .accessibilityIdentifier("back-to-notes")
      } trailing: {
        Button(action: settings) {
          Image(systemName: "gearshape.fill").font(.system(size: 16))
        }
        .buttonStyle(LeatherButtonStyle())
        .accessibilityLabel(L10n.text("Settings"))
        .accessibilityIdentifier("notes-settings")
      }
      ScrollView {
        VStack(spacing: 0) {
          accountRow("All Notes", identifier: "all-notes")
          accountRow("On My iPhone", identifier: "local-account")
        }
        .background(.white, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.gray.opacity(0.5), lineWidth: 1))
        .padding(.horizontal, 10)
        .padding(.top, 30)
      }
      .background(PinstripeBackground())
    }
  }

  private func accountRow(_ name: String, identifier: String) -> some View {
    Button(action: select) {
      HStack {
        Text(L10n.text(name))
          .font(.custom("HelveticaNeue-Bold", size: 18))
        Spacer()
        Text("\(count)").font(.custom("HelveticaNeue", size: 17)).foregroundStyle(.gray)
        Image(systemName: "chevron.right").font(.system(size: 15, weight: .bold)).foregroundStyle(
          .gray)
      }
      .foregroundStyle(.black)
      .padding(.horizontal, 14)
      .frame(height: 46)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .overlay(alignment: .bottom) { Color.gray.opacity(0.22).frame(height: 0.5) }
    .accessibilityIdentifier(identifier)
  }
}

struct PinstripeBackground: View {
  var body: some View {
    Canvas { context, size in
      context.fill(
        Path(CGRect(origin: .zero, size: size)),
        with: .color(Color(red: 0.82, green: 0.84, blue: 0.87)))
      var lines = Path()
      for x in stride(from: CGFloat(0), through: size.width, by: 7) {
        lines.move(to: CGPoint(x: x, y: 0))
        lines.addLine(to: CGPoint(x: x, y: size.height))
      }
      context.stroke(lines, with: .color(.white.opacity(0.16)), lineWidth: 2)
    }
    .accessibilityHidden(true)
  }
}

struct NotesSettingsView: View {
  let store: NotesStore
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 0) {
      ClassicNavigationBar(title: L10n.text("Settings")) {
        EmptyView()
      } trailing: {
        Button(L10n.text("Done")) { dismiss() }
          .buttonStyle(LeatherButtonStyle())
          .accessibilityIdentifier("close-settings")
      }
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          Text(L10n.text("Font")).font(.custom("HelveticaNeue-Bold", size: 17))
            .foregroundStyle(.black.opacity(0.65))
          VStack(spacing: 0) {
            ForEach(NoteFont.allCases, id: \.self) { font in
              Button {
                store.setFont(font)
              } label: {
                HStack {
                  Text(font.rawValue).font(.custom(font.postScriptName, size: 21))
                  Spacer()
                  if store.font == font {
                    Image(systemName: "checkmark").foregroundStyle(
                      Color(red: 0.22, green: 0.34, blue: 0.50))
                  }
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .contentShape(Rectangle())
              }
              .buttonStyle(.plain)
              .accessibilityIdentifier("font-\(font.rawValue)")
              .accessibilityAddTraits(store.font == font ? .isSelected : [])
              .overlay(alignment: .bottom) { Color.gray.opacity(0.2).frame(height: 0.5) }
            }
          }
          .background(.white, in: RoundedRectangle(cornerRadius: 10))
          .overlay(RoundedRectangle(cornerRadius: 10).stroke(.gray.opacity(0.5), lineWidth: 0.7))
          Text(L10n.text("The quick brown fox jumps over the lazy dog."))
            .font(.custom(store.font.postScriptName, size: 21))
            .foregroundStyle(ClassicTheme.ink)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PaperBackground(ruled: true, margin: true))
          info(
            "Storage",
            "Notes are saved automatically on this iPhone. iCloud and mail account synchronization are not available."
          )
          info(
            "Language",
            "The interface follows your iPhone or per-app language. English and Simplified Chinese are supported. Your note text stays as you wrote it."
          )
        }
        .padding(20)
      }
      .background(PinstripeBackground())
    }
    .preferredColorScheme(.light)
  }

  private func info(_ heading: String, _ description: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(L10n.text(heading)).font(.custom("HelveticaNeue-Bold", size: 16))
      Text(L10n.text(description)).font(.custom("HelveticaNeue", size: 14))
    }
    .foregroundStyle(.black.opacity(0.65))
  }
}
