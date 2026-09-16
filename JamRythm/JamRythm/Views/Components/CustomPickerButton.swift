import SwiftUI

struct CustomPickerButton<T: Identifiable & Equatable, Label: View, OptionRow: View>: View {
    let options: [T]
    @Binding var selection: T
    let sheetTitle: String
    @ViewBuilder let label: () -> Label
    @ViewBuilder let optionRow: (T) -> OptionRow

    @State private var isSheetPresented = false

    var body: some View {
        Button(action: { isSheetPresented = true }) {
            label()
        }
        .sheet(isPresented: $isSheetPresented) {
            NavigationView {
                List(options) { option in
                    Button(action: {
                        selection = option
                        isSheetPresented = false
                    }) {
                        HStack(spacing: 16) {
                            optionRow(option)
                            Spacer()
                            if selection == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                }
                .listStyle(.insetGrouped)
                .navigationTitle(sheetTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { isSheetPresented = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}
