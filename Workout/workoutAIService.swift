import Foundation
import UIKit

struct MacroEstimate:Codable {
    let foodname:String
    let foodgrams:Double
    let protein: Double
    let carbs: Double
    let fats: Double
    let calories: Double
    let fiber: Double
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
        calories: Constants.num_defaultDouble,
        fiber: Constants.num_defaultDouble
    )
    
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

        let inputString = """
        You are an AI that predicts macros.
        Return ONLY a JSON array, no extra text, no explanations.

        Output Format:
        [{"foodname": String, "foodgrams": Double, "protein": Double, "carbs": Double, "fats": Double, "calories": Double, "fiber": Double}]

        Rules:
        - All measurements are grams.
        - If an input macro field is 0, treat it as unknown and estimate it.

        Input:
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

                guard
                    let jsonData = cleanedContent.data(using: .utf8),
                    let ingredientsReply = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]]
                else {
                    // Helpful debug:
                    print("Model returned:", cleanedContent)
                    return [macroEstimateDefault]
                }

                var ingredientResults: [MacroEstimate] = []

                for ingredient in ingredientsReply {
                    guard
                        let foodname = ingredient["foodname"] as? String,
                        let foodgrams = (ingredient["foodgrams"] as? NSNumber)?.doubleValue,
                        let protein = (ingredient["protein"] as? NSNumber)?.doubleValue,
                        let carbs = (ingredient["carbs"] as? NSNumber)?.doubleValue,
                        let fats = (ingredient["fats"] as? NSNumber)?.doubleValue,
                        let calories = (ingredient["calories"] as? NSNumber)?.doubleValue,
                        let fiber = (ingredient["fiber"] as? NSNumber)?.doubleValue
                    else { continue }

                    ingredientResults.append(
                        MacroEstimate(
                            foodname: foodname,
                            foodgrams: foodgrams,
                            protein: protein,
                            carbs: carbs,
                            fats: fats,
                            calories: calories,
                            fiber: fiber
                        )
                    )
                }

                return ingredientResults.isEmpty ? [macroEstimateDefault] : ingredientResults

            } catch {
                await MainActor.run {
                    HelperFunctions.showAlert(on: i_vc, title: "Parsing error", message: error.localizedDescription)
                }
                return [macroEstimateDefault]
            }

        } catch {
            await MainActor.run {
                HelperFunctions.showAlert(on: i_vc, title: "Network error!", message: error.localizedDescription)
            }
            return [macroEstimateDefault]
        }
    }
    
    
//    func estimateMacros(i_ingredients:[MacroEstimate],
//                        i_vc:UIViewController) async throws -> [MacroEstimate] {
//        
//        guard let url = URL(string: endpoint) else {
//            HelperFunctions.showAlert(on: i_vc, title: "Failed to Init URL!", message: "")
//            return [macroEstimateDefault]
//        }
//        
//        let ingredientsData = try JSONEncoder().encode(i_ingredients)
//        let ingredientsJSONString = String(data: ingredientsData, encoding: .utf8) ?? "[]"
//                            
//                            
//        let inputString = """
//        You are an AI that predeicts macros.
//        Return ONLY a JSON array, no extra text, no explanations.
//
//        Rules:
//        - Output Format: [{"foodname":String,
//                           "foodgrams":Double,
//                           "protein": Double,
//                           "carbs": Double,
//                           "fats": Double,
//                           "calories": Double,
//                           "fiber": Double}]
//        
//        - All measurements will be in grams.
//        - If the input field is = 0 then please ignore it.
//        
//        Please predict the Output Format based on the following input information:
//        
//        \(ingredientsJSONString)
//        """
//        
//        let query = [
//            ["role": "system", "content": "You are a helpful Macro Predicting assistant who responds ONLY in JSON."],
//            ["role": "user", "content": inputString] ]
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        let requestBody: [String: Any] = [
//            "model": "gpt-4o",
//            "temperature": 0.3,
//            "messages": query
//        ]
//        
//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
//        } catch {
//            return [macroEstimateDefault]
//        }
//        
//        do {
//            let (data, response) = try await URLSession.shared.data(for: request)
//            // just check thre response code from chat usually code = 200 is good!
//            if let response = response as? HTTPURLResponse {
//                if response.statusCode != 200 {
//                    HelperFunctions.showAlert(on: i_vc, title: "Network error!", message: "\(response.statusCode) - \(response.allHeaderFields)")
//                    return [macroEstimateDefault]
//                }
//                
//                // if we reach here then try and parse the response
//                
//                
//                do {
//                    if let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//                       let choices = responseDict["choices"] as? [[String: Any]],
//                       let message = choices.first?["message"] as? [String: Any],
//                       let content = message["content"] as? String {
//                        let cleanedContent = content
//                            .replacingOccurrences(of: "```json", with: "")
//                            .replacingOccurrences(of: "```", with: "")
//                            .trimmingCharacters(in: .whitespacesAndNewlines)
//                        
//                        if let jsonData = cleanedContent.data(using: .utf8),
//                           let ingredientsReply = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] {
//                           var ingredientResults = [] as [MacroEstimate]
//                           for ingredient in ingredientsReply {
//                               if let foodname = ingredient["foodname"]as? String,
//                                  let foodgram = ingredient["foodgrams"]as? Double,
//                                  let protein = ingredient["protein"]as? Double,
//                                  let carbs = ingredient["carbs"]as? Double,
//                                  let fats = ingredient["fats"]as? Double,
//                                  let calories = ingredient["calories"]as? Double,
//                                  let fiber = ingredient["fiber"]as? Double
//                               {
//                                   let newEstimate = MacroEstimate(foodname: foodname,
//                                                                   foodgrams: foodgram,
//                                                                   protein: protein,
//                                                                   carbs: carbs,
//                                                                   fats: fats,
//                                                                   calories: calories,
//                                                                   fiber: fiber)
//                                   
//                                   ingredientResults.append(newEstimate)
//                                   
//                               }
//                           }
//                         return ingredientResults
//                        }
//                    }
//                } catch {
//                    HelperFunctions.showAlert(on: i_vc, title: "Parsing error", message: error.localizedDescription)
//                }
//                
//                
//                
//            }
//        }catch {
//            HelperFunctions.showAlert(on: i_vc, title: "Network error!", message: error.localizedDescription)
//        }
//
//        return [macroEstimateDefault]
//    }

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
