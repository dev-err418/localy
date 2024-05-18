//
//  Summarize.swift
//  lookup
//
//  Created by arthur on 09/05/2024.
//

import SwiftUI

struct Summarize: View {
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("Summerize command")
                        .font(.system(size: 15, weight: .bold))
                    GroupBox {
                        Text("/s")
                            .font(.system(size: 15, weight: .bold))
                            .padding(.horizontal, 4)
                    }
                }
                Divider()
                    .padding(.vertical, 12)
                
                Text("This command is made to summerize text in your clip board. Simply compy some text and run the command without arguments. If an argument is provided, it will be the one summerized. The answer will also be copied in your clipboard.")
                
                Divider()
                    .padding(.vertical, 12)
                
                Text("Usages :")
                GroupBox {
                    Text("/s")
                        .padding(.horizontal, 4)
                }
                GroupBox {
                    Text("/s The large language model quickly processed my files.")
                        .padding(.horizontal, 4)
                }
                
            }
        }.padding(16)
    }

}

#Preview {
    Summarize()
}
