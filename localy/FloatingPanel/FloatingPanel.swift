//
//  FloatingPanel.swift
//  lookup
//
//  Created by arthur on 09/05/2024.
//

import SwiftUI

private struct FloatingPanelKey: EnvironmentKey {
    static let defaultValue: NSPanel? = nil
}

extension EnvironmentValues {
  var floatingPanel: NSPanel? {
    get { self[FloatingPanelKey.self] }
    set { self[FloatingPanelKey.self] = newValue }
  }
}

class FloatingPanel: NSPanel {
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {        
        super.init(contentRect: contentRect, styleMask: [.nonactivatingPanel, .titled, .resizable, .closable, .fullSizeContentView], backing: backing, defer: flag)
        
        // Allow the pannel to be on top of almost all other windows
        self.isFloatingPanel = true
        self.level = .floating
        
        // Allow the pannel to appear in a fullscreen space
        self.collectionBehavior.insert(.fullScreenAuxiliary)
        
        // While we may set a title for the window, don't show it
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        
        // Since there is no titlebar make the window moveable by click-dragging on the background
        self.isMovableByWindowBackground = true
        
        // Keep the panel around after closing since I expect the user to open/close it often
        self.isReleasedWhenClosed = false
        
        // Warning do not set this to true, otherwise you wont be able to call it back
        // self.hidesOnDeactivate = true
        
        // Hide the traffic icons (standard close, minimize, maximize buttons)
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
        
        self.animationBehavior = .default
        self.isOpaque = false
                
        self.contentView = NSHostingView(rootView: ContentView()
            .ignoresSafeArea()
            .environment(\.floatingPanel, self)
        )                
    }
    
    override func resignMain() {
        super.resignMain()
        self.close()
    }
    
    // `canBecomeKey` and `canBecomeMain` are required so that text inputs inside the panel can receive focus
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}
