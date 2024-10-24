import Foundation

class workoutAIservice {
    static let shared = workoutAIservice()
    
    private init() {}

    
    // we are going to define this in the settings screen
    private let apiKey = "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"
    private let endpoint = "https://api.openai.com/v1/chat/completions"

    // Function to send a message to ChatGPT API
    func queryChatGPT(messages: [[String: String]], completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
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
                return
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
                                   let setqty      = workout["setqty"] as? Int,
                                   let repqty      = workout["repqty"] as? Int{
                                    
                                    for _ in 1...setqty{
                                        SetrepManager.shared.addSetrep(qty: repqty, startTime: Date(), finishTime:Date(), workoutName: workoutname, weight: 0)
                                    }
                                   
                                }
                                else{
                               
                                }
                            }
                            
                            completion(.success(content))
                          
                        }
                    }
                } catch {
                    print("Error parsing response: \(error)")
                }
            }

            

           
        }
        
      

             


        task.resume()
    }
}
