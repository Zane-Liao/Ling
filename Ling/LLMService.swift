import Foundation

struct LLMResponse: Decodable {
    let id: String
    let choices: [Choice]
}

struct Choice: Decodable {
    let message: Message
}

struct Message: Decodable {
    let content: String
}

enum LLMServiceError: Error {
    case missingAPIKey
    case networkError
    case parsingError
    case serverError(String)
}

class LLMService {
    static let shared = LLMService()
    private init() {}
    
    func performQuery(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Get API key from UserDefaults
        guard let apiKey = UserDefaults.standard.string(forKey: "openAIAPIKey"),
              !apiKey.isEmpty else {
            completion(.failure(LLMServiceError.missingAPIKey))
            return
        }
        
        // Create URL request
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.failure(LLMServiceError.networkError))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare request body
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "你是一个有帮助的助手，请用中文回答问题。"],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        // Make API call
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(LLMServiceError.networkError))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let data = data, let errorResponse = String(data: data, encoding: .utf8) {
                    completion(.failure(LLMServiceError.serverError("Status code: \(httpResponse.statusCode), Response: \(errorResponse)")))
                } else {
                    completion(.failure(LLMServiceError.serverError("Status code: \(httpResponse.statusCode)")))
                }
                return
            }
            
            guard let data = data else {
                completion(.failure(LLMServiceError.parsingError))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    completion(.success(content))
                } else {
                    completion(.failure(LLMServiceError.parsingError))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "OPENAI_API_KEY")
    }
}