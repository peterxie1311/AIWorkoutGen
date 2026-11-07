import CoreData
import UIKit

/// An immutable, read-only snapshot. No account IDs or credentials enter tool results.
struct HistoryChatContext: Sendable {
    struct Row: Codable, Sendable {
        let date: String?
        let name: String
        var session: Int? = nil
        var sessionName: String? = nil
        var sessionCompleted: Bool? = nil
        var setCompleted: Bool? = nil
        var reps: Int64? = nil
        var weight: Double? = nil
        var weightBasis: String? = nil
        var durationMinutes: Double? = nil
        var grams: Double? = nil
        var calories: Double? = nil
        var protein: Double? = nil
        var carbs: Double? = nil
        var fat: Double? = nil
    }

    struct Query: Decodable {
        let kind: String
        var from: String? = nil
        var through: String? = nil
        var contains: String? = nil
        var offset: Int? = nil
        var summaryOnly: Bool? = nil
    }

    struct ResultPage: Encodable {
        let matchingRows: Int
        let firstDay: String?
        let lastDay: String?
        let undatedRows: Int
        let loggedDays: Int
        let completedSessions: Int?
        let completedSets: Int?
        let calories: Double?
        let proteinGrams: Double?
        let carbGrams: Double?
        let fatGrams: Double?
        let nextOffset: Int?
        let rows: [Row]
    }

    let workouts: [Row]
    let food: [Row]
    let today: String
    let timeZone: String

    @MainActor
    static func load() async throws -> HistoryChatContext {
        guard let app = UIApplication.shared.delegate as? AppDelegate else {
            throw HistoryChatError.historyUnavailable
        }
        let zone = TimeZone.current
        return try await app.persistentContainer.performBackgroundTask { context in
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = zone
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            func dateString(_ date: Date?) -> String? { date.map { formatter.string(from: $0) } }
            func label(_ text: String?, fallback: String) -> String {
                String((text?.isEmpty == false ? text ?? fallback : fallback).prefix(160))
            }
            func finite(_ value: Double) -> Double? { value.isFinite ? value : nil }

            let request: NSFetchRequest<WorkoutSession> = WorkoutSession.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false),
                                       NSSortDescriptor(key: "id", ascending: true)]
            let sessions = try context.fetch(request)
            var workouts: [Row] = []
            for (index, session) in sessions.enumerated() {
                let name = label(session.workouttab ?? session.workout_genre, fallback: "Workout")
                let sets = session.setrepArray.sorted {
                    ($0.startTime ?? .distantPast, $0.repid?.uuidString ?? "") >
                    ($1.startTime ?? .distantPast, $1.repid?.uuidString ?? "")
                }
                if sets.isEmpty {
                    workouts.append(Row(date: dateString(session.startTime ?? session.endTime),
                                        name: name, session: index + 1, sessionName: name,
                                        sessionCompleted: session.isComplete,
                                        durationMinutes: finite(Double(session.duration_hrs) * 60)))
                }
                for set in sets {
                    workouts.append(Row(date: dateString(set.startTime ?? set.finishTime ?? session.startTime ?? session.endTime),
                                        name: label(set.workoutName, fallback: "Unnamed exercise"),
                                        session: index + 1, sessionName: name,
                                        sessionCompleted: session.isComplete, setCompleted: set.completed,
                                        reps: set.rep_qty, weight: finite(Double(set.weight)),
                                        weightBasis: set.weight_basis.map { String($0.prefix(40)) },
                                        durationMinutes: finite(Double(session.duration_hrs) * 60)))
                }
            }

            let foodRequest: NSFetchRequest<FoodLogLine> = FoodLogLine.fetchRequest()
            foodRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false),
                                           NSSortDescriptor(key: "foodID", ascending: true)]
            let food = try context.fetch(foodRequest).map {
                Row(date: dateString($0.date), name: label($0.food, fallback: "Unnamed food"),
                    grams: finite($0.grams), calories: finite($0.calories),
                    protein: finite($0.protein), carbs: finite($0.carbs), fat: finite($0.fat))
            }
            return HistoryChatContext(workouts: workouts.sorted { ($0.date ?? "") > ($1.date ?? "") },
                                      food: food,
                                      today: String(formatter.string(from: Date()).prefix(10)),
                                      timeZone: zone.identifier)
        }
    }

    func lookup(_ query: Query) throws -> ResultPage {
        guard query.kind == "workouts" || query.kind == "food" else {
            throw HistoryChatError.invalidLookup
        }
        let bounds = [query.from, query.through].compactMap { $0 }
        let dayParser = DateFormatter()
        dayParser.locale = Locale(identifier: "en_US_POSIX")
        dayParser.calendar = Calendar(identifier: .gregorian)
        dayParser.timeZone = TimeZone(secondsFromGMT: 0)
        dayParser.dateFormat = "yyyy-MM-dd"
        guard bounds.allSatisfy({ day in
            guard let date = dayParser.date(from: day) else { return false }
            return dayParser.string(from: date) == day
        }), (query.from ?? "") <= (query.through ?? "9999-12-31") else {
            throw HistoryChatError.invalidLookup
        }

        let isFood = query.kind == "food"
        let matches = (isFood ? food : workouts).filter { row in
            let day = row.date.map { String($0.prefix(10)) }
            if let from = query.from, (day ?? "") < from { return false }
            if let through = query.through, day == nil || (day ?? "") > through { return false }
            if let term = query.contains, !term.isEmpty {
                return row.name.localizedCaseInsensitiveContains(term)
                    || (row.sessionName?.localizedCaseInsensitiveContains(term) ?? false)
            }
            return true
        }
        let days = Set(matches.compactMap { $0.date.map { String($0.prefix(10)) } })
        let offset = min(max(query.offset ?? 0, 0), matches.count)
        let end = min(offset + 20, matches.count)
        let summary = query.summaryOnly == true
        return ResultPage(matchingRows: matches.count, firstDay: days.min(), lastDay: days.max(),
                          undatedRows: matches.filter { $0.date == nil }.count, loggedDays: days.count,
                          completedSessions: isFood ? nil : Set(matches.filter { $0.sessionCompleted == true }.compactMap(\.session)).count,
                          completedSets: isFood ? nil : matches.filter { $0.setCompleted == true }.count,
                          calories: isFood ? matches.reduce(0) { $0 + ($1.calories ?? 0) } : nil,
                          proteinGrams: isFood ? matches.reduce(0) { $0 + ($1.protein ?? 0) } : nil,
                          carbGrams: isFood ? matches.reduce(0) { $0 + ($1.carbs ?? 0) } : nil,
                          fatGrams: isFood ? matches.reduce(0) { $0 + ($1.fat ?? 0) } : nil,
                          nextOffset: !summary && end < matches.count ? end : nil,
                          rows: summary ? [] : Array(matches[offset..<end]))
    }
}
