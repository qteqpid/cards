//
//  CardModel.swift
//  cards
//
//  Created by Gongliang Zhang on 2025/7/28.
//

import SwiftUI

// 卡片面数据模型
struct CardSide: Codable, Equatable {
    let title: String?
    let description: String?
    let icon: String?
}

// 卡片数据模型
struct Card: Identifiable, Codable, Equatable {
    // 从JSON加载的整数ID，实现Identifiable协议
    let id: Int
    // 原创作者
    let author: String?
    let authorUrl: String?
    let front: CardSide
    let back: CardSide
    // 标签数组，可为空
    let labels: [String]?
    let position: Int?
    let isFree: Bool?

    var isFreeCard: Bool {
        isFree ?? false
    }
}
