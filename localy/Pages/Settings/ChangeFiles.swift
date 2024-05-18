//
//  ChangeFiles.swift
//  lookup
//
//  Created by arthur on 09/05/2024.
//

import SwiftUI

struct ChangeFiles: View {
    
    let manager = BookmarkManager.manager
    
    @State private var showFileImporter = false
    @State private var selectedPath = UserDefaults.standard.string(forKey: "path")
    
    var body: some View {
        ZStack {
            VStack {
                Button("Choose path") {
                    showFileImporter.toggle()
                }
                Text(selectedPath ?? "No path provided")
                Button("Print folder content") {                    
                    self.embed()
                }
            }
        }
        .onAppear {
            manager.loadBookmarks()
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.directory], onCompletion: { result in
            // TODO
            switch result {
            case .success(let files):
                print(files.path(percentEncoded: true))
                
                guard files.startAccessingSecurityScopedResource() else {
                    print("no rights to access")
                    return
                }
                
                manager.saveBookmark(for: files)
                
                self.selectedPath = files.path
                UserDefaults.standard.set(files.path, forKey: "path")
                
                do { files.stopAccessingSecurityScopedResource() }
                
            case .failure(let error):
                print(error)
            }
        })
    }
    
    func embed() {
        guard let selectedPath = self.selectedPath else {
            print("No path selected")
            return
        }
        
        guard let url = URL(string: selectedPath) else {
            // Handle the failure here.
            print("Invalid URL")
            return
        }
        
        print(url)
        
        let fm = FileManager.default
        
        do {
            let items = try fm.contentsOfDirectory(atPath: selectedPath)
            for item in items {
                var p = url
                p.appendPathComponent(item)
                let content = try String(contentsOfFile: p.path)
                print(content)
            }
        } catch let error as NSError {
            // failed to read directory – bad permissions, perhaps?
            print(error)
            print("bad permissions")
        }

    }
}
