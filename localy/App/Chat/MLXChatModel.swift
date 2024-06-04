//
//  MLXChatModel.swift
//  localy
//
//  Created by nathan ranchin on 04/06/2024.
//

import Hub
import MLXLLM
import Tokenizers
import Foundation

class MLXChatModel: ChatModel {
    var model: LLMModel? = nil
    var tokenizer: Tokenizer? = nil
    var chatModelConfiguration: ChatModelConfiguration
    
    init(chatModelConfiguration: ChatModelConfiguration) {
        self.chatModelConfiguration = chatModelConfiguration
    }
    
    func asyncGenerate(prompt: String, callback: @escaping (String) -> Void) async {
        let prompt = chatModelConfiguration.modelConfiguration!.prepare(prompt: prompt)
        let promptTokens = tokenizer!.encode(text: prompt)
        
        let generationResult = await MLXLLM.generate(promptTokens: promptTokens, parameters: GenerateParameters(), model: model!, tokenizer: tokenizer!) { tokens in
            if tokens.count % chatModelConfiguration.displayEvery == 0 {
                let text = tokenizer!.decode(tokens: tokens)
                callback(text)
            }
            
            return tokens.count < chatModelConfiguration.maxTokens ? .more : .stop
        }
    }
    
    func loadModel(downloadBase: URL, chatModelConfiguration: ChatModelConfiguration, callback: ((Progress) -> Void)?) async {
        if !FileManager.default.fileExists(atPath: downloadBase.appending(path: chatModelConfiguration.modelConfiguration!.name).path()) {
            let chatRepo = Hub.Repo(id: chatModelConfiguration.modelConfiguration!.name, type: .models)
            try! await HubApi().snapshot(from: chatRepo, matching: ["*"]) { progress in
                callback?(progress)
            }
        }
        
        (self.model, self.tokenizer) = try! await MLXLLM.load(configuration: chatModelConfiguration.modelConfiguration!)
    }
}
