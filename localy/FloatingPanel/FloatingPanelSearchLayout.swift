//
//  FloatingPanelSearchLayout.swift
//  lookup
//
//  Created by arthur on 09/05/2024.
//

import SwiftUI

public protocol SearchItem: Identifiable, Equatable {
    var id: ID { get }
    var name: String { get }
    var icon: String { get }
    var section: SearchItemSection { get }
}

public struct SearchItemSection: Identifiable, Equatable, Hashable {
    public init(name: String) {
        self.name = name
    }
    
    public let id = UUID()
    var name: String
}

public struct FloatingPanelSearchLayout<Item: SearchItem, ItemView: View, DetailsView: View>: View {
    @Binding var items: [Item]
    
    @ViewBuilder let itemView: (Item, Binding<Item?>, Bool, SearchItemSection) -> (ItemView)
    @ViewBuilder let detailsView: (Binding<Item?>) -> (DetailsView)
        
    @State private var selectedItem: Item?
    
    @FocusState private var isFocused: Bool
    
    @StateObject var appState = AppState.shared
    @StateObject var authViewModel: AuthViewModel
    
    var prompt: String = "Browse"
    
    var sections: [SearchItemSection] {
        var unique = [SearchItemSection]()
        for section in items.map({ $0.section }) {
            if !unique.contains(section) {
                unique.append(section)
            }
        }
        return unique
    }
    
    var filteredItems: [Item] {
        if appState.query.isEmpty {
            // Don't filter if the query is empty
            return items
        } else {
            let queryPrefix = String(appState.query.prefix(2)) // Obtenir les deux premiers caractères de la query
            return items.filter { item in
                if item.section.name == "AI" {
                    // Si la section est "Commands", ne garder que les items dont le nom commence par les deux premiers caractères de la query
                    return item.name.hasPrefix(queryPrefix)
                } else {
                    // Pour les autres sections, filtrer par nom et nom de section, sans tenir compte de la casse
                    return item.name.range(of: appState.query, options: .caseInsensitive) != nil || item.section.name.range(of: appState.query, options: .caseInsensitive) != nil
                }
            }
        }
    }
    
    var shortcuts: some View {
        ZStack {
            Button(action: {
                jump(amount: 1)
            }, label: {})
            .keyboardShortcut(.downArrow, modifiers: [])
            
            Button(action: {
                jump(amount: -1)
            }, label: {})
            .keyboardShortcut(.upArrow, modifiers: [])
            
            Button(action: {
                enterPressed()
            }, label: {})
            .keyboardShortcut(.defaultAction)
        }
        .opacity(0.0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
    
    public var body: some View {
        ZStack {
            Text("yo")
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow, state: .followsWindowActiveState, emphasized: true)
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Image(systemName: "command")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .offset(x: 0, y: 1)
                    TextField(prompt, text: $appState.query)
                        .textFieldStyle(.plain)
                        .font(.system(size: 26, weight: .regular))
                        .onChange(of: appState.query) {
                            // Whenever the query updates, update the selected item too
                            selectedItem = filteredItems.first
                        }
                        .focused($isFocused)
                        .onAppear {
                            self.isFocused = true
                        }
                    switch (authViewModel.authState) {
                    case .Initial:
                        ProgressView()
                            .controlSize(.small)                        
                    case .SignIn:
                        Circle()
                            .fill(Color(.systemGreen))
                            .opacity(0.5)
                            .offset(x: 4, y: -16)
                            .frame(width: 8, height: 8)
                    case .SignOut:
                        Circle()
                            .fill(Color(.systemRed))
                            .opacity(0.5)
                            .offset(x: 4, y: -16)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(16)
                
                Divider()
                
                HStack(spacing: 0) {
                    VStack {
                        //Spacer()
                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack() {
                                    ForEach(sections) { section in
                                        let items = filteredItems(in: section)
                                        
                                        // Only show section if it has any items
                                        if !items.isEmpty {
                                            let selected = section == selectedItem?.section
                                            
                                            VStack() {
                                                // Section title
                                                Text(section.name.uppercased())
                                                    .font(.system(size: selected ? 15 : 14, weight: .bold))
                                                    .foregroundStyle(selected ? .secondary : .tertiary)
                                                    .frame(width: 256.0 - 16.0, height: 15, alignment: .leading)
                                                    .padding(.top, 8)
                                                
                                                // Section items
                                                ForEach(0..<items.count, id: \.self) { itemIndex in
                                                    let item = items[itemIndex]
                                                    itemView(item, $selectedItem, selectedItem == item, section)
                                                        .id(itemIndex)
                                                        .onTapGesture {
                                                            selectedItem = item
                                                        }                                                        
                                                    // to try to auto scroll
                                                        .onChange(of: selectedItem) {
                                                            proxy.scrollTo(filteredItems.firstIndex(of: selectedItem!)!, anchor: .bottom)
                                                        }
                                                }
                                            }.frame(width: 256.0 - 16.0)
                                            .padding(.vertical, 8)
                                        }
                                    }
                                }
                            }
                        }.background(shortcuts)
                            .onAppear {
                                selectedItem = filteredItems.first
                            }
                        // if we set the animation, the image will rerender...
                            //.animation(.spring(response: 0.2, dampingFraction: 0.85), value: selectedItem)
                            .frame(maxWidth: 256.0)
                    }
                    HStack(spacing: 0) {
                        Divider()
                        detailsView($selectedItem)
                            .frame(width: 800.0 - 256.0)
                    }
                }
            }
        }.task {            
            await authViewModel.isUserSignIn()
        }
    }
    
    func filteredItems(in section: SearchItemSection) -> [Item] {
        filteredItems.filter({ return $0.section == section })
    }
    
    func jump(amount: Int) {
        if let selectedItem = selectedItem {
            if let index = filteredItems.firstIndex(of: selectedItem) {
                if filteredItems.indices.contains(index + amount) {
                    self.selectedItem = filteredItems[index + amount]
                }
            }
        } else {
            selectedItem = filteredItems.first
        }
    }
    
    func enterPressed() {
        if self.selectedItem?.section.name == "Apps" {
            let url = NSURL(fileURLWithPath: self.selectedItem!.icon)
            NSWorkspace.shared.openApplication(at: url as URL, configuration: .init(), completionHandler: nil)
            print(url)
        }
    }
}
