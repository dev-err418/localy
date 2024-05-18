//
//  Reformulation.swift
//  lookup
//
//  Created by arthur on 09/05/2024.
//

import SwiftUI

struct Reformulation: View {
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("Reformulate command")
                        .font(.system(size: 15, weight: .bold))
                    GroupBox {
                        Text("/r")
                            .font(.system(size: 15, weight: .bold))
                            .padding(.horizontal, 4)
                    }
                }
                Divider()
                    .padding(.vertical, 12)
                
                Text("This command is made to reformulate text in your clip board. Simply compy some text and run the command without arguments. If an argument is provided, it will be the one reformulated. The answer will also be copied in your clipboard.")
                
                Divider()
                    .padding(.vertical, 12)
                
                Text("Usages :")
                GroupBox {
                    Text("/r")
                        .padding(.horizontal, 4)
                }
                GroupBox {
                    Text("/r The artificial intelligence system indexed all my documents.")
                        .padding(.horizontal, 4)
                }
                HStack {
                    GroupBox {
                        Text("/r polite ...")
                            .padding(.horizontal, 4)
                    }
                    Text("You could also provide an argument to precise the reformulation.")
                }
                
            }
        }.padding(16)
    }

}

#Preview {
    Reformulation()
}
