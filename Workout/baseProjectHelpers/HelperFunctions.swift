//
//  HelperFunctions.swift
//  Workout
//
//  Created by Peter Xie on 22/12/2024.
//

import Foundation

import UIKit

class HelperFunctions {
   
    static func parseDateToStringFull(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    static func parseDateToString(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    static func showAlert(on viewController: UIViewController, title: String, message: String) {
           let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
           alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
           viewController.present(alert, animated: true, completion: nil)
       }
    static func formatNumber(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value)) // no .0
        } else {
            return String(format: "%.2f", value) // 2dp
        }
    }
    
    static func parseIntSecToString(seconds: Int) -> String {
        let hrs = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d:%02d", hrs, mins, secs)
    }
    static func parseDateToStringTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    static func isDateHourBetween(date:Date,hour_less:Int,hour_greater:Int) -> Bool{
        let datehour = Calendar.current.component(.hour, from: date)
        return datehour <= hour_less && datehour >= hour_greater
    }
    
    
    static func isLargerThanSunday(date: Date) -> Bool { // we're actually just doing saturday
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // 1 = Sunday

        // Calculate the start of the week
        if let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start {
            let normalizedStartOfWeek = calendar.startOfDay(for: startOfWeek)
            return date > normalizedStartOfWeek
        }
        return false
    }
      
}




struct APIResponseError: LocalizedError {
    let statusCode: Int
    let serverMessage: String?

    var errorDescription: String? {
        serverMessage ?? "The request failed (HTTP \(statusCode))."
    }
}

enum APIResponse {
    private struct MessageBody: Decodable {
        struct ErrorBody: Decodable {
            let message: String?
        }

        let message: String?
        let error: ErrorBody?

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            message = try? values.decode(String.self, forKey: .message)
            error = try? values.decode(ErrorBody.self, forKey: .error)
        }

        private enum CodingKeys: String, CodingKey { case message, error }
    }

    static func data(for request: URLRequest, using session: URLSession = .shared) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            try Task.checkCancellation()
            try check(data, response: response, request: request)
            return data
        } catch let error as APIResponseError {
            throw error
        } catch {
            if !Task.isCancelled {
                logFailure(request: request, message: error.localizedDescription)
            }
            throw error
        }
    }

    static func logFailure(request: URLRequest, message: String) {
        let endpoint = request.url?.path ?? "Unknown endpoint"
        print("[API] \(request.httpMethod ?? "GET") \(endpoint): \(message)")
    }

    static func check(_ data: Data, response: URLResponse?, request: URLRequest) throws {
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        let body = try? JSONDecoder().decode(MessageBody.self, from: data)
        var message = [body?.message, body?.error?.message]
            .compactMap { $0 }
            .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        if let authorization = request.value(forHTTPHeaderField: "Authorization"),
           authorization.hasPrefix("Bearer "), authorization.count > "Bearer ".count {
            let token = String(authorization.dropFirst("Bearer ".count))
            message = message?.replacingOccurrences(of: token, with: "[redacted]")
        }

        guard (200...299).contains(http.statusCode) else {
            let error = APIResponseError(statusCode: http.statusCode, serverMessage: message)
            let alertMessage = error.localizedDescription
            logFailure(request: request, message: "HTTP \(http.statusCode) \(message ?? "")")
            Task { @MainActor in APIMessageAlert.enqueue(alertMessage) }
            throw error
        }

        if let message {
            Task { @MainActor in APIMessageAlert.enqueue(message) }
        }
    }
}

@MainActor
enum APIMessageAlert {
    private static var pending: [String] = []
    private static weak var visibleAlert: UIAlertController?
    private static var retryScheduled = false

    static func enqueue(_ message: String) {
        guard visibleAlert?.message != message, !pending.contains(message) else { return }
        pending.append(message)
        presentNext()
    }

    static func presentNext() {
        guard let message = pending.first,
              let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .filter({ $0.activationState == .foregroundActive })
                .compactMap({ $0.keyWindow }).first,
              let root = window.rootViewController,
              (window.windowScene?.delegate as? SceneDelegate)?.isOpeningWorkout != true else { return }

        var presenter = root
        while let presented = presenter.presentedViewController {
            presenter = presented
        }

        guard !(presenter is UIAlertController),
              presenter.transitionCoordinator == nil,
              !presenter.isBeingPresented, !presenter.isBeingDismissed,
              presenter.viewIfLoaded?.window === window else {
            retryPresentation()
            return
        }

        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            retryPresentation()
        })
        presenter.present(alert, animated: true)
        guard presenter.presentedViewController === alert || alert.presentingViewController != nil else {
            retryPresentation()
            return
        }
        pending.removeFirst()
        visibleAlert = alert
    }

    private static func retryPresentation() {
        guard !pending.isEmpty, !retryScheduled else { return }
        retryScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            retryScheduled = false
            presentNext()
        }
    }
}
