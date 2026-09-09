import SwiftUI

struct HatchTransitionOverlay: View {
    @State private var opacity: Double = 1

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: KelinSpacing.section) {
                IncubatingEggView()
                    .opacity(opacity)

                KelinLoadingDots()
            }
        }
        .accessibilityLabel(String(localized: "孵化中"))
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                opacity = 0
            }
        }
    }
}
