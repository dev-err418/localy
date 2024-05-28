//
//  AuthViewModel.swift
//  lookup
//
//  Created by arthur on 17/05/2024.
//

import Foundation
import Supabase
import Combine

enum AuthState: Hashable {
    case Initial
    case SignIn
    case SignOut
}

class AuthViewModel: ObservableObject {    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String = ""
    @Published var authState: AuthState = AuthState.Initial
    @Published var isLoading = false
    
    var cancellable = Set<AnyCancellable>()
    
    private var supabaseAuth: SupabaseAuth = SupabaseAuth()        
    
    @MainActor
    func isUserSignIn() async -> [String] {
        do {
            // [access_token, refresh_token]
            let tokens = try await supabaseAuth.LoginUser()
            authState = AuthState.SignIn            
            return tokens
        } catch _ {
            authState = AuthState.SignOut
            return ["", ""]
        }
    }
    
    @MainActor
    func signIn(idToken: String) async {
        do {
            isLoading = true
            try await supabaseAuth.SignIn(idToken: idToken)
            authState = AuthState.SignIn
            isLoading = false
        } catch let error {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    @MainActor
    func signOut() async {
        do {
            try await supabaseAuth.SignOut()
            authState = AuthState.SignOut
        } catch let error {
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func queryWeb(query: String) async -> [Response] {
        do {
            let query = try await supabaseAuth.QueryWeb(query: query)
            return query
            
        } catch let error {
            errorMessage = error.localizedDescription            
        }
        
        return []
    }
    
    @MainActor
    func signInTest() async {
        do {
            isLoading = true
            try await supabaseAuth.LoginTest()
            authState = AuthState.SignIn
            isLoading = false
        } catch let error {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
