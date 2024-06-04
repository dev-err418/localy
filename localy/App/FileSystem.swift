//
//  FileSystem.swift
//  localy
//
//  Created by nathan ranchin on 02/06/2024.
//

import CoreML
import SwiftData
import Foundation

struct FileChunk: Codable {
    let text: String
}

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
    var chunks: [FileChunk]
    var embeddings: PersistentMLMultiArray
    var restrictionLevel: RestrictionLevel
    
    init(url: URL, chunks: [FileChunk], embeddings: MLMultiArray, restrictionLevel: RestrictionLevel = .normal) {
        self.url = url
        self.chunks = chunks
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
    
    // This method support folders
    func embedFiles(urls: [URL], restrictionLevel: RestrictionLevel = .normal) {
        for url in urls {
            var paths = [URL]()
            
            paths.append(contentsOf: FileManager.default.subpaths(atPath: url.path())?.map({ sp in url.appending(path: sp)}) ?? [])
            if paths.count == 0 {
                paths.append(url)
            }
            let _ = paths.map { path in embedFile(path: path) }
        }
        try! self.context.save()
        
        let streamRef = FSEventStreamCreate(kCFAllocatorDefault, getFileWatcherCallback(), nil, urls as CFArray, FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 1, UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents))!
        
        FSEventStreamSetDispatchQueue(streamRef, DispatchQueue.main)
        FSEventStreamStart(streamRef)
    }
    
    func search(query: String, num_results: Int = 6) -> [FileChunk] {
        let (_, queryEmbeddings) = self.embeddingModel.embed(chunks: [query])
        let indices = self.embeddingModel.search(query: queryEmbeddings, files: files().map({ file in file.embeddings.asMLMultiArray() })).prefix(num_results)
        
        let files = files()
        var fileChunks = [FileChunk]()
        
        for index in indices {
            var i = index
            for file in files {
                i -= file.embeddings.shape[0]
                if (i < 0) {
                    fileChunks.append(file.chunks[i + file.embeddings.shape[0]])
                }
            }
        }
        
        return fileChunks
    }
    
    private func embedFile(path: URL, restrictionLevel: RestrictionLevel = .normal) {
        guard let fileContent = try? String(contentsOf: path) else { return }
        
        let (chunks, embeddings) = self.embeddingModel.embed(text: fileContent)
        self.context.insert(File(url: path, chunks: chunks.map { t in FileChunk(text: t) }, embeddings: embeddings, restrictionLevel: restrictionLevel))
    }
    
    private func files() -> [File] {
        return try! self.context.fetch(FetchDescriptor<File>(predicate: #Predicate { _ in true }))
    }
    
    private func getFileWatcherCallback() -> FSEventStreamCallback {
        return {(
            stream: ConstFSEventStreamRef,
            contextInfo: UnsafeMutableRawPointer?,
            numEvents: Int,
            eventPaths: UnsafeMutableRawPointer,
            eventFlags: UnsafePointer<FSEventStreamEventFlags>,
            eventIds: UnsafePointer<FSEventStreamEventId>
        ) in
            let paths = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue() as! [String]
            print(paths)
        }
    }
}
