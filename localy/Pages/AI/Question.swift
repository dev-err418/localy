//
//  Question.swift
//  lookup
//
//  Created by arthur on 09/05/2024.
//

import SwiftUI

struct Question: View {
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("Query command")
                        .font(.system(size: 15, weight: .bold))
                    GroupBox {
                        Text("/q")
                            .font(.system(size: 15, weight: .bold))
                            .padding(.horizontal, 4)
                    }
                }
                Divider()
                    .padding(.vertical, 12)
                
                Text("This command is made to query the AI on your files or for general questions. It could be use on local or remote, depending on your settings (current settings : local).")
                
                Divider()
                    .padding(.vertical, 12)
                
                Text("Usages :")
                GroupBox {
                    Text("/q What are the main parts of a business plan ?")
                        .padding(.horizontal, 4)
                }
                GroupBox {
                    Text("/q Find documents mentioning 'project proposal' from last quarter ?")
                        .padding(.horizontal, 4)
                }
                
            }
        }.padding(16)
    }
}
