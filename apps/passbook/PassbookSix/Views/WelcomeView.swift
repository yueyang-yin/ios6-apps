import SwiftUI

struct WelcomeView: View {
  var openCatalog: () -> Void
  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(spacing: geometry.size.height < 600 ? 20 : 34) {
          Text(L10n.text("Welcome headline"))
            .font(PassTheme.font(24)).multilineTextAlignment(.center)
            .lineSpacing(4).shadow(color: .black, radius: 1, y: 1)
            .padding(.top, geometry.size.height < 600 ? 18 : 36)
          VStack(spacing: geometry.size.height < 600 ? 13 : 22) {
            ForEach([PassKind.boardingPass, .eventTicket, .storeCard, .coupon]) { kind in
              Button(action: openCatalog) {
                HStack(spacing: 26) {
                  MiniTicket(kind: kind)
                  Text(L10n.text(kind.title)).font(PassTheme.font(23))
                    .shadow(color: .black, radius: 1, y: 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }.padding(.horizontal, geometry.size.width > 420 ? 55 : 34)
              }.buttonStyle(.plain)
            }
          }
          Text(L10n.text("Welcome explanation"))
            .font(PassTheme.font(14)).multilineTextAlignment(.center)
            .foregroundStyle(.white.opacity(0.7)).lineSpacing(3).padding(.horizontal, 30)
          Button(L10n.text("Add Passes"), action: openCatalog)
            .buttonStyle(ClassicButton()).accessibilityIdentifier("welcome-add")
            .padding(.bottom, 24)
        }.frame(maxWidth: 500).frame(maxWidth: .infinity)
      }.scrollIndicators(.hidden)
    }.foregroundStyle(.white)
  }
}

struct PassCatalog: View {
  var onClose: () -> Void
  var onAdd: (PocketPass) -> Void
  var onImport: () -> Void
  var onCreate: () -> Void
  var onSamples: () -> Void
  var body: some View {
    VStack(spacing: 0) {
      PassNavigation(title: L10n.text("Add Passes"), onLeading: onClose)
      ScrollView {
        VStack(spacing: 20) {
          Text(L10n.text("Keep it all in your pocket."))
            .font(PassTheme.font(23)).multilineTextAlignment(.center).padding(.top, 24)
          Text(L10n.text("Catalog explanation")).font(PassTheme.font(14))
            .foregroundStyle(.white.opacity(0.7)).multilineTextAlignment(.center)
          VStack(spacing: 1) {
            catalogAction(
              "Import a .pkpass file", symbol: "square.and.arrow.down", action: onImport)
            catalogAction("Create a local pass", symbol: "pencil", action: onCreate)
          }.clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black, lineWidth: 1))
          Text(L10n.text("SAMPLE PASSES")).font(PassTheme.font(12, bold: true))
            .tracking(1.5).foregroundStyle(.white.opacity(0.6))
            .frame(maxWidth: .infinity, alignment: .leading)
          ForEach([PassKind.boardingPass, .eventTicket, .storeCard, .coupon]) { kind in
            Button {
              onAdd(PassSamples.make(kind))
            } label: {
              HStack(spacing: 20) {
                MiniTicket(kind: kind).scaleEffect(0.75).frame(width: 52, height: 66)
                VStack(alignment: .leading, spacing: 4) {
                  Text(L10n.text(kind.title)).font(PassTheme.font(18))
                  Text(L10n.text("Try a sample pass")).font(PassTheme.font(12)).foregroundStyle(
                    .white.opacity(0.6))
                }
                Spacer()
                Image(systemName: "plus.circle.fill").font(.system(size: 24)).foregroundStyle(
                  .white.opacity(0.65))
              }.padding(10).background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
            }.buttonStyle(.plain).accessibilityIdentifier("sample-\(kind.rawValue)")
          }
          Button(L10n.text("Add sample collection"), action: onSamples)
            .buttonStyle(ClassicButton()).accessibilityIdentifier("add-samples")
          Text(L10n.text("Sample pass explanation")).font(PassTheme.font(12))
            .foregroundStyle(.white.opacity(0.6)).multilineTextAlignment(.center).padding(
              .bottom, 30)
        }.padding(.horizontal, 20).frame(maxWidth: 500).frame(maxWidth: .infinity)
      }
    }.foregroundStyle(.white)
  }
  private func catalogAction(_ key: String, symbol: String, action: @escaping () -> Void)
    -> some View
  {
    Button(action: action) {
      HStack {
        Image(systemName: symbol).frame(width: 24)
        Text(L10n.text(key)).font(PassTheme.font(17, bold: true))
        Spacer()
        Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
      }.padding(.horizontal, 14).frame(minHeight: 52).background(.white.opacity(0.1))
    }.buttonStyle(.plain)
  }
}
