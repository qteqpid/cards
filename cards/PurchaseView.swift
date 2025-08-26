import SwiftUI
import StoreKit

struct PurchaseView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var purchaseManager: InAppPurchaseManager
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showRestoreAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // 标题区域
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        
                        Text("海龟汤专业版")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("解锁永久使用权限")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    
                    // 功能列表
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(icon: "clock.badge.checkmark", title: "永久使用", description: "不再受试用期使用限制")
                        FeatureRow(icon: "shield.checkered", title: "所有功能", description: "体验最全最新的功能")
                        FeatureRow(icon: "arrow.up.circle", title: "感谢打赏", description: "您的支持是我继续努力的动力，谢谢！")
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // 购买按钮
                    VStack(spacing: 16) {
                            Button(action: {
                                Task {
                                    do {
                                        try await purchaseManager.purchase()
                                        dismiss()
                                    } catch {
                                        errorMessage = error.localizedDescription
                                        showError = true
                                    }
                                }
                            }) {
                                HStack {
                                    if purchaseManager.isPurchasing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "crown.fill")
                                            .font(.headline)
                                    }
                                    Text(purchaseManager.isPurchasing ? "购买中..." : "立即升级")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                            .disabled(purchaseManager.isPurchasing)
                        
                        Button("恢复购买") {
                            Task {
                                do {
                                    try await purchaseManager.restorePurchases()
                                    showRestoreAlert = true
                                } catch {
                                    errorMessage = "恢复购买失败：\(error.localizedDescription)"
                                    showError = true
                                }
                            }
                        }
                        .foregroundColor(.blue)
                        .font(.subheadline)
                        
                        Button("稍后再说") {
                            dismiss()
                        }
                        .foregroundColor(.gray)
                        .font(.subheadline)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
        .alert("购买失败", isPresented: $showError) {
            Button("确定") {}
        } message: {
            Text(errorMessage)
        }
        .alert("恢复购买", isPresented: $showRestoreAlert) {
            Button("确定") {
                dismiss()
            }
        } message: {
            Text(purchaseManager.isPremium ?  "恢复购买成功" : "没有找到已购买的产品")
        }
        .onAppear {
            Task {
                await purchaseManager.loadProducts()
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.yellow)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    PurchaseView(purchaseManager: InAppPurchaseManager.shared)
} 
