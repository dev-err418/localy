//
//  Supabase.swift
//  lookup
//
//  Created by arthur on 15/05/2024.
//

import Supabase
import Foundation

struct Response: Decodable, Hashable {
    let title: String
    let url: String
    let age: String?
    let content: String
    let favicon: String
}

class SupabaseAuth {
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://cwhqudvcynincccneemq.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3aHF1ZHZjeW5pbmNjY25lZW1xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTYyODg3NDUsImV4cCI6MjAzMTg2NDc0NX0.DH3fCT-Wl77qUJLnqvY0pCLLh1yuYRkjvZJOdPHF7IY"
    )
    
    func QueryWeb(query: String) async throws -> [Response] {
        do {
            let response = try await client.functions.invoke(
                "query-web",
                options: FunctionInvokeOptions(
                    region: .euWest1, // optional parameter, only used here to lower latency in France
                    body: ["query": query]
                ),
                decode: { data, response in
                    String(data: data, encoding: .utf8)
                }
            )
            //print(response[0].title)
            let data = response!.data(using: .utf8)!
            let decoder = JSONDecoder()

            do {
                let jsonArray = try decoder.decode([Response].self, from: data)                
                return jsonArray
            } catch {
                print("Error decoding JSON: \(error)")
            }
        } catch let error {
            print(error)
            throw error
        }
        
        return []
    }
        
    func LoginTest() async throws {
        do {
            try await client.auth.signIn(
                email: "arthur.spalanzani@gmail.com",
                password: "123456"
            )
        } catch let error {
            throw error
        }
    }
    
    func LoginUser() async throws -> [String] {        
        do {
            let session = try await client.auth.refreshSession()     
            //let user = try await client.auth.user(jwt: session.accessToken)            
            return [session.accessToken, session.refreshToken]
        } catch let error {
            print(error)
            throw error
        }
    }
    
    func SignIn(idToken: String) async throws {
        do {
            try await client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idToken
                )
            )
        } catch let error {
            throw error
        }
    }
    
    func SignOut() async throws {
        do {
            try await client.auth.signOut(scope: .local)
        } catch let error {
            throw error
        }
    }
}
