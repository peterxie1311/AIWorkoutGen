//
//  WorkoutTests.swift
//  WorkoutTests
//
//  Created by Peter Xie on 24/10/2024.
//

import XCTest
@testable import Workout

final class WorkoutTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }
//    func testCreateWorkoutPlan() async throws {
//        let vc = UIViewController()
//
//        let result = try await workoutAIservice.shared.createWorkoutPlan(
//            i_cntInputData: [],
//            i_sessions: 5,
//            i_vc: vc,
//            i_customisations: "Upper body hypertrophy"
//        )
//
//        print("RESULT COUNT:", result.count)
//
//        result.forEach {
//            print($0.workouttab)
//        }
//
//        XCTAssertEqual(result.count, 5)
//    }
//    
//    func testInsertStuff() async throws {
//        await MainActor.run {
//           
//                await WorkoutSessionManager.shared.syncworkoutsessionentries()
//                print("working")
//           
//        }
//    }
//    
//    func testGrabWorkouts() async throws{
//                await WorkoutSessionManager.shared.syncworkoutsessionentries()
//            
//        
//        
//    }
    
    func testInsertStuff() async throws {
        await FoodLogManager.shared.addFoodLogEntry(
            i_date: Date(),
            i_calories: 500,
            i_carbs: 60,
            i_fat: 10,
            i_food: "Chicken rice",
            i_grams: 300,
            i_protein: 40
        )

        print("done")
    }
    
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    
    
//    func testAiFoodEstimate() async throws {
//        let vc = UIViewController()
//        
//        let chicken = MacroEstimate(
//            foodname: "Chicken",
//            foodgrams: 150,
//            protein: 0,
//            carbs: 0,
//            fats: 0,
//            fiber: 0,
//            assumptions: [],
//            confidence: ""
//        )
//        
//        try await workoutAIservice.shared.estimateMacros(i_ingredients: [chicken], i_vc: vc)
//    }
//    
//    func UpdatesetrepDate() async throws {
//        await MainActor.run {
//            WorkoutSessionManager.shared.loadWorkoutSessions()
//        }
//
//        let dbWorkouts = await DBConnector.shared.fetchWorkoutSessions()
//
//        await MainActor.run {
//            for dbWorkout in dbWorkouts {
//                print("WORKING  " )
//
//                if let localWorkout =  WorkoutSessionManager.shared.workoutSessions.first(where: {
//                    $0.id == dbWorkout.id
//                }) {
//                    for setrep in dbWorkout.setreps {
//                        
//                        if let localSet = localWorkout.setrepArray.first(where: {
//                            $0.repid == setrep.repid
//                            
//                        }) {
//                            localSet.duration_sec = Float(setrep.duration_sec)
//                            print("Saved")
//                            print(Float(setrep.duration_sec))
//                            
//                        }
//                    }
//
//                }
//            }
//            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
//            let context = appDelegate.persistentContainer.viewContext
//            do{
//                try context.save()
//            }catch{
//                print("didnt work")
//            }
//        }
//    }
    
//    func testRemoveAllWorkouts() throws {
//        WorkoutSessionManager.shared.loadWorkoutSessions()
//        
//        WorkoutSessionManager.shared.workoutSessions.forEach{
//            
//            if let id = $0.id{
//                WorkoutSessionManager.shared.removeWorkoutSession(workoutid: id)
//            }
//        }
        
  //  }

}

@MainActor
final class AccountSettingsSyncTests: XCTestCase {
    private func stubSession(status: Int, body: String) -> URLSession {
        SettingsRPCStub.status = status
        SettingsRPCStub.body = Data(body.utf8)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [SettingsRPCStub.self]
        return URLSession(configuration: configuration)
    }

    func testFetchSettingsUsesAPIProfileAndDecodesRows() async throws {
        let session = stubSession(status: 200, body: """
        [{"settingName":"Name","value":"Peter"}]
        """)
        defer { session.invalidateAndCancel() }
        let rows = try await DBConnector.shared.fetchSettings(
            i_sessionid: UUID().uuidString, using: session)
        XCTAssertEqual(rows, [AccountSettingDTO(settingName: "Name", value: "Peter")])
        XCTAssertEqual(SettingsRPCStub.lastRequest?.url?.lastPathComponent, "getsettings")
        XCTAssertEqual(SettingsRPCStub.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(SettingsRPCStub.lastRequest?.value(forHTTPHeaderField: "Content-Profile"), "api")
        XCTAssertNil(SettingsRPCStub.lastRequest?.value(forHTTPHeaderField: "Authorization"))
        XCTAssertNotNil(SettingsRPCStub.lastRequest?.value(forHTTPHeaderField: "apikey"))
    }

    func testFailedFetchThrowsInsteadOfPretendingAccountHasNoSettings() async throws {
        let session = stubSession(status: 401, body: "{}")
        defer { session.invalidateAndCancel() }
        do {
            _ = try await DBConnector.shared.fetchSettings(
                i_sessionid: UUID().uuidString, using: session)
            XCTFail("An HTTP error must not be interpreted as an empty settings list.")
        } catch SettingsSyncError.http(let status) {
            XCTAssertEqual(status, 401)
        }
    }

    func testUpsertHandlesVoidResponse() async throws {
        let session = stubSession(status: 204, body: "")
        defer { session.invalidateAndCancel() }
        try await DBConnector.shared.upsertSettings(
            i_payload: [AccountSettingDTO(settingName: "Name", value: "Peter")],
            i_sessionid: UUID().uuidString, using: session)
        XCTAssertEqual(SettingsRPCStub.lastRequest?.url?.lastPathComponent, "insupdatesettings")
    }

    func testExistingAccountSettingsAreNotOverwrittenByDefaults() {
        let upload = SettingsManager.settingsToUpload(
            local: [AccountSettingDTO(settingName: "Calorie Goal", value: "0")],
            remote: [AccountSettingDTO(settingName: "Calorie Goal", value: "2300")],
            pending: [])
        XCTAssertTrue(upload.isEmpty)
    }

    func testPendingEditWinsAndMissingSettingsAreSeeded() {
        let local = [
            AccountSettingDTO(settingName: "Name", value: "Peter"),
            AccountSettingDTO(settingName: "Calorie Goal", value: "2400"),
            AccountSettingDTO(settingName: "Protein Goal", value: "170")
        ]
        let upload = SettingsManager.settingsToUpload(local: local, remote: [
            AccountSettingDTO(settingName: "Name", value: "Remote name"),
            AccountSettingDTO(settingName: "Calorie Goal", value: "2300")
        ], pending: ["Calorie Goal"])
        XCTAssertEqual(upload, Array(local.dropFirst()))
    }

    func testSessionAndUnknownSettingsNeverUploadButGPTKeyDoes() {
        let key = AccountSettingDTO(settingName: "GPT API Key", value: "test-placeholder")
        let upload = SettingsManager.settingsToUpload(local: [
            AccountSettingDTO(settingName: "Session Key", value: UUID().uuidString),
            AccountSettingDTO(settingName: "Unknown", value: "value"), key
        ], remote: [], pending: ["Session Key", "Unknown"])
        XCTAssertEqual(upload, [key])
    }

    func testRPCResponseDecodesWithoutParsingTimestamp() throws {
        let data = Data("""
        [{"settingName":"Calorie Goal","value":"2300","moddate":"2026-10-26T01:02:03.123456+00:00"}]
        """.utf8)
        XCTAssertEqual(try JSONDecoder().decode([AccountSettingDTO].self, from: data),
                       [AccountSettingDTO(settingName: "Calorie Goal", value: "2300")])
    }

    func testRPCPayloadUsesBackendFieldNames() throws {
        let data = try JSONEncoder().encode(AccountSettingDTO(settingName: "Name", value: "Peter"))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: String])
        XCTAssertEqual(object, ["settingName": "Name", "value": "Peter"])
    }
}

/// Settings tests never contact the real backend.
private final class SettingsRPCStub: URLProtocol {
    static var status = 200
    static var body = Data()
    static var lastRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lastRequest = request
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status,
                                       httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

