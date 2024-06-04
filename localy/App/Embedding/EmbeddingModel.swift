//
//  EmbeddingModel.swift
//  localy
//
//  Created by nathan ranchin on 03/06/2024.
//

import Hub
import CoreML
import Tokenizers
import Foundation

class EmbeddingInput: MLFeatureProvider {
    var input_ids: MLMultiArray
    var mask: MLMultiArray
    
    var featureNames: Set<String> {
        get {
            return ["input_ids", "mask"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "input_ids") {
            return MLFeatureValue(multiArray: input_ids)
        }
        if (featureName == "mask") {
            return MLFeatureValue(multiArray: mask)
        }
        return nil
    }
    
    init(input_ids: MLMultiArray, mask: MLMultiArray) {
        self.input_ids = input_ids
        self.mask = mask
    }
    
    convenience init(input_ids: [Int], mask: [Int]) throws {
        let shape: [NSNumber] = [1, NSNumber(value: input_ids.count)]
        
        let inputIdsMLMultiArray = try MLMultiArray(shape: shape, dataType: MLMultiArrayDataType.int32)
        for i in 0..<input_ids.count {
            inputIdsMLMultiArray[i] = NSNumber(value: input_ids[i])
        }
        
        let maskMLMultiArray = try MLMultiArray(shape: shape, dataType: MLMultiArrayDataType.float16)
        for i in 0..<mask.count {
            maskMLMultiArray[i] = NSNumber(value: mask[i])
        }
        
        self.init(input_ids: inputIdsMLMultiArray, mask: maskMLMultiArray)
    }
}

class CosimInput: MLFeatureProvider {
    var query: MLMultiArray
    var files: MLMultiArray
    
    var featureNames: Set<String> {
        get {
            return ["query", "files"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "query") {
            return MLFeatureValue(multiArray: query)
        }
        if (featureName == "files") {
            return MLFeatureValue(multiArray: files)
        }
        return nil
    }
    
    init(query: MLMultiArray, files: MLMultiArray) {
        self.query = query
        self.files = files
    }
}

class EmbeddingModel {
    var model: MLModel? = nil
    var cosim: MLModel? = nil
    var splitter: Splitter? = nil
    
    static let repoID: String = "silvainrichou/localy"
    
    func loadModel(downloadBase: URL, modelName: String, callback: ((Progress) -> Void)?) async {
        if !FileManager.default.fileExists(atPath: downloadBase.appending(path: EmbeddingModel.repoID).appending(path: modelName).path()) {
            let embeddingRepo = Hub.Repo(id: EmbeddingModel.repoID, type: .models)
            try! await HubApi().snapshot(from: embeddingRepo, matching: ["*\(modelName)/*"]) { progress in
                callback?(progress)
            }
        }

        let modelURL = downloadBase.appending(path: EmbeddingModel.repoID).appending(path: modelName)
        let config = LanguageModelConfigurationFromHub(modelFolder: modelURL.appending(path: "tokenizer"))
        let tokenizer = try! await BertTokenizer(tokenizerConfig: config.tokenizerConfig!, tokenizerData: config.tokenizerData, addedTokens: [:])
        
        self.splitter = DefaultSplitter(tokenizer: tokenizer)
        self.model = try! MLModel(contentsOf: modelURL.appending(path: "model.mlmodelc"))
        self.cosim = try! MLModel(contentsOf: modelURL.appending(path: "cosim.mlmodelc"))
    }
    
    func embed(text: String) -> ([String], MLMultiArray) {
        let chunks = self.splitter!.split(text: text)
        
        return embed(chunks: chunks)
    }
    
    func embed(chunks: [String]) -> ([String], MLMultiArray) {
        var embeddings: [MLMultiArray] = []
        
        let (inputs_ids, masks) = self.splitter!.tokenize(chunks: chunks)
        for (input_ids, mask) in zip(inputs_ids, masks) {
            let output = try! self.model!.prediction(from: EmbeddingInput(input_ids: input_ids, mask: mask))
            embeddings.append(output.featureValue(for: "outputs")!.multiArrayValue!)
        }
        
        return (chunks, MLMultiArray(concatenating: embeddings, axis: 0, dataType: MLMultiArrayDataType.float16))
    }
    
    func search(query: MLMultiArray, files: [MLMultiArray]) -> [Int] {
        let filesMLMultiArray = MLMultiArray(concatenating: files, axis: 0, dataType: MLMultiArrayDataType.float16)
        let outputs = try! cosim!.prediction(from: CosimInput(query: query, files: filesMLMultiArray))
        
        let similarities = outputs.featureValue(for: "outputs")!.multiArrayValue!
        var similaritiesArray = [Float](repeating: 0, count: similarities.count)
        
        for i in 0..<similarities.count {
            similaritiesArray[i] = similarities[i].floatValue
        }
        
        return Array(similaritiesArray.enumerated().map({ ($0.element, $0.offset) }).sorted(by: { a, b in a.0 > b.0 }).map({ $0.1 }))
    }
}
