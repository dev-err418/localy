//
//  Splitter.swift
//  localy
//
//  Created by nathan ranchin on 03/06/2024.
//

import Tokenizers
import Foundation

protocol Splitter {
    var max_size: Int { get }
    var tokenizer: BertTokenizer { get }
    func split(text: String) -> [String]
    func tokenize(chunks: [String]) -> (inputs_ids: [[Int]], masks: [[Int]])
}

class DefaultSplitter: Splitter {
    var max_size: Int
    var tokenizer: BertTokenizer
    
    init(tokenizer: BertTokenizer) {
        self.max_size = 512
        self.tokenizer = tokenizer
    }
    
    func split(text: String) -> [String] {
        return [text]
    }
    
    func tokenize(chunks: [String]) -> (inputs_ids: [[Int]], masks: [[Int]]) {
        return (chunks.map { chunk in tokenizer.tokenize(text: chunk).map { token in tokenizer.convertTokenToId(token)! } }, [[Int]]())
    }
}
