//
//  cardsApp.swift
//  cards
//
//  Created by Gongliang Zhang on 2025/7/28.
//

import SwiftUI

@main
struct cardsApp: App {
    @StateObject private var purchaseManager = InAppPurchaseManager.shared
    var body: some Scene {
        WindowGroup {
            LaunchView()
                .onAppear {
                    // 如果不是会员，才加载产品信息
                    if !purchaseManager.isPremium {
                        Task {
                            await purchaseManager.loadProducts()
                        }
                    }
                }
        }
    }
}
