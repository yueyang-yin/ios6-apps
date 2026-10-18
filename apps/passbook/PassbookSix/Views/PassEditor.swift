import SwiftUI

struct PassEditor: View {
  var onClose: () -> Void
  var onSave: (PocketPass) -> Void
  @State private var kind: PassKind = .storeCard
  @State private var organization = ""
  @State private var title = ""
  @State private var detail = ""
  @State private var code = ""
  @State private var notes = ""
  @State private var hasDate = false
  @State private var date = Date()

  var body: some View {
    VStack(spacing: 0) {
      PassNavigation(
        title: L10n.text("New Pass"), trailing: "Add", onLeading: onClose,
        onTrailing: save,
        trailingEnabled: !organization.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
          && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      ScrollView {
        VStack(spacing: 20) {
          Picker(L10n.text("Pass type"), selection: $kind) {
            ForEach(PassKind.allCases) { kind in Text(L10n.text(kind.title)).tag(kind) }
          }.pickerStyle(.menu).tint(.white)
            .padding(12).frame(maxWidth: .infinity).background(
              .black.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
          VStack(spacing: 1) {
            input("Organization", text: $organization, identifier: "pass-organization")
            input("Title", text: $title, identifier: "pass-title")
            input("Details", text: $detail, identifier: "pass-details")
            input("Barcode message", text: $code, identifier: "pass-code")
          }.clipShape(RoundedRectangle(cornerRadius: 8))
          Toggle(L10n.text("Expiration date"), isOn: $hasDate).tint(Color(passHex: "3975AA"))
          if hasDate {
            DatePicker(
              L10n.text("Expires"), selection: $date, displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
          }
          VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("Notes")).font(PassTheme.font(14, bold: true))
            TextEditor(text: $notes).frame(height: 110).scrollContentBackground(.hidden)
              .padding(6).background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
              .accessibilityLabel(L10n.text("Notes"))
          }
          Text(L10n.text("Local pass explanation")).font(PassTheme.font(13))
            .foregroundStyle(.white.opacity(0.6)).fixedSize(horizontal: false, vertical: true)
          if organization.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
          {
            Text(L10n.text("Organization and title are required.")).font(PassTheme.font(13))
              .foregroundStyle(.white.opacity(0.7))
          }
        }.padding(20).frame(maxWidth: 500).frame(maxWidth: .infinity)
      }.scrollDismissesKeyboard(.interactively)
    }.foregroundStyle(.white)
  }

  private func input(_ label: String, text: Binding<String>, identifier: String) -> some View {
    TextField(L10n.text(label), text: text).font(PassTheme.font(17)).padding(14)
      .background(.white.opacity(0.1)).accessibilityLabel(L10n.text(label)).accessibilityIdentifier(
        identifier)
  }

  private func save() {
    let name = organization.trimmingCharacters(in: .whitespacesAndNewlines)
    let heading = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty, !heading.isEmpty else { return }
    let pass = PocketPass(
      id: UUID().uuidString, kind: kind, organization: name, title: heading,
      colorHex: kind.hex, primary: [.init(key: "title", label: "", value: heading)],
      secondary: detail.isEmpty ? [] : [.init(key: "details", label: "Details", value: detail)],
      barcode: code.isEmpty
        ? nil
        : .init(message: code, format: "PKBarcodeFormatQR", alternateText: code, encoding: "utf-8"),
      expirationDate: hasDate ? date : nil, userNote: notes)
    onSave(pass)
  }
}
