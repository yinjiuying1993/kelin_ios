import SwiftUI

struct OnboardingMessageBubble: View {
    let message: OnboardingMessage

    var body: some View {
        HStack {
            if message.role == .spirit {
                bubble
                Spacer(minLength: KelinSpacing.section)
            } else {
                Spacer(minLength: KelinSpacing.section)
                bubble
            }
        }
    }

    private var bubble: some View {
        Text(message.text)
            .font(.system(size: 15))
            .foregroundStyle(message.role == .spirit ? Color(red: 0.93, green: 0.94, blue: 0.97) : KelinColor.textPrimary)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, KelinSpacing.standard)
            .padding(.vertical, KelinSpacing.compact)
            .background(
                RoundedRectangle(cornerRadius: KelinRadius.standard)
                    .fill(message.role == .spirit ? KelinColor.surfacePrimary : KelinColor.accentSurface)
            )
            .overlay {
                RoundedRectangle(cornerRadius: KelinRadius.standard)
                    .stroke(KelinColor.borderSubtle, lineWidth: 1)
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: message.role == .spirit ? KelinRadius.small : KelinRadius.standard,
                    bottomLeadingRadius: KelinRadius.standard,
                    bottomTrailingRadius: KelinRadius.standard,
                    topTrailingRadius: message.role == .user ? KelinRadius.small : KelinRadius.standard
                )
            )
            .frame(maxWidth: message.role == .spirit ? 320 : 290, alignment: message.role == .spirit ? .leading : .trailing)
            .accessibilityLabel(
                message.role == .spirit
                    ? String(localized: "精灵说：\(message.text)")
                    : String(localized: "你说：\(message.text)")
            )
    }
}
