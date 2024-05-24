//
//  Account.swift
//  lookup
//
//  Created by arthur on 15/05/2024.
//

import SwiftUI

struct Account: View {
    
    @State private var email: String = ""
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            VStack {
                /*AppleSignIn(authViewModel: authViewModel)*/
                if authViewModel.authState == .SignIn {
                    
                    /*Button("logout") {
                        Task {
                            await authViewModel.signOut()
                        }
                    }*/
                    Button("access account online") {
                        Task {
                            // [access_token, refresh_token]
                            let tokens = await authViewModel.isUserSignIn()
                            let uri = "https://localy.vercel.app/auth?access=" + tokens[0] + "&refresh=" + tokens[1]
                            if let url = URL(string: uri) {                                
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }
                } else {
                    Button("signin test") {
                        Task {
                            await authViewModel.signInTest()
                        }
                    }
                }
            }
        }
    }
}
