import SwiftUI

struct DashboardInsightPageIndicator: View {
    @Binding var insightPage: Int
    let palette: FinanceTheme.Palette

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<2, id: \.self) { index in
                Capsule()
                    .fill(insightPage == index ? palette.accent : palette.accentSoft)
                    .frame(width: insightPage == index ? 20 : 8, height: 6)
                    .animation(.spring(response: 0.25, dampingFraction: 0.85), value: insightPage)
                    .onTapGesture {
                        insightPage = index
                    }
                    .accessibilityLabel(index == 0 ? "Weekly Trend" : "Category Distribution")
                    .accessibilityAddTraits(insightPage == index ? [.isSelected] : [])
            }
        }
    }
}
