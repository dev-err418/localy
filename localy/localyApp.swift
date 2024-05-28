//
//  lookupApp.swift
//  lookup
//
//  Created by arthur on 09/05/2024.
//

import SwiftUI
import KeyboardShortcuts
import FileWatcher

extension KeyboardShortcuts.Name {
    static let openModal = Self("openModal", default: .init(.k, modifiers: [.command]))
}

@main
struct lookupApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("Menu Bar", systemImage: "eye") {
            ZStack {
                VStack {
                    Form {
                        KeyboardShortcuts.Recorder("Shortcut :", name: .openModal)
                    }
                }
            }.padding(16)
        }.menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var appState = AppState.shared
    var isPresented: Bool = true
    var newEntryPanel: FloatingPanel!
    var authModel = AuthViewModel()
    //var supabase = SupabaseAuth()
    
    //let filewatcher = FileWatcher([NSString(string: "~/Downloads").expandingTildeInPath])
    let manager = BookmarkManager.manager
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Launched")
        NSApplication.shared.activate(ignoringOtherApps: true)
                
        manager.loadBookmarks()
        
        createFloatingPanel()
        
        newEntryPanel.center()
        newEntryPanel.orderFront(nil)
        newEntryPanel.makeKey()
        
        // setup the global shortcut
        KeyboardShortcuts.onKeyUp(for: .openModal) {
            self.togglePanel()
        }

        //filewatcher.callback = { (event: FileWatcherEvent) in
        //    print("Something happened here: \(event.path)")
        //    Swift.print("event.description:  \(event.description)")
        //    if !FileManager().fileExists(atPath: event.path) { Swift.print("was deleted") }
        //    Swift.print("event.flags:  \(event.flags)")
        //}

        //filewatcher.queue = DispatchQueue.global()
        //filewatcher.start()
    }
    
    // this function is called when Cmd + q is called from the user
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // if panel on screen, hide it
        if (self.newEntryPanel.isVisible) {
            self.newEntryPanel?.close()
            self.newEntryPanel?.close()
            self.appState.query = ""
        }
        
        return .terminateCancel
    }
    
    private func createFloatingPanel() {
        newEntryPanel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 800, height: 512), backing: .buffered, defer: false)
    }
    
    private func togglePanel() {
        self.isPresented.toggle()
        self.appState.query = ""
        if (self.newEntryPanel.isVisible) {
            self.newEntryPanel?.close()
        } else {
            self.newEntryPanel?.orderFront(nil)
            self.newEntryPanel?.makeKey()
            Task {
                //try await supabase.LoginUser()
                print("checking")
                await authModel.isUserSignIn()
            }
        }
    }
}

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var query = ""
}
