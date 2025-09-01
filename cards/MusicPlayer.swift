import AVFoundation

class MusicPlayer: ObservableObject {
    @Published var isPlaying = false
    private var audioPlayer: AVAudioPlayer?
    private let audioFileName = "bg_audio"
    private let audioFileType = "m4a"
    
    // 单例模式，确保整个应用中只有一个音乐播放器实例
    static let shared = MusicPlayer()
    
    // 私有初始化方法，防止外部创建实例
    private init() {}
    
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