import SwiftUI

struct TransactionListScreen: View {
    @ObservedObject var viewModel: TransactionListViewModel
    @Environment(\.colorScheme) private var colorScheme

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        NavigationStack {
            List {
                if viewModel.sections.isEmpty {
                    Text(String(localized: "No transactions yet"))
                        .foregroundStyle(palette.secondaryInk)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.sections, id: \.title) { section in
                        Section {
                            ForEach(section.items, id: \.id) { item in
                                HStack {
                                    Image(systemName: "creditcard")
                                        .foregroundStyle(palette.accent)
                                        .frame(width: 30, height: 30)
                                        .background(palette.accentSoft)
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.merchant)
                                            .font(.system(.body, design: .rounded).weight(.semibold))
                                        Text("\(item.category) • \(item.account)")
                                            .font(.footnote)
                                            .foregroundStyle(palette.secondaryInk)
                                    }
                                    Spacer()
                                    Text(currencyText(item.amount))
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        .foregroundStyle(palette.ink)

                                    Image(systemName: "chevron.right")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(palette.secondaryInk)
                                }
                                .financeCard(palette: palette)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.beginEdit(id: item.id)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.deleteTransaction(id: item.id)
                                    } label: {
                                        Label(String(localized: "Delete"), systemImage: "trash")
                                    }
                                }
                            }
                        } header: {
                            Text(section.title)
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .textCase(nil)
                                .foregroundStyle(palette.secondaryInk)
                        }
                    }
                }

                if let actionMessage = viewModel.actionMessage {
                    Section(String(localized: "Last Action")) {
                        Text(actionMessage)
                            .font(.footnote)
                            .foregroundStyle(palette.secondaryInk)
                    }
                    .listRowBackground(Color.clear)
                }

                if let errorMessage = viewModel.errorMessage {
                    Section(String(localized: "Error")) {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(FinanceTheme.pageBackground(for: colorScheme))
            .navigationTitle(String(localized: "Transactions"))
            .onAppear {
                viewModel.load()
            }
            .animation(.spring(response: 0.36, dampingFraction: 0.82), value: viewModel.sections)
        }
    }

    private func currencyText(_ value: Double) -> String {
        value.formatted(.currency(code: "IDR").precision(.fractionLength(0)))
    }
}
