import SwiftUI

/// 应用启动页视图
/// 展示海龟汤介绍和欢迎信息
struct LaunchView: View {
    @State private var isShowingMainView = false
    @State private var animationProgress: CGFloat = 0
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var descriptionOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.8),
                    Color.blue.opacity(0.6),
                    Color.cyan.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 装饰性背景元素
            GeometryReader { geometry in
                ZStack {
                    // 浮动圆圈
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .offset(x: geometry.size.width * 0.8, y: geometry.size.height * 0.2)
                        .scaleEffect(1 + sin(animationProgress * 2) * 0.1)
                    
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 150, height: 150)
                        .offset(x: geometry.size.width * 0.1, y: geometry.size.height * 0.8)
                        .scaleEffect(1 + cos(animationProgress * 1.5) * 0.1)
                    
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 100, height: 100)
                        .offset(x: geometry.size.width * 0.7, y: geometry.size.height * 0.7)
                        .scaleEffect(1 + sin(animationProgress * 3) * 0.1)
                }
            }
            
            // 主要内容
            VStack(spacing: 40) {
                Spacer()
                
                // 应用图标和标题
                VStack(spacing: 20) {
                    // 应用图标
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                        
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(1 + sin(animationProgress * 2) * 0.05)
                    
                    // 应用标题
                    Text(AppConfigs.appTitle)
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                        .opacity(titleOpacity)
                }
                
                // 介绍文字
                VStack(spacing: 25) {
                    // 副标题
                    Text("推理游戏")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(subtitleOpacity)
                    
                    // 描述文字
                    VStack(spacing: 15) {
                        Text("海龟汤是一种经典的推理游戏")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        Text("通过提问来揭开谜题背后的真相")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        Text("挑战你的逻辑思维和推理能力")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .opacity(descriptionOpacity)
                }
                
                Spacer()
                
                // 开始按钮
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isShowingMainView = true
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text("开始体验")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .foregroundColor(.purple)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    )
                }
                .opacity(buttonOpacity)
                .scaleEffect(buttonOpacity > 0 ? 1 : 0.8)
                
                Spacer()
                
                // 底部提示
                Text("准备好挑战你的推理能力了吗？")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .opacity(buttonOpacity)
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            startAnimations()
        }
        .fullScreenCover(isPresented: $isShowingMainView) {
            ContentView()
        }
    }
    
    /// 启动动画序列
    private func startAnimations() {
        // 开始背景动画
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            animationProgress = 1
        }
        
        // 标题动画
        withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
            titleOpacity = 1
        }
        
        // 副标题动画
        withAnimation(.easeInOut(duration: 0.8).delay(0.6)) {
            subtitleOpacity = 1
        }
        
        // 描述动画
        withAnimation(.easeInOut(duration: 0.8).delay(0.9)) {
            descriptionOpacity = 1
        }
        
        // 按钮动画
        withAnimation(.easeInOut(duration: 0.8).delay(1.2)) {
            buttonOpacity = 1
        }
    }
}

#Preview {
    LaunchView()
} 
