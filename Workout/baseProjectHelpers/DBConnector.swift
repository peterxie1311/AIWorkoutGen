//
//  DBConnector.swift
//  Workout
//
//  Created by Peter Xie on 11/4/2026.
// currently designed for supabase but coded like this so we can move platforms when needed

import Foundation

/// Wire names match the settings RPC. Keep dates when copying between stores.
struct AccountSettingDTO: Codable, Equatable {
    let settingName: String
    let value: String
    let moddate: Date

    init(settingName: String, value: String, moddate: Date = .distantPast) {
        self.settingName = settingName
        self.value = value
        self.moddate = moddate
    }

    private enum CodingKeys: String, CodingKey { case settingName, value, moddate }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        settingName = try container.decode(String.self, forKey: .settingName)
        value = try container.decode(String.self, forKey: .value)
        let text = try container.decode(String.self, forKey: .moddate)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: text)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: text)
        }
        guard let date = date else {
            throw DecodingError.dataCorruptedError(forKey: .moddate, in: container,
                                                   debugDescription: "Invalid settings timestamp.")
        }
        moddate = date
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(settingName, forKey: .settingName)
        try container.encode(value, forKey: .value)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(formatter.string(from: moddate), forKey: .moddate)
    }
}

private struct SettingsUpdatePayload: Encodable {
    let i_sessionid: String
    let i_payload: [AccountSettingDTO]
}

enum SettingsSyncError: LocalizedError {
    case missingSession
    case sessionChanged
    case localStorage

    var errorDescription: String? {
        switch self {
        case .missingSession: return "Log on before syncing settings."
        case .sessionChanged: return "The account changed while settings were syncing."
        case .localStorage: return "Settings could not be saved on this device."
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
    let iconName:String?
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

        let data = try await APIResponse.data(for: request)

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
        return try await APIResponse.data(for: request, using: session)
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
            _ = try await APIResponse.data(for: request)
        } catch {
            print("Database request failed:", (error as NSError).code)
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
            _ = try await APIResponse.data(for: request)
        } catch {
            print("Database request failed:", (error as NSError).code)
        }
    }
    
    func fetchWorkoutSessions() async throws -> [WorkoutSessionUploadDTO] {
        let functionName = "get_workout_sessions"
        let url = URL(string: "\(projectString)\(functionName)")!
        var request = initRequest(i_url: url, i_method: method_POST)
        let body = [
            "i_sessionid": session_token
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let data = try await APIResponse.data(for: request)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([WorkoutSessionUploadDTO].self, from: data)
    }
    
    
    func fetchFoodLogs() async throws -> [FoodLogLinePayload] {
        
        let functionName = "getfoodlinesync"
        let url = URL(string: "\(projectString)\(functionName)")!
        var request = initRequest(i_url: url, i_method: method_POST)
        let body = [
            "i_sessionid": session_token
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let data = try await APIResponse.data(for: request)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([FoodLogLinePayload].self, from: data)
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
            _ = try await APIResponse.data(for: request)
        } catch {
            print("Database request failed:", (error as NSError).code)
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
            _ = try await APIResponse.data(for: request)
        } catch {
            print("Database request failed:", (error as NSError).code)
        }
    }
    
    
}



