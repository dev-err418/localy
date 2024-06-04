//
//  FileSystem.swift
//  localy
//
//  Created by nathan ranchin on 02/06/2024.
//

import CoreML
import SwiftData
import Foundation

enum RestrictionLevel: Codable {
    case protected
    case normal
}

@Model
class PersistentMLMultiArray {
    var shape: [Int]
    var strides: [Int]
    var dataType: Int
    var data: Data
    
    init<T>(shape: [Int], strides: [Int], dataType: Int, buffer: UnsafeMutableBufferPointer<T>) {
        self.shape = shape
        self.strides = strides
        self.dataType = dataType
        self.data = Data(buffer: buffer)
    }
    
    convenience init(mlMultiArray: MLMultiArray) {
        self.init(
            shape: mlMultiArray.shape.map(\.intValue),
            strides: mlMultiArray.strides.map(\.intValue),
            dataType: mlMultiArray.dataType.rawValue,
            buffer: mlMultiArray.withUnsafeMutableBytes({ ptr, _ in
                ptr.bindMemory(to: Float16.self)
            })
        )
    }
    
    public func asMLMultiArray() -> MLMultiArray {
        let dataPointer = self.data.withUnsafeMutableBytes({ ptr in ptr.baseAddress })!
        let mlMultiArray = try! MLMultiArray(
            dataPointer: dataPointer,
            shape: self.shape.map({i in NSNumber(integerLiteral: i)}),
            dataType: MLMultiArrayDataType(rawValue: self.dataType)!,
            strides: self.strides.map({i in NSNumber(integerLiteral: i)})
        )
        
        return mlMultiArray
    }
}

@Model
class File {
    var url: URL
    var content: [String]
    var embeddings: PersistentMLMultiArray
    var restrictionLevel: RestrictionLevel
    
    init(url: URL, content: [String], embeddings: MLMultiArray, restrictionLevel: RestrictionLevel = .normal) {
        self.url = url
        self.content = content
        self.embeddings = PersistentMLMultiArray(mlMultiArray: embeddings)
        self.restrictionLevel = restrictionLevel
    }
}

class FileSystem {
    var context: ModelContext
    var container: ModelContainer
    var embeddingModel: EmbeddingModel
    
    static let downloadBase: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appending(path: "huggingface").appending(path: "models")
    
    init(embeddingModelName: String, callBack: ((Progress) -> Void)?) async {
        self.container = try! ModelContainer(for: File.self)
        self.context = ModelContext(self.container)
        self.embeddingModel = EmbeddingModel()
        
        await self.embeddingModel.loadModel(downloadBase: FileSystem.downloadBase, modelName: embeddingModelName, callback: callBack)
    }
    
    private func embedFile(path: URL, restrictionLevel: RestrictionLevel = .normal) {
        guard let fileContent = try? String(contentsOf: path) else { return }
        
        let (content, embeddings) = self.embeddingModel.embed(text: fileContent)
        self.context.insert(File(url: path, content: content, embeddings: embeddings, restrictionLevel: restrictionLevel))
    }
    
    func embedFile(paths: [URL], restrictionLevel: RestrictionLevel = .normal) {
        let _ = paths.map { path in embedFile(path: path) }
        try! self.context.save()
    }
}
