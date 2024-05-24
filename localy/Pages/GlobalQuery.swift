//
//  GlobalQuery.swift
//  localy
//
//  Created by arthur on 24/05/2024.
//

import SwiftUI

struct GlobalQuery: View {
    
    var queryContent: [Response]
    var isLoading: Bool
    
    var body: some View {
        ZStack {
            VStack {
                if !queryContent.isEmpty {
                    VStack {
                        HStack {
                            ForEach(queryContent.prefix(5), id: \.self) { q in
                                Button {
                                    if let url = URL(string: q.url) {
                                        NSWorkspace.shared.open(url)
                                    }
                                } label: {
                                    VStack(alignment: .leading) {
                                        // animation list
                                        Text(q.title)
                                            .font(.system(size: 10))
                                            .lineLimit(2)
                                        
                                        AsyncImage(url: URL(string: q.favicon)) { image in
                                            image.resizable()
                                        } placeholder: {
                                            Color.gray
                                        }
                                        .frame(width: 16, height: 16)
                                        .clipShape(.rect(cornerRadius: 4))
                                        .help(q.title)
                                    }.frame(width: 80, alignment: .leading)
                                    .padding(4)
                                    .background(.quaternary)
                                    .cornerRadius(4)
                                }.buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                } else {
                    if isLoading {
                        ProgressView()
                    } else {
                        HStack {
                            Image(systemName: "return")
                            Text("Press enter to run your query")
                        }
                    }
                }
            }
        }
    }
}
