import SwiftUI

struct SettingsCategoriesDetailPage: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.colorScheme) private var colorScheme
    let palette: FinanceTheme.Palette

    @State private var isEditorPresented = false
    @State private var editorDraft = CategoryEditorDraft.createDefault()
    @State private var categoryPendingDeleteID: UUID?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Button {
                    editorDraft = .createDefault()
                    isEditorPresented = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(palette.accent)
                        Text(String(localized: "Add Category"))
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(palette.ink)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .financeCard(palette: palette)
                }

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
                                palette: palette,
                                onEdit: {
                                    editorDraft = CategoryEditorDraft(
                                        categoryID: category.id,
                                        name: category.name,
                                        type: category.type,
                                        icon: category.icon
                                    )
                                    isEditorPresented = true
                                },
                                onDelete: {
                                    categoryPendingDeleteID = category.id
                                }
                            )
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(FinanceTheme.pageBackground(for: colorScheme))
        .navigationTitle(String(localized: "Categories"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isEditorPresented) {
            CategoryEditorSheet(
                draft: $editorDraft,
                onCancel: {
                    isEditorPresented = false
                },
                onSave: {
                    if let categoryID = editorDraft.categoryID {
                        viewModel.updateCategory(
                            id: categoryID,
                            name: editorDraft.name,
                            type: editorDraft.type,
                            icon: editorDraft.icon
                        )
                    }
                    isEditorPresented = false
                },
                onCreate: {
                    viewModel.createCategory(
                        name: editorDraft.name,
                        type: editorDraft.type,
                        icon: editorDraft.icon
                    )
                    isEditorPresented = false
                }
            )
        }
        .confirmationDialog(
            String(localized: "Delete this category?"),
            isPresented: Binding(
                get: { categoryPendingDeleteID != nil },
                set: { isPresented in
                    if !isPresented {
                        categoryPendingDeleteID = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            if let categoryID = categoryPendingDeleteID {
                Button(String(localized: "Delete"), role: .destructive) {
                    viewModel.deleteCategory(id: categoryID)
                    categoryPendingDeleteID = nil
                }
            }

            Button(String(localized: "Cancel"), role: .cancel) {
                categoryPendingDeleteID = nil
            }
        }
    }
}

struct SettingsCategoryCard: View {
    let category: TransactionFormCategoryOption
    let palette: FinanceTheme.Palette
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button {
            onEdit()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(palette.accent)
                    .frame(width: 36, height: 36)
                    .background(palette.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.ink)

                    Text(category.type.capitalized)
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(category.type == "income" ? .green : palette.secondaryInk)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule(style: .continuous)
                                .fill(category.type == "income" ? Color.green.opacity(0.15) : palette.accentSoft)
                        )
                }

                Spacer()

                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label(String(localized: "Edit"), systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label(String(localized: "Delete"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(palette.secondaryInk)
                        .frame(width: 32, height: 32)
                }
            }
        }
        .buttonStyle(.plain)
        .financeCard(palette: palette)
    }
}

private struct CategoryEditorDraft {
    var categoryID: UUID?
    var name: String
    var type: String
    var icon: String

    static func createDefault() -> CategoryEditorDraft {
        CategoryEditorDraft(categoryID: nil, name: "", type: "expense", icon: "questionmark.circle")
    }
}

private struct CategoryEditorSheet: View {
    @Binding var draft: CategoryEditorDraft
    let onCancel: () -> Void
    let onSave: () -> Void
    let onCreate: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private let typeOptions = ["expense", "income"]
    private let symbolOptions = [
        "questionmark.circle",
        "fork.knife",
        "cart.fill",
        "car.fill",
        "bag.fill",
        "house.fill",
        "heart.fill",
        "cross.case.fill",
        "book.fill",
        "gift.fill",
        "gamecontroller.fill",
        "arrow.down.circle.fill",
        "briefcase.fill",
        "building.columns.fill"
    ]

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    private var titleText: String {
        draft.categoryID == nil ? String(localized: "New Category") : String(localized: "Edit Category")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: draft.icon.isEmpty ? "questionmark.circle" : draft.icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(draft.type == "income" ? Color.green : palette.accent)
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            Text(titleText)
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundStyle(palette.ink)
                            Text(String(localized: "Customize name, type, and symbol"))
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(palette.secondaryInk)
                        }

                        Spacer()
                    }
                    .financeCard(palette: palette)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(String(localized: "Category Name"))
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(palette.secondaryInk)

                        TextField(String(localized: "Category name"), text: $draft.name)
                            .font(.system(.body, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(palette.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(palette.cardBorder, lineWidth: 1)
                            )
                    }
                    .financeCard(palette: palette)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(String(localized: "Type"))
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(palette.secondaryInk)

                        HStack(spacing: 10) {
                            ForEach(typeOptions, id: \.self) { type in
                                Button {
                                    draft.type = type
                                    if draft.icon.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        draft.icon = type == "income" ? "arrow.down.circle.fill" : "questionmark.circle"
                                    }
                                } label: {
                                    Text(type.capitalized)
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        .foregroundStyle(draft.type == type ? Color.white : palette.ink)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(draft.type == type ? palette.accent : palette.cardBackground)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .financeCard(palette: palette)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(String(localized: "Symbol"))
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(palette.secondaryInk)

                        HStack(spacing: 12) {
                            Image(systemName: draft.icon.isEmpty ? "questionmark.circle" : draft.icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(palette.accent)
                                .frame(width: 40, height: 40)
                                .background(palette.accentSoft)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            TextField(String(localized: "SF Symbol name"), text: $draft.icon)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.system(.subheadline, design: .rounded))
                        }

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 42), spacing: 8)], spacing: 8) {
                            ForEach(symbolOptions, id: \.self) { symbol in
                                Button {
                                    draft.icon = symbol
                                } label: {
                                    Image(systemName: symbol)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(draft.icon == symbol ? Color.white : palette.accent)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(draft.icon == symbol ? palette.accent : palette.accentSoft)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .financeCard(palette: palette)
                }
                .padding(16)
            }
            .background(FinanceTheme.pageBackground(for: colorScheme).ignoresSafeArea())
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Cancel")) {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(draft.categoryID == nil ? String(localized: "Add") : String(localized: "Save")) {
                        if draft.categoryID == nil {
                            onCreate()
                        } else {
                            onSave()
                        }
                    }
                    .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
