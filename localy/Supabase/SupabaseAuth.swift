//
//  Supabase.swift
//  lookup
//
//  Created by arthur on 15/05/2024.
//

import Supabase
import Foundation

struct Response: Decodable {
    let title: String
    let url: String
    let age: String?
    let content: String
    let favicon: String
}

class SupabaseAuth {
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://nghcmsbksjdehvnpgata.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5naGNtc2Jrc2pkZWh2bnBnYXRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTU3ODYzMTgsImV4cCI6MjAzMTM2MjMxOH0.b-nyOYcX0rHaIozvh975cbUlA5-2fyAz4NUNjRm3I6E"
    )
    
    func QueryWeb(query: String) async throws {
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
                print(jsonArray)
            } catch {
                print("Error decoding JSON: \(error)")
            }
        } catch let error {
            print(error)
            throw error
        }
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
    
    func LoginUser() async throws {
        do {
            let session = try await client.auth.session
            //print(session)
        } catch let error {
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
            try await client.auth.signOut()
        } catch let error {
            throw error
        }
    }
}
