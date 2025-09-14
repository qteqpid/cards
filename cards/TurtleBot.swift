
import SwiftUI
import Combine
import Foundation

enum BotState {
    case isWaiting
    case isThinking
    case isSpeaking
}

class TurtleBot: ObservableObject {
    // 单例实例
    static let shared = TurtleBot()
    
    @Published var botState = BotState.isWaiting
    @Published var userInput = "" // 存储识别到的文本
    @Published var fullResponseText = "" // 存储完整的回复文本
    @Published var displayedText = "" // 用于打字机效果的显示文本
    
    init() {}
    
    func thinkAndReply(_ userInput: String) {      
        self.switchState(state: .isThinking)
        self.displayedText = ""
        // 思考并获取回复
        let response = self.think(userInput)
        // 添加延迟，在回答前停几秒
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 播放回复
            self.speak(response)
        }
    }
    
    func speak(_ response: String, withMute: Bool = false) {
        switchState(state: .isSpeaking)
        //print("要说话了："+response)
        self.fullResponseText = response
        
        // 将状态设置为回答，显示回答气泡
        self.displayedText = "" // 清空显示文本，准备打字机效果
        
        // 实现打字机效果 - 按标点符号分词
        let segments = getSegments(response: response)
        var currentIndex = 0
        // 定时器，每隔一定时间显示一个分句
        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) {
            [weak self] timer in
            guard let self = self else { return }
            
            if currentIndex < segments.count {
                // 添加当前分句到显示文本
                self.displayedText += segments[currentIndex]
                currentIndex += 1
            } else {
                // 所有分句都显示完了，停止定时器
                timer.invalidate()
            }
        }
        
        switchState(state: .isWaiting)
    }

    private func think(_ userInput: String) -> String {
        switchState(state: .isThinking)
        if let userInput = self.userInput as String? {
            // 调用SkillFactory处理文本并获取响应
            return userInput
        } else {
            return "我没听清你说的话"
        }
    }

    private func switchState(state: BotState) {
        self.botState = state
        //print("切换状态为：\(state)")
    }

    private func getSegments(response: String) -> [String] {
        // 实现打字机效果 - 按标点符号分词
        // 分割正则表达式：匹配中文和英文的标点符号
        let pattern = "([。！？,，.!?；；;:：])"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        
        // 将文本按标点符号分割，保留标点符号
        var segments: [String] = []
        if let regex = regex {
            let matches = regex.matches(in: response, options: [], range: NSRange(location: 0, length: response.utf16.count))
            
            if matches.isEmpty {
                // 如果没有匹配到标点符号，就整个作为一段
                segments = [response]
            } else {
                var lastRangeEnd = 0
                
                for match in matches {
                    let matchRange = match.range(at: 0)
                    let matchStart = matchRange.location
                    
                    // 添加标点符号前的文本
                    if matchStart > lastRangeEnd {
                        let textRange = NSRange(location: lastRangeEnd, length: matchStart - lastRangeEnd)
                        if let substring = Range(textRange, in: response) {
                            if let sep = Range(matchRange, in: response) { // 句子+标点
                                segments.append(String(response[substring])+String(response[sep]))
                            } else {
                                segments.append(String(response[substring]))
                            }     
                        }
                    }
                    lastRangeEnd = matchStart + matchRange.length
                }
                
                // 添加最后一个标点符号后的文本（如果有的话）
                if lastRangeEnd < response.utf16.count {
                    let textRange = NSRange(location: lastRangeEnd, length: response.utf16.count - lastRangeEnd)
                    if let substring = Range(textRange, in: response) {
                        segments.append(String(response[substring]))
                    }
                }
            }
        } else {
            // 如果正则表达式创建失败，就整个作为一段
            segments = [response]
        }
        return segments
    }

    
}

// 为String添加扩展，实现正则表达式匹配功能
extension String {
    func matches(pattern: String) -> Bool {
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: self)
    }
}
