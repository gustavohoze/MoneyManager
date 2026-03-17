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
                                TransactionListRow(
                                    item: item,
                                    palette: palette,
                                    amountText: viewModel.currencyText(item.amount),
                                    onTap: { viewModel.beginEdit(id: item.id) },
                                    onDelete: { viewModel.deleteTransaction(id: item.id) }
                                )
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
}
