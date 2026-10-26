//
//  DBConnector.swift
//  Workout
//
//  Created by Peter Xie on 11/4/2026.
// currently designed for supabase but coded like this so we can move platforms when needed

import Foundation

/// The RPC returns moddate too; sync only needs the setting name and value.
struct AccountSettingDTO: Codable, Equatable {
    let settingName: String
    let value: String
}

private struct SettingsUpdatePayload: Encodable {
    let i_sessionid: String
    let i_payload: [AccountSettingDTO]
}

enum SettingsSyncError: LocalizedError {
    case missingSession
    case sessionChanged
    case localStorage
    case http(Int)

    var errorDescription: String? {
        switch self {
        case .missingSession: return "Log on before syncing settings."
        case .sessionChanged: return "The account changed while settings were syncing."
        case .localStorage: return "Settings could not be saved on this device."
        case .http(let status): return "Settings could not sync (HTTP \(status)). Please try again."
        }
    }
}

struct AddWorkoutSessionPayload: Encodable {
    let i_sessionid: String
    let i_payload: [WorkoutSessionUploadDTO]
}

struct WorkoutSessionUploadDTO: Encodable,Decodable {
    let id: UUID
    let endTime: Date?
    let startTime: Date?
    let location: String?
    let workout_genre: String?
    let duration_hrs: Double
    let workouttab: String?
    let rest_duration:Float?
    let moddate:Date?
    let iscompleted: Bool?
    let setreps: [SetrepUploadDTO]
}

struct SetrepUploadDTO: Encodable,Decodable {
    let repid: UUID
    let duration_sec: Double
    let finishTime: Date?
    let rep_qty: Int
    let startTime: Date?
    let weight: Double
    let workoutName: String?
    let completed: Bool
    let moddate:Date?
    let weight_basis:String?
}

struct InsUpdWorkoutRequest: Encodable {
    let i_completed: Bool?
    let i_duration_sec: Float?
    let i_finishtime: Date?
    let i_repqty: Int64?
    let i_repid: UUID?
    let i_starttime: Date?
    let i_weight: Int64?
    let i_workoutname: String?
    let i_wsid: UUID?
    let i_wsdur: Float?
    let i_wsendtime: Date?
    let i_wslocation: String?
    let i_wsstarttime: Date?
    let i_wsgenre: String?
}

class DBConnector {
    static let shared = DBConnector()
    
    private let publicAPIKey = "sb_publishable_1UROIFmD1grMT9X90e8FXg_4YyV4lHD"
    private let httpHeadField = "application/json"
    private let projectString = "https://yavtbpncswpvvjuuzzhy.supabase.co/rest/v1/rpc/"
    
    private let method_POST = "POST"
    private let method_DELETE = "DELETE"
    private let method_GET = "GET"
    //private let session_token = "ae13ea87-5f4e-4a36-a71a-693b6a3f2539" // THIS IS JUST FOR TEMP SYNC
    private var session_token = ""
    
    @MainActor
    func loadSessionToken() {
        session_token =
            SettingsManager.shared
                .getSetting(name: SettingsManager.sessionKey)?
                .value ?? ""
    }
    
    func initRequest (i_url:URL,i_method:String) -> URLRequest {
        var request = URLRequest(url: i_url)
        request.httpMethod = i_method
        
        request.setValue(self.httpHeadField, forHTTPHeaderField: "Content-Type")
        request.setValue(self.publicAPIKey, forHTTPHeaderField: "apikey")
        request.setValue("api", forHTTPHeaderField: "Content-Profile")
        return request
    }
    
    @MainActor
    func login(i_username: String, i_password: String) async throws {
        let url = URL(string: "\(projectString)login")!
        var request = initRequest(i_url: url, i_method: method_POST)

        // Publishable keys belong in the apikey header, not Bearer auth.
        request.setValue(nil, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "i_username": i_username,
            "i_password": i_password
        ])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(http.statusCode) else {
            struct APIError: Decodable {
                let message: String
            }

            let message = (try? JSONDecoder().decode(
                APIError.self,
                from: data
            ))?.message ?? "Login failed (HTTP \(http.statusCode))."

            throw NSError(
                domain: "DBConnector.Login",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        }

        let sessionID = try JSONDecoder().decode(UUID.self, from: data)
        session_token = sessionID.uuidString
        SettingsManager.shared.updateSetting(name: SettingsManager.sessionKey, newValue: session_token)
    }
    func fetchSettings(i_sessionid: String, using session: URLSession = .shared) async throws -> [AccountSettingDTO] {
        let body = try JSONEncoder().encode(["i_sessionid": i_sessionid])
        let data = try await settingsRequest(function: "getsettings", body: body, session: session)
        return try JSONDecoder().decode([AccountSettingDTO].self, from: data)
    }

    func upsertSettings(i_payload: [AccountSettingDTO], i_sessionid: String,
                        using session: URLSession = .shared) async throws {
        guard !i_payload.isEmpty else { return }
        let body = try JSONEncoder().encode(SettingsUpdatePayload(
            i_sessionid: i_sessionid, i_payload: i_payload))
        _ = try await settingsRequest(function: "insupdatesettings", body: body, session: session)
    }

    private func settingsRequest(function: String, body: Data, session: URLSession) async throws -> Data {
        let url = URL(string: "\(projectString)\(function)")!
        var request = initRequest(i_url: url, i_method: method_POST)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 20
        request.httpBody = body
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(http.statusCode) else {
            // Never log request/response bodies: settings can contain API keys.
            throw SettingsSyncError.http(http.statusCode)
        }
        return data
    }

    func insertWorkouts(i_ws: [WorkoutSessionUploadDTO]) async {
        
        let postgresqlFuncName = "insupdateworkoutsession"
        let url = URL(string: "\(projectString)\(postgresqlFuncName)")!
        var request = initRequest(i_url: url, i_method: method_POST)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        print("trying to insert workouts")
        let payload = AddWorkoutSessionPayload(i_sessionid: session_token,
                                               i_payload: i_ws)
        do {
            request.httpBody = try encoder.encode(payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                print("Status:", http.statusCode)
                print(response)
            }
            if let body = String(data: data, encoding: .utf8) {
                print("Supabase response body:")
                print(body)
            }
        } catch {
            print("Error:", error)
        }
    }
    
    func deleteworkouts(i_ws: [WorkoutSessionUploadDTO]) async {
        let postgresqlFuncName = "deleteworkoutsession"
        let url = URL(string: "\(projectString)\(postgresqlFuncName)")!
        var request = initRequest(i_url: url, i_method: method_POST)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        print("trying to delete workouts")
        let payload = AddWorkoutSessionPayload(i_sessionid: session_token,
                                               i_payload: i_ws)
        do {
            request.httpBody = try encoder.encode(payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                print("Status:", http.statusCode)
                print(response)
            }
            if let body = String(data: data, encoding: .utf8) {
                print("Supabase response body:")
                print(body)
            }
        } catch {
            print("Error:", error)
        }
    }
    
    func fetchWorkoutSessions() async -> [WorkoutSessionUploadDTO] {
        let functionName = "get_workout_sessions"
        let url = URL(string: "\(projectString)\(functionName)")!
        var request = initRequest(i_url: url, i_method: method_POST)
        let body = [
            "i_sessionid": session_token
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let http = response as? HTTPURLResponse {
                print("Status:", http.statusCode)
                
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let result = try decoder.decode([WorkoutSessionUploadDTO].self, from: data)
            return result
            
        } catch {
            print("❌ Fetch error:", error)
            return []
        }
    }
    
    
    func fetchFoodLogs() async -> [FoodLogLinePayload] {
        
        let functionName = "getfoodlinesync"
        let url = URL(string: "\(projectString)\(functionName)")!
        var request = initRequest(i_url: url, i_method: method_POST)
        let body = [
            "i_sessionid": session_token
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let http = response as? HTTPURLResponse {
                print("Status:", http.statusCode)
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let result = try decoder.decode([FoodLogLinePayload].self, from: data)
            return result
            
        } catch {
            print("❌ Fetch error:", error)
            return []
        }
    }
    

    func insertFoodLog(i_flls: [FoodLogLinePayloadRequest]) async {
        
        let postgresqlFuncName = "addfoodlogentries"
        let url = URL(string: "\(projectString)\(postgresqlFuncName)")!
        var request = initRequest(i_url: url, i_method: method_POST)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let payload = AddFoodLogEntriesRequest(i_sessionid: session_token,
                                               i_payload: i_flls)

        do {
            request.httpBody = try encoder.encode(payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                print("Status:", http.statusCode)
            }

        } catch {
            print("Error:", error)
        }
    }
    
    func deleteFoodLogs(i_ids:[FoodLogLinePayloadRequest]) async {
        let postgresqlFuncName = "deletefoodlogentries"
        let url = URL(string: "\(projectString)\(postgresqlFuncName)")!
        var request = initRequest(i_url: url, i_method: method_POST)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let payload = AddFoodLogEntriesRequest(i_sessionid: session_token,
                                               i_payload: i_ids)

        do {
            request.httpBody = try encoder.encode(payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                print("Status:", http.statusCode)
            }

        } catch {
            print("Error:", error)
        }
    }
    
    
}


