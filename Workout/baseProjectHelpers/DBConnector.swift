//
//  DBConnector.swift
//  Workout
//
//  Created by Peter Xie on 11/4/2026.
// currently designed for supabase but coded like this so we can move platforms when needed

import Foundation

class DBConnector {
    static let shared = DBConnector()
    
    private let publicAPIKey = "sb_publishable_1UROIFmD1grMT9X90e8FXg_4YyV4lHD"
    private let httpHeadField = "application/json"
    private let projectString = "https://yavtbpncswpvvjuuzzhy.supabase.co/rest/v1/rpc/"
    
    private let method_POST = "POST"
    private let method_DELETE = "DELETE"
    private let method_GET = "GET"
    private let session_token = "ae13ea87-5f4e-4a36-a71a-693b6a3f2539" // THIS IS JUST FOR TEMP SYNC
    
    
    
    
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
    
   
  
    
    
    func insupdworkout(i_sr:Setrep) async {
        let postgresqlFuncName = "insupdworkout"
        print("WORKING!")
        
        let payload = InsUpdWorkoutRequest(
            i_completed: i_sr.completed ?? false,
            i_duration_sec: i_sr.duration_sec ?? 0,
            i_finishtime: i_sr.finishTime ?? Date(),
            i_repqty: i_sr.rep_qty ?? 0,
            i_repid: i_sr.repid ?? UUID(),
            i_starttime: i_sr.startTime ?? Date(),
            i_weight: i_sr.weight ?? 0,
            i_workoutname: i_sr.workoutName ?? "",
            i_wsid: i_sr.workoutSession?.id ?? UUID(),
            i_wsdur: i_sr.workoutSession?.duration_hrs ?? 0,
            i_wsendtime: i_sr.workoutSession?.endTime ?? Date(),
            i_wslocation: i_sr.workoutSession?.location ?? "",
            i_wsstarttime: i_sr.workoutSession?.startTime ?? Date(),
            i_wsgenre: i_sr.workoutSession?.workout_genre ?? ""
        )
        
        let url = URL(string: "\(projectString)\(postgresqlFuncName)")!
        var request = initRequest(i_url: url, i_method: method_POST)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            request.httpBody = try encoder.encode(payload)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let http = response as? HTTPURLResponse {
                print("Status:", http.statusCode)
            }
            
            print(String(data: data, encoding: .utf8) ?? "")
            
        } catch {
            print("Error:", error)
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
            
            print(String(data: data, encoding: .utf8) ?? "")
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

            print(String(data: data, encoding: .utf8) ?? "")

        } catch {
            print("Error:", error)
        }
    }
    
    
}

