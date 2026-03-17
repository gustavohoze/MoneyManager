import SwiftUI

enum FinanceTheme {
    struct Palette {
        let accent: Color
        let accentSoft: Color
        let ink: Color
        let secondaryInk: Color
        let pageTop: Color
        let pageBottom: Color
        let cardBackground: Color
        let cardBorder: Color
        let heroStart: Color
        let heroEnd: Color
    }

    static func palette(for colorScheme: ColorScheme) -> Palette {
        if colorScheme == .dark {
            return Palette(
                accent: Color(red: 0.26, green: 0.86, blue: 0.66),
                accentSoft: Color(red: 0.15, green: 0.25, blue: 0.22),
                ink: Color(red: 0.94, green: 0.96, blue: 0.98),
                secondaryInk: Color(red: 0.67, green: 0.72, blue: 0.78),
                pageTop: Color(red: 0.06, green: 0.08, blue: 0.11),
                pageBottom: Color(red: 0.10, green: 0.12, blue: 0.16),
                cardBackground: Color(red: 0.12, green: 0.15, blue: 0.19),
                cardBorder: Color.white.opacity(0.08),
                heroStart: Color(red: 0.08, green: 0.49, blue: 0.37),
                heroEnd: Color(red: 0.05, green: 0.32, blue: 0.25)
            )
        }

        return Palette(
            accent: Color(red: 0.02, green: 0.52, blue: 0.38),
            accentSoft: Color(red: 0.84, green: 0.95, blue: 0.90),
            ink: Color(red: 0.10, green: 0.13, blue: 0.16),
            secondaryInk: Color(red: 0.45, green: 0.50, blue: 0.56),
            pageTop: Color.white,
            pageBottom: Color(red: 0.95, green: 0.97, blue: 0.98),
            cardBackground: Color.white,
            cardBorder: Color.black.opacity(0.05),
            heroStart: Color(red: 0.02, green: 0.52, blue: 0.38),
            heroEnd: Color(red: 0.03, green: 0.37, blue: 0.28)
        )
    }

    static func pageBackground(for colorScheme: ColorScheme) -> LinearGradient {
        let palette = palette(for: colorScheme)
        return LinearGradient(
            colors: [palette.pageTop, palette.pageBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct FinanceCardModifier: ViewModifier {
    let palette: FinanceTheme.Palette

    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(palette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(palette.cardBorder, lineWidth: 1)
            )
    }
}

extension View {
    func financeCard(palette: FinanceTheme.Palette) -> some View {
        modifier(FinanceCardModifier(palette: palette))
    }
}
