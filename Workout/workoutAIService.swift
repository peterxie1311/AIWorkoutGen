import Foundation
import UIKit

class workoutAIservice {
    static let shared = workoutAIservice()
    
    private init() {}

    
    // we are going to define this in the settings screen
    private let apiKey = SettingsManager.shared.getSetting(name: "GPT API Key")?.value ?? ""
    private let endpoint = "https://api.openai.com/v1/chat/completions"

    // Function to send a message to ChatGPT API
    func queryChatGPT(messages: [[String: String]],completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        print("API Key: \(apiKey)")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "temperature": 0.3,
            "messages": messages
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        print("Request Body: \(String(describing: String(data: request.httpBody!, encoding: .utf8)))")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                print("Error: \(error)")
                return
            }

            if let response = response as? HTTPURLResponse {
                print("Response status code: \(response.statusCode)")
                if response.statusCode != 200 {
                    completion(.failure(NSError(domain: "Invalid response", code: response.statusCode, userInfo: nil)))
                    return
                }
            }

            if let data = data {
                do {
                    print("Raw response data: \(String(data: data, encoding: .utf8) ?? "")")
                    
                    if let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let choices = responseDict["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let content = message["content"] as? String {

                        print("Raw response content: \(content)")

                        let cleanedContent = content
                            .replacingOccurrences(of: "```json", with: "")
                            .replacingOccurrences(of: "```", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        print("Cleaned content: \(cleanedContent)")

                        if let jsonData = cleanedContent.data(using: .utf8),
                           let workouts = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] {
                            
                            for workout in workouts {
                                if let workoutname = workout["workoutname"] as? String,
                                   let setqty = workout["setqty"] as? Int,
                                   let repqty = workout["repqty"] as? Int {
                                    
                                    for _ in 1...setqty {
                                        SetrepManager.shared.addSetrep(qty: repqty, startTime: Date(), finishTime: Date(), workoutName: workoutname, weight: 0)
                                        print(workoutname)
                                    }
                                }
                            }

                            completion(.success(content))
                        }
                    }
                } catch {
                   // HelperFunctions.showAlert(on: viewController, title: "Failed to add workout!", message: //"Error parsing response: \(error)")
                    print(error)
                    completion(.failure(error))
                    
                }
            }
        }

        task.resume()
    }

}
