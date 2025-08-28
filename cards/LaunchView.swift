import SwiftUI

/// 应用启动页视图
/// 展示海龟汤介绍和欢迎信息
struct LaunchView: View {
    @State private var isShowingMainView = false
    @State private var subtitleOpacity: Double = 0
    @State private var descriptionOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // 背景图片
            let imagePath = Bundle.main.path(forResource: "cover", ofType: "jpg")
            Image(uiImage: UIImage(contentsOfFile: imagePath!) ?? UIImage())
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .brightness(-0.3) // 稍微调暗图片，确保前景内容清晰可见
            
            
            // 主要内容
            VStack() {
                Spacer()
                
    
                // 介绍文字
                VStack(spacing: 25) {
                    // 副标题
                    Text("推理游戏")
                        .font(.system(size: AppConfigs.startTitleFontSize, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(subtitleOpacity)
                    
                    // 描述文字
                    VStack(spacing: 15) {
                        Text("海龟汤是一种经典的推理游戏")
                            .font(.system(size: AppConfigs.startFontSize, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        Text("通过提问来揭开谜题背后的真相")
                            .font(.system(size: AppConfigs.startFontSize, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        Text("挑战你的逻辑思维和推理能力")
                            .font(.system(size: AppConfigs.startFontSize, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .opacity(descriptionOpacity)
                }
                .padding(.bottom, 40)
                
                Spacer()
                
                // 开始按钮
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isShowingMainView = true
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: AppConfigs.startButtonFontSize+2, weight: .semibold))
                        
                        Text("开始体验")
                            .font(.system(size: AppConfigs.startButtonFontSize, weight: .semibold, design: .rounded))
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
            }
            
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
        // 副标题动画
        withAnimation(.easeInOut(duration: 0.8).delay(0.1)) {
            subtitleOpacity = 1
        }
        
        // 描述动画
        withAnimation(.easeInOut(duration: 0.8).delay(0.5)) {
            descriptionOpacity = 1
        }
        
        // 按钮动画
        withAnimation(.easeInOut(duration: 0.8).delay(1.0)) {
            buttonOpacity = 1
        }
    }
}

#Preview {
    LaunchView()
}
