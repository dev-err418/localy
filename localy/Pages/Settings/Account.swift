//
//  Account.swift
//  lookup
//
//  Created by arthur on 15/05/2024.
//

import SwiftUI

struct Account: View {
    
    @State private var email: String = ""
    @StateObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            VStack {
                AppleSignIn(authViewModel: authViewModel)
                Button("signin test") {
                    Task {
                        await authViewModel.signInTest()
                    }
                }
                Button("logout") {
                    Task {
                        await authViewModel.signOut()
                    }
                }
                Button("query") {
                    Task {
                        await authViewModel.queryWeb(query: "Who won the last NBA match")
                    }
                }
                if authViewModel.isQueryLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
    }
}
