import SwiftUI

struct LeftBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius: CGFloat = 16
        // 起点：左上角（直角）
        path.move(to: CGPoint(x: 0, y: rect.minY))
        // 顶部直线到右上角
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        // 右上角圆角
        path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius), radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        // 右侧直线
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        // 右下角圆角
        path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius), radius: radius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        // 底部直线到左下角
        path.addLine(to: CGPoint(x: radius, y: rect.maxY))
        // 左下角圆角
        path.addArc(center: CGPoint(x: radius, y: rect.maxY - radius), radius: radius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        // 左侧直线回到左上角
        path.addLine(to: CGPoint(x: 0, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
