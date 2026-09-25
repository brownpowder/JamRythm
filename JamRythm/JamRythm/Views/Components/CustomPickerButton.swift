import SwiftUI
import StoreKit

struct CustomPickerButton<T: Identifiable & Equatable, Label: View, OptionRow: View>: View {
    let options: [T]
    @Binding var selection: T
    let sheetTitle: String
    @ViewBuilder let label: () -> Label
    @ViewBuilder let optionRow: (T) -> OptionRow

    @State private var isSheetPresented = false
    @State private var showPaywall = false
    @ObservedObject var store = StoreManager.shared

    var body: some View {
        Button(action: { isSheetPresented = true }) {
            label()
        }
        .sheet(isPresented: $isSheetPresented) {
            ZStack {
            NavigationView {
                List(options) { option in
                    Button(action: {
                        let isLockable = option as? PremiumLockable != nil
                        let locked = (option as? PremiumLockable)?.isLocked ?? false
                        print("DEBUG CustomPickerButton: Tapped option: \(option)")
                        print("DEBUG CustomPickerButton: Cast to PremiumLockable successful? \(isLockable)")
                        print("DEBUG CustomPickerButton: isLocked evaluated to: \(locked)")
                        
                        if locked {
                            showPaywall = true
                        } else {
                            selection = option
                            isSheetPresented = false
                        }
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
                .fullScreenCover(isPresented: $showPaywall) {
                    PremiumPaywallView()
                }
                .navigationTitle(LocalizedStringKey(sheetTitle))
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
            TourOverlayView(spaceName: "PickerTourSpace")
            }
            .environmentObject(TourManager.shared)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

struct PremiumPaywallView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store = StoreManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Image / Icon
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 30)
                    
                    Text(LocalizedStringKey("プレミアム機能のロック解除"))
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    
                    Text(LocalizedStringKey("一度の買い切りで、すべての追加機能が使い放題になります！サブスクリプションではありません。"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    // Features List
                    VStack(alignment: .leading, spacing: 16) {
                        featureRow(icon: "music.mic", color: .blue, title: "12人の追加プレイヤー", description: "個性豊かなドラム・ベース・ピアノプレイヤーをすべて解放。")
                        featureRow(icon: "music.note.list", color: .green, title: "特殊なスケール", description: "Japaneseや琉球音階など、エキゾチックなスケールで作曲可能に。")
                        featureRow(icon: "guitars.fill", color: .purple, title: "追加の音楽ジャンル", description: "Lo-FiやR&Bなど、お洒落で洗練された伴奏スタイルを追加。")
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                    
                    Spacer(minLength: 30)
                    
                    // Purchase Button
                    Button(action: {
                        store.purchasePremium()
                    }) {
                        if let product = store.products.first {
                            Text("\(product.displayPrice) で全てロック解除")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(16)
                                .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                        } else {
                            Text("¥800 で全てロック解除")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(16)
                                .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Restore Purchases
                    Button(action: {
                        store.restorePurchases()
                        dismiss()
                    }) {
                        Text(LocalizedStringKey("購入を復元する"))
                            .font(.footnote.bold())
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onChange(of: store.isPremium) { _, newValue in
            if newValue {
                dismiss()
            }
        }
    }
    
    private func featureRow(icon: String, color: Color, title: LocalizedStringKey, description: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
        }
    }
}
