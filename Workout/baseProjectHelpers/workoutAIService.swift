import Foundation
import UIKit

struct MacroEstimate:Codable {
    let foodname:String
    let foodgrams:Double
    let protein: Double
    let carbs: Double
    let fats: Double
    let fiber: Double
    let assumptions:[String]
    let confidence:String
    let imageName:String
    var calories: Double {
           (protein * 4) + (carbs * 4) + (fats * 9)
       }
}

struct WorkoutSessionDTO: Codable {
    let workouttab: String
    let location: String?
    let workout_genre: String?
    let rest_time:Float
    let setreps: [SetrepDTO]
}

struct SetrepDTO: Codable {
    let workoutName: String
    let rep_qty: Int
    let weight: Int
    let set_qty: Int

    var asSetreps: [Setrep] {
        (0..<set_qty).map { _ in
            SetrepManager.shared.initSetRep(
                qty: rep_qty,
                startTime: Date(),
                finishTime: Date(),
                workoutName: workoutName,
                weight: Int64(weight)
            )
        }
    }
}
struct ChatCompletionResponse: Decodable {
    let choices: [Choice]
}

struct Choice: Decodable {
    let message: Message
}

struct Message: Decodable {
    let content: String
}
class workoutAIservice {
    static let shared = workoutAIservice()
    private init() {}
    // we are going to define this in the settings screen
    private let apiKey = SettingsManager.shared.getSetting(name: "GPT API Key")?.value ?? ""
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    private let macroEstimateDefault = MacroEstimate(
        foodname: Constants.string_default,
        foodgrams: Constants.num_defaultDouble,
        protein: Constants.num_defaultDouble,
        carbs: Constants.num_defaultDouble,
        fats: Constants.num_defaultDouble,
      //  calories: Constants.num_defaultDouble,
        fiber: Constants.num_defaultDouble,
        assumptions: [Constants.string_default],
        confidence: Constants.string_default,
        imageName: Constants.string_default
    )
    

    
    func createWorkoutPlan(i_cntInputData:[WorkoutSessionDTO],i_sessions:Int,i_customisations:String) async throws -> [WorkoutSessionDTO]{
        guard let url = URL(string: endpoint) else {
            return []
        }
        
        let workoutData = try JSONEncoder().encode(i_cntInputData)
        let workoutJSONString = String(data: workoutData, encoding: .utf8) ?? "[]"
        
        let inputString =
        """
        You are a fitness assistant.

        Return ONLY valid JSON.

        Generate a workout plan.

        The response must be a JSON array containing exactly \(i_sessions) WorkoutSession objects.

        Do not return an empty array.

        Each WorkoutSession must contain:
        - workouttab (String)
        - workout_genre (String)
        - setreps (Array)
        - rest_time (Float) seconds

        Each setrep must contain:
        - workoutName (String)
        - rep_qty (Integer)
        - set_qty (Integer)
        - weight (Integer)

        rep_qty, set_qty, and weight MUST be integers only.
        Do not use ranges.
        Do not use strings for numbers.
        Do not include markdown.
        Do not include explanations.

        Recent workout history:
        \(workoutJSONString)

        Customisations and goals:
        \(i_customisations)
        """
        
        let query: [[String: String]] = [
            ["role": "system", "content": "You are a fitness assistant who responds ONLY in JSON."],
            ["role": "user", "content": inputString]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "temperature": 0.3,
            "messages": query
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let http = response as? HTTPURLResponse else {
           
                return []
            }
            
            guard (200...299).contains(http.statusCode) else {
             
                return []
            }
            
            
            let chatResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
            
            guard let jsonString = chatResponse.choices.first?.message.content
            else {
                return []
            }

            let cleanedJSONString = jsonString
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard let jsonData = cleanedJSONString.data(using: .utf8)
            else {
                return []
            }

            return try JSONDecoder().decode([WorkoutSessionDTO].self, from: jsonData)
        }
    }
    
    //cleaned up version
    func estimateMacros(i_ingredients: [MacroEstimate], i_vc: UIViewController) async throws -> [MacroEstimate] {

        guard let url = URL(string: endpoint) else {
            await MainActor.run {
                HelperFunctions.showAlert(on: i_vc, title: "Failed to Init URL!", message: "")
            }
            return [macroEstimateDefault]
        }

        let ingredientsData = try JSONEncoder().encode(i_ingredients)
        let ingredientsJSONString = String(data: ingredientsData, encoding: .utf8) ?? "[]"

        let allowedIcons = FoodIcon.allowedIconNamesForPrompt

        let inputString = """
        You are a nutrition estimation AI.

        Estimate missing nutrition values for food ingredients.

        IMPORTANT:
        - Return ONLY valid JSON.
        - Do NOT include markdown.
        - Output must be a JSON array.
        - The icon field MUST be exactly one of the allowed icon names.
        - Do NOT invent icon names.
        - If unsure, choose the closest general category.
        - If no good icon matches, use "vegetables", "sauce", "dessert", or "protein_powder" only when appropriate.

        Allowed icon names:
        [\(allowedIcons)]

        Output format:
        [
          {
            "foodname": String,
            "foodgrams": Double,
            "protein": Double,
            "carbs": Double,
            "fats": Double,
            "fiber": Double,
            "assumptions": [String],
            "confidence": String,
            "icon": String
          }
        ]

        Input ingredients:
        \(ingredientsJSONString)
        """
        
        let query: [[String: String]] = [
            ["role": "system", "content": "You are a helpful Macro Predicting assistant who responds ONLY in JSON."],
            ["role": "user", "content": inputString]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "temperature": 0.3,
            "messages": query
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                await MainActor.run {
                    HelperFunctions.showAlert(on: i_vc, title: "Network error!", message: "Invalid response.")
                }
                return [macroEstimateDefault]
            }

            guard (200...299).contains(http.statusCode) else {
                await MainActor.run {
                    HelperFunctions.showAlert(on: i_vc, title: "Network error!", message: "\(http.statusCode)")
                }
                return [macroEstimateDefault]
            }

            do {
                guard
                    let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let choices = responseDict["choices"] as? [[String: Any]],
                    let message = choices.first?["message"] as? [String: Any],
                    let content = message["content"] as? String
                else {
                    return [macroEstimateDefault]
                }

                let cleanedContent = content
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                
                print("trying to print cleaned content:")
                print(cleanedContent)
                
                
                guard let jsonData = cleanedContent.data(using: .utf8) else {
                    print("Model returned:", cleanedContent)
                    return [macroEstimateDefault]
                }

                let decoded = try JSONDecoder().decode([MacroEstimate].self, from: jsonData)
                return decoded.isEmpty ? [macroEstimateDefault] : decoded

            } catch {
                print("Parsing error!!")
                await MainActor.run {
                    HelperFunctions.showAlert(on: i_vc, title: "Parsing error", message: error.localizedDescription)
                }
                return [macroEstimateDefault]
            }

        } catch {
            print("Network error!")
            await MainActor.run {
                HelperFunctions.showAlert(on: i_vc, title: "Network error!", message: error.localizedDescription)
            }
            return [macroEstimateDefault]
        }
    }
    

    // Function to send a message to ChatGPT API
    func queryChatGPT(messages: [[String: String]],completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
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
                    if let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let choices = responseDict["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        let cleanedContent = content
                            .replacingOccurrences(of: "```json", with: "")
                            .replacingOccurrences(of: "```", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)

                        if let jsonData = cleanedContent.data(using: .utf8),
                           let workouts = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] {
                            
                            for workout in workouts {
                                if let workoutname = workout["workoutname"] as? String,
                                   let setqty = workout["setqty"] as? Int,
                                   let repqty = workout["repqty"] as? Int {
                                    
                                    for _ in 1...setqty {
                                        SetrepManager.shared.addSetrep(qty: repqty, startTime: Date(), finishTime: Date(), workoutName: workoutname, weight: 0)
                                    }
                                }
                            }

                            completion(.success(content))
                        }
                    }
                } catch {
                    completion(.failure(error))
                    
                }
            }
        }

        task.resume()
    }

}
