//
//  GroqChatModel.swift
//  localy
//
//  Created by nathan ranchin on 04/06/2024.
//

import MLXLLM
import Tokenizers
import Foundation

struct Query: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }
    let model = "llama3-8b-8192"
    let messages: [Message]
    let stream = true
    let max_tokens: Int
}

struct Chunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable {
            let role: String?
            let content: String?
        }
        let delta: Delta
    }
    let choices: [Choice]
}

class GroqChatModel: ChatModel {
    var model: LLMModel? = nil
    var authorizationToken: String
    var tokenizer: Tokenizer? = nil
    var chatModelConfiguration: ChatModelConfiguration
    
    init(model: LLMModel? = nil, authorizationToken: String, tokenizer: Tokenizer? = nil, chatModelConfiguration: ChatModelConfiguration) {
        self.model = model
        self.authorizationToken = authorizationToken
        self.tokenizer = tokenizer
        self.chatModelConfiguration = chatModelConfiguration
    }
    
    func asyncGenerate(prompt: String, callback: @escaping (String) -> Void) async {
        var request = URLRequest(url: URL(string: "https://api.groq.com/openai/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authorizationToken)", forHTTPHeaderField: "Authorization")
        
        let query = Query(messages: [.init(role: "system", content: chatModelConfiguration.systemPrompt), .init(role: "user", content: prompt)], max_tokens: chatModelConfiguration.maxTokens)
        request.httpBody = try! JSONSerialization.data(withJSONObject: query)
        
        let (bytes, response) = try! await URLSession.shared.bytes(for: request)
        
        do {
            var index: Int = 0
            var completion: String = ""
            for try await line in bytes.lines {
                completion += self.parseLine(line: line)
                
                if index % chatModelConfiguration.displayEvery == 0 {
                    callback(completion)
                }
                
                index += 1;
            }
        } catch { }
    }
    
    func parseLine(line: String) -> String {
        let components = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)
        guard components.count == 2, components[0] == "data" else { return "" }

        let message = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        
        if message == "[DONE]" {
            return ""
        } else {
            let chunk = try! JSONDecoder().decode(Chunk.self, from: message.data(using: .utf8)!)
            return chunk.choices.first?.delta.content ?? ""
        }
    }
    
    func loadModel(downloadBase: URL, chatModelConfiguration: ChatModelConfiguration, callback: ((Progress) -> Void)?) async { }
}
