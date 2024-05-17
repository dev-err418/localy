//
//  ContentView.swift
//  lookup
//
//  Created by arthur on 09/05/2024.
//

import SwiftUI

let ai = SearchItemSection(name: "AI")
let settings = SearchItemSection(name: "Settings")
let apps = SearchItemSection(name: "Apps")

struct ContentView: View {
    
    @State private var commands_list: [Command] = [
        .init(name: "Account", icon: "person.crop.circle.fill", section: settings),
        .init(name: "Change files", icon: "gear", section: settings),
        .init(name: "/q Ask questions", icon: "command", section: ai),
        .init(name: "/r Reformulate", icon: "command", section: ai),
        .init(name: "/s Summarize", icon: "command", section: ai),
    ]
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        FloatingPanelSearchLayout(items: $commands_list, itemView: { item, selectedItem, currentlySelected, section in
            HStack {
                section.name == "Apps" ? Image(nsImage: NSWorkspace.shared.icon(forFile: item.icon))
                :
                Image(systemName: item.icon)
                
                if section.name == "AI" {
                    Text(item.name.dropFirst(2))
                    GroupBox {
                        Text(item.name.prefix(2))
                            .padding(.horizontal, 4)
                    }
                } else {
                    Text(item.name)
                }
                
            }
            .id(item.id)
            .frame(maxWidth: .infinity, maxHeight: 20, alignment: .leading)
            .padding(8)
            .background(
                currentlySelected ?
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color(nsColor: .unemphasizedSelectedContentBackgroundColor)) :
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.clear)
            )
            .contentShape(Rectangle())
        }, detailsView: { command in
            if let command = command.wrappedValue {
                if command.name.prefix(2) == "/q" {
                    Question()
                } else if command.name.prefix(2) == "/r" {
                    Reformulation()
                } else if command.name.prefix(2) == "/s" {
                    Summarize()
                } else if command.name == "Change files" {
                    ChangeFiles()
                } else if command.name == "Account" {
                    Account(authViewModel: authViewModel)
                } else {
                    Text("The currently selected thing is \(command.name).")
                }
            } else {
                Text("Nothing to see here...")
            }
        }, authViewModel: authViewModel, prompt: "Enter your query...")
        .onAppear {
            self.commands_list.append(contentsOf: self.enumerateAppsFolder().map { Command(name: $0.name, icon: $0.path, section: apps) })
        }
    }
    
    func enumerateAppsFolder() -> [AppInfo] {
        var appInfos = [AppInfo]()
        
        let fileManager = FileManager.default
        if let appsURL = fileManager.urls(for: .applicationDirectory, in: .localDomainMask).first {
            if let enumerator = fileManager.enumerator(at: appsURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants) {
                while let element = enumerator.nextObject() as? URL {
                    if element.pathExtension == "app" {
                        let appName = element.deletingPathExtension().lastPathComponent
                        let appPath = element.relativePath
                        let appInfo = AppInfo(name: appName, path: appPath)
                        appInfos.append(appInfo)
                    }
                }
            }
        }
        
        return appInfos
    }
}

class AppInfo {
    let name: String
    let path: String

    init(name: String, path: String) {
        self.name = name
        self.path = path
    }
}

struct Command: SearchItem {
    let id = UUID()
    let name: String
    let icon: String
    let section: SearchItemSection
}

