//
//  ChatModel.swift
//  localy
//
//  Created by nathan ranchin on 03/06/2024.
//

import MLXLLM
import Tokenizers
import Foundation

struct ChatModelConfiguration {
    var maxTokens: Int
    var displayEvery: Int
    var systemPrompt: String
    var modelConfiguration: ModelConfiguration? = nil
}

protocol ChatModel {
    var model: LLMModel? { get }
    var tokenizer: Tokenizer? { get }
    var chatModelConfiguration: ChatModelConfiguration { get }
    func asyncGenerate(prompt: String, callback: @escaping (String) -> Void) async
    func generate(prompt: String, callback: @escaping (String) -> Void)
    func loadModel(downloadBase: URL, chatModelConfiguration: ChatModelConfiguration, callback: ((Progress) -> Void)?) async
}

extension ChatModel {
    func generate(prompt: String, callback: @escaping (String) -> Void) {
        Task { await asyncGenerate(prompt: prompt, callback: callback) }
    }
}
