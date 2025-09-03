//  LabelsView.swift
//  cards
//
//  Created by Gongliang Zhang on 2025/7/28.
//

import SwiftUI

struct LabelsView: View {
    let labels: [String]
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(labels, id: \.self) {
                label in
                Text(label)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                                    .foregroundColor(colorForLabel(label).foreground)
                                    .background(colorForLabel(label).background)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.black.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5, 2]))
                                    )
                                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    // 根据label内容返回背景色和前景色
    private func colorForLabel(_ label: String) -> (background: Color, foreground: Color) {
        // 使用元组存储背景色和前景色
        let colors: [String: (background: Color, foreground: Color)] = [
            "红汤": (Color.red.opacity(0.2), Color.primary),
            "清汤": (Color.green.opacity(0.2), Color.primary),
            "黑汤": (Color.black.opacity(0.6), Color.white), // 伦理扭曲、人性黑暗
            "变格": (Color.white.opacity(0.3), Color.primary),
            "本格": (Color.gray.opacity(0.2), Color.primary)
        ]
        
        if let colorPair = colors[label] {
            return colorPair
        } else {
            return (Color.yellow.opacity(0.2), Color.primary)
        }
    }
}