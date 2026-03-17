import SwiftUI

struct SettingsCategoriesDetailPage: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.colorScheme) private var colorScheme
    let palette: FinanceTheme.Palette

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.categories.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "square.grid.2x2.circle")
                            .font(.system(size: 40))
                            .foregroundStyle(palette.accentSoft)
                        Text(String(localized: "No categories found"))
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(palette.ink)
                        Text(String(localized: "Categories help organize and track your spending."))
                            .font(.caption)
                            .foregroundStyle(palette.secondaryInk)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .financeCard(palette: palette)
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.categories) { category in
                            SettingsCategoryCard(
                                category: category,
                                palette: palette
                            )
                        }
                    }
                }

                // Info card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(palette.accent)
                        Text(String(localized: "Advanced category management (create, merge, delete) will be available in the next milestone."))
                            .font(.caption)
                            .foregroundStyle(palette.secondaryInk)
                    }
                }
                .financeCard(palette: palette)
            }
            .padding(16)
        }
        .background(FinanceTheme.pageBackground(for: colorScheme))
        .navigationTitle(String(localized: "Categories"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsCategoryCard: View {
    let category: TransactionFormCategoryOption
    let palette: FinanceTheme.Palette

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.system(size: 18))
                .foregroundStyle(palette.accent)
                .frame(width: 32, height: 32)
                .background(palette.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(palette.ink)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(palette.secondaryInk)
        }
        .financeCard(palette: palette)
    }
}


