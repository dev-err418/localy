//
//  AuthView.swift
//  lookup
//
//  Created by arthur on 15/05/2024.
//

import SwiftUI
import AuthenticationServices

struct AppleSignIn: View {
    
    @StateObject var authViewModel: AuthViewModel
    
    var body: some View {
        SignInWithAppleButton { request in
            request.requestedScopes = [.email, .fullName]
        } onCompletion: { result in
            Task {
                do {
                    guard let credential = try result.get().credential as? ASAuthorizationAppleIDCredential
                    else {
                        return
                    }
                    guard let idToken = credential.identityToken
                        .flatMap({ String(data: $0, encoding: .utf8) })
                    else {
                        return
                    }
                    await authViewModel.signIn(idToken: idToken)
                } catch {
                    dump(error)
                }
            }
        }
        .disabled(authViewModel.isLoading)
        .fixedSize()
        .signInWithAppleButtonStyle(.white)
    }
}
