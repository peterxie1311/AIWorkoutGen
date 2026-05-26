//
//  DBConnector.swift
//  Workout
//
//  Created by Peter Xie on 11/4/2026.
// currently designed for supabase but coded like this so we can move platforms when needed

import Foundation

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
    private let session_token = SettingsManager.shared.getSetting(name: SettingsManager.sessionKey)?.value ?? ""
    
    
    
    func initRequest (i_url:URL,i_method:String) -> URLRequest {
        var request = URLRequest(url: i_url)
        request.httpMethod = i_method
        
        request.setValue(self.httpHeadField, forHTTPHeaderField: "Content-Type")
        request.setValue(self.publicAPIKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(publicAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("api", forHTTPHeaderField: "Content-Profile")
        return request
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
    

    
    func insertWorkouts(i_ws: [WorkoutSessionUploadDTO]) async {
        
        let postgresqlFuncName = "insupdateworkoutsession"
        let url = URL(string: "\(projectString)\(postgresqlFuncName)")!
        var request = initRequest(i_url: url, i_method: method_POST)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        print("trying to insert workouts")
        
        let payload = AddWorkoutSessionPayload(i_sessionid: session_token,
                                               i_payload: i_ws)
        print("PAYLOAD")
        print(payload)
        do {
            request.httpBody = try encoder.encode(payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                print("Status:", http.statusCode)
                print(response)
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
           
//            print(String(data: data, encoding: .utf8) ?? "")
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
    
    
}

