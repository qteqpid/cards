import AVFoundation
import SwiftUI

// 导入应用配置

// 音乐图标的颜色渐变动画修饰符
struct MusicNoteAnimation: ViewModifier {
    // 动画状态变量
    @State private var hue = 0.0
    @State private var scale = 1.0
    
    func body(content: Content) -> some View {
        content
            // 使用hueRotation来实现颜色变化
            .hueRotation(Angle(degrees: hue))
            // 添加缩放效果
            .scaleEffect(scale)
            // 添加无限循环的动画
            .onAppear {
                // 色相旋转动画
                withAnimation(Animation.linear(duration: 4).repeatForever(autoreverses: false)) {
                    hue = 360.0 // 360度色相旋转，覆盖所有颜色
                }
                // 缩放动画
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    scale = 1.2 // 放大到1.2倍
                }
            }
    }
}

// 音乐播放/暂停按钮视图组件
struct MusicToggleButton: View {
    @ObservedObject var musicPlayer: MusicPlayer
    
    var body: some View {
        Button(action: {
            musicPlayer.togglePlayback()
        }) {
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: AppConfigs.buttonSize, height: AppConfigs.buttonSize)
                .overlay(
                    Group {
                        if musicPlayer.isPlaying {
                            // 播放时的动态效果
                            Image(systemName: "music.note")
                                .font(.system(size: AppConfigs.buttonImageSize))
                                .foregroundColor(Color.blue) // 使用更明显的颜色
                                .animation(.none) // 禁用默认动画
                                // 添加自定义动画修饰符
                                .modifier(MusicNoteAnimation())
                        } else {
                            // 暂停时的静态图标
                            Image(systemName: "music.note")
                                .font(.system(size: AppConfigs.buttonImageSize))
                                .foregroundColor(Color.black)
                        }
                    }
                )
                .shadow(radius: 5)
        }
        .padding(.top, 20)
    }
}

class MusicPlayer: ObservableObject {
    @Published var isPlaying = true
    private var audioPlayer: AVAudioPlayer?
    private let audioFileName = "bg_audio"
    private let audioFileType = "m4a"
    
    // 单例模式，确保整个应用中只有一个音乐播放器实例
    static let shared = MusicPlayer()
    
    // 私有初始化方法，防止外部创建实例
    private init() {
        if isPlaying {
            initializePlayer()
        }
    }
    
    // 播放或暂停背景音乐
    func togglePlayback() {
        if let player = audioPlayer {
            // 已经有播放器实例
            if player.isPlaying {
                player.pause()
                isPlaying = false
            } else {
                player.play()
                isPlaying = true
            }
        } else {
            // 首次创建播放器实例
            initializePlayer()
        }
    }
    
    // 初始化音频播放器
    private func initializePlayer() {
        do {
            // 配置音频会话，允许后台播放
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // 加载音频文件
            if let audioPath = Bundle.main.path(forResource: audioFileName, ofType: audioFileType) {
                let audioURL = URL(fileURLWithPath: audioPath)
                audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                audioPlayer?.numberOfLoops = -1 // 设置循环播放
                audioPlayer?.play()
                isPlaying = true
            } else {
                print("无法找到音频文件 \(audioFileName).\(audioFileType)")
            }
        } catch {
            print("音频播放错误: \(error.localizedDescription)")
        }
    }
    
    // 停止播放并释放资源
    func stopAndRelease() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("音频会话关闭错误: \(error.localizedDescription)")
        }
    }
}