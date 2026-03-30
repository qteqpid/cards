import Foundation
import SwiftUI

// Bot配置结构体
struct BotConfig {
    let apiKey: String
    let url: String
    let model: String
}

// Bot配置列表
private let botConfigs: [BotConfig] = [
    BotConfig(
        apiKey: "sk-918b269d28dd4585b4608291339491ae",
        url: "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
        model: "qwen3.5-plus"
    ),
    BotConfig(
        apiKey: "sk-918b269d28dd4585b4608291339491ae",
        url: "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
        model: "qwen3.5-flash-2026-02-23"
    ),
    BotConfig(
        apiKey: "sk-918b269d28dd4585b4608291339491ae",
        url: "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
        model: "qwen3.5-plus-2026-02-15"
    ),
    BotConfig(
        apiKey: "sk-918b269d28dd4585b4608291339491ae",
        url: "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
        model: "qwen3.5-27b"
    ),
    BotConfig(
        apiKey: "sk-918b269d28dd4585b4608291339491ae",
        url: "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
        model: "qwen3.5-122b-a10b"
    ),
    BotConfig(
        apiKey: "sk-918b269d28dd4585b4608291339491ae",
        url: "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
        model: "qwen3.5-397b-a17b"
    ),
    BotConfig(
        apiKey: "265138820d1c4bd2909506540624b718.LroRUoYiWbojTMWG",
        url: "https://open.bigmodel.cn/api/paas/v4/chat/completions",
        model: "glm-4.6v-flash"
    )
]

// 定义Bot协议
protocol BotProtocol {
    func request(messages: [[String: Any]]) async throws -> Data
    func parseResponse(_ data: Data) throws -> JudgeBot.RefereeResult
}

class JudgeBot: ObservableObject {
    private let bots: [BotProtocol]
    @Published var isGuessing = false
    
    struct RefereeResult: Codable {
        let answer: String
    }
    
    init() {
        // 遍历配置列表生成Bot实例
        self.bots = botConfigs.compactMap { config in
            guard let url = URL(string: config.url) else {
                print("Invalid URL for \(config.model): \(config.url)")
                return nil
            }
            //print("创建Bot实例: \(config.model)")
            return BaseBot(
                apiKey: config.apiKey,
                url: url,
                model: config.model
            )
        }
    }
    
    func guess(userInput: String, card: Card, conversationHistory: [Message]) async throws -> RefereeResult {
        // 设置isGuessing为true
        DispatchQueue.main.async {
            self.isGuessing = true
        }
        
        // 生成共用的messages
        let messages = generateMessages(card: card, conversationHistory: conversationHistory, userInput: userInput)
        
        // 随机打乱bot顺序
        let shuffledBots = bots.shuffled()
        
        // 轮询调用各个bot
        var lastError: Error?
        for bot in shuffledBots {
            do {
                let data = try await bot.request(messages: messages)
                let result = try bot.parseResponse(data)
                
                // 设置isGuessing为false
                DispatchQueue.main.async {
                    self.isGuessing = false
                }
                
                return result
            } catch {
                print("Bot调用失败: \(error)")
                lastError = error
                // 继续尝试下一个bot
            }
        }
        
        // 所有bot都失败了
        DispatchQueue.main.async {
            self.isGuessing = false
        }
        
        throw lastError ?? NSError(domain: "JudgeBotError", code: 500, userInfo: [NSLocalizedDescriptionKey: "所有模型调用失败"])
    }
    
    // 生成共用的messages
    private func generateMessages(card: Card, conversationHistory: [Message], userInput: String) -> [[String: Any]] {
        return [
            ["role": "system", "content": """
            Role: 海龟汤（侧向思维游戏）裁判员

            Context
            海龟汤是一种通过“是/不是/不相关”提问来推导离奇事件真相的游戏。你作为裁判，掌握着唯一的真相。

            Current Game Information
            【题目】：\(card.front.description ?? "")
            【答案】：\(card.back.description ?? "")
            【标签】：\(card.labels?.joined(separator: ",") ?? "")

            Task
            根据提供的【题目】、【答案】和【标签】，对玩家的【猜测】进行严格评审。

            Rules & Constraints
            1. **核心回答限制**：你只能输出以下四个词之一：
               - "是"：猜测符合真相逻辑。
               - "不是"：猜测与真相矛盾。
               - "不相关"：猜测对真相的推导没有帮助或无关痛痒或真相中没提到的细节（且不影响主干）。
               - "成功"：当玩家通过一系列提问，还原了真相的一半以上的关键要素（包括：起因、经过、结果、关键转折点）。
            2. **特殊回复：提示**：
               - 如果玩家显式要求“提示”，或者连续 5 次获得“不是”或“不相关”的回应，你必须给出提示。
               - 提示必须以“提示：”开头。
               - 提示原则：渐进式启发。先提示“范围”（如：关注时间点），再提示“动作”，最后提示“逻辑矛盾点”。严禁直接透露真相。
            3. **输出格式**：必须严格遵循 JSON 格式：
               {
                 "answer": "是/不是/不相关/提示：..."
               }
            4. **语气与风格**：思路部分应专业冷静；“回答”部分严禁出现多余文字或标点。
            """]
        ] + convertHistoryToMessages(conversationHistory) + [
            ["role": "user", "content": "\(userInput)"]
        ]
    }
    
    // 将conversationHistory转换为role为user和assistant的消息数组
    private func convertHistoryToMessages(_ history: [Message]) -> [[String: String]] {
        var messages: [[String: String]] = []
        
        for message in history {
            if !message.isUser, let userInput = message.userInputForJudge {
                // 添加用户输入作为user角色的消息
                messages.append(["role": "user", "content": userInput])
                // 添加助手回复作为assistant角色的消息
                messages.append(["role": "assistant", "content": message.content])
            }
        }
        
        return messages
    }
}

// 基础OpenAI Bot实现
class BaseBot: BotProtocol {
    private let apiKey: String
    private let url: URL
    private let model: String
    
    init(apiKey: String, url: URL, model: String) {
        self.apiKey = apiKey
        self.url = url
        self.model = model
    }
    
    func request(messages: [[String: Any]]) async throws -> Data {
        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "response_format": ["type": "json_object"]
        ]

        //print("begin request \(model) \(body)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
    
    func parseResponse(_ data: Data) throws -> JudgeBot.RefereeResult {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        //print("curl response \(model): \(json)")

        if let error = json?["error"] as? [String: Any] {
            let errorCode = error["code"] as? Int ?? 0
            let errorMessage = error["message"] as? String ?? "未知错误"
            throw NSError(domain: "\(model) BotError", code: errorCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        guard let choices = json?["choices"] as? [[String: Any]],
              let content = choices.first?["message"] as? [String: Any],
              let contentString = content["content"] as? String,
              let contentData = contentString.data(using: .utf8) else {
            throw NSError(domain: "\(model) BotError", code: 500, userInfo: [NSLocalizedDescriptionKey: "响应格式错误"])
        }
        
        return try JSONDecoder().decode(JudgeBot.RefereeResult.self, from: contentData)
    }
}
