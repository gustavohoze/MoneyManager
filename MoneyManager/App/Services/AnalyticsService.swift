import Foundation

enum AnalyticsPropertyValue: Codable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
            return
        }
        if let value = try? container.decode(Int.self) {
            self = .int(value)
            return
        }
        if let value = try? container.decode(Double.self) {
            self = .double(value)
            return
        }
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
            return
        }

        throw DecodingError.typeMismatch(
            AnalyticsPropertyValue.self,
            DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported analytics property value")
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        }
    }

    var rawValue: Any {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return value
        case .double(let value):
            return value
        case .bool(let value):
            return value
        }
    }
}

protocol AnalyticsTracking {
    func track(_ event: AnalyticsEvent)
    func track(_ event: AnalyticsEvent, properties: [String: AnalyticsPropertyValue])
    func flush(completion: ((Bool) -> Void)?)
    func allEvents() -> [AnalyticsEvent]
}

extension AnalyticsTracking {
    func track(_ event: AnalyticsEvent) {
        track(event, properties: [:])
    }

    func flush(completion: ((Bool) -> Void)? = nil) {
        completion?(true)
    }
}

final class InMemoryAnalyticsService: AnalyticsTracking {
    private var events: [AnalyticsEvent] = []

    func track(_ event: AnalyticsEvent, properties: [String: AnalyticsPropertyValue]) {
        _ = properties
        events.append(event)
    }

    func allEvents() -> [AnalyticsEvent] {
        events
    }
}

struct SupabaseAnalyticsConfiguration {
    let baseURL: String
    let anonKey: String
    let tableName: String

    static func fromBundle(_ bundle: Bundle = .main) -> SupabaseAnalyticsConfiguration? {
        guard
            let baseURL = bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let anonKey = bundle.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
            !baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !anonKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        let configuredTableName = (bundle.object(forInfoDictionaryKey: "SUPABASE_ANALYTICS_TABLE") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let tableName: String
        if let configuredTableName, !configuredTableName.isEmpty {
            tableName = configuredTableName
        } else {
            tableName = "analytics_events"
        }
        return SupabaseAnalyticsConfiguration(
            baseURL: baseURL,
            anonKey: anonKey,
            tableName: tableName
        )
    }
}

private struct BufferedAnalyticsEvent: Codable, Equatable {
    let eventID: String
    let userID: String
    let sessionID: String
    let eventName: String
    let eventTimestamp: Date
    let properties: [String: AnalyticsPropertyValue]
}

private protocol AnalyticsIdentityProviding {
    func userID() -> String
}

private struct UserDefaultsAnalyticsIdentityProvider: AnalyticsIdentityProviding {
    private let defaults: UserDefaults
    private let key = "analytics.userID"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func userID() -> String {
        if let existing = defaults.string(forKey: key), !existing.isEmpty {
            return existing
        }
        let generated = UUID().uuidString.lowercased()
        defaults.set(generated, forKey: key)
        return generated
    }
}

private protocol AnalyticsEventTransporting {
    func insert(events: [BufferedAnalyticsEvent], completion: @escaping (Bool) -> Void)
}

private struct SupabaseAnalyticsTransport: AnalyticsEventTransporting {
    let configuration: SupabaseAnalyticsConfiguration
    let session: URLSession

    init(configuration: SupabaseAnalyticsConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    func insert(events: [BufferedAnalyticsEvent], completion: @escaping (Bool) -> Void) {
        guard !events.isEmpty else {
            completion(true)
            return
        }

        let base = configuration.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(base)/rest/v1/\(configuration.tableName)") else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(configuration.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(configuration.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        let formatter = ISO8601DateFormatter()
        let payload: [[String: Any]] = events.map { event in
            var properties = event.properties.mapValues { $0.rawValue }
            properties["client_event_id"] = event.eventID

            return [
                "user_id": event.userID,
                "session_id": event.sessionID,
                "event_name": event.eventName,
                "event_timestamp": formatter.string(from: event.eventTimestamp),
                "properties": properties
            ]
        }

        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            completion(false)
            return
        }

        request.httpBody = body

        session.dataTask(with: request) { data, response, error in
            guard error == nil else {
#if DEBUG
                print("[Analytics] Supabase insert network error: \(error!.localizedDescription)")
#endif
                completion(false)
                return
            }

            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
#if DEBUG
                print("[Analytics] Supabase insert missing HTTP response")
#endif
                completion(false)
                return
            }

#if DEBUG
            if !(200...299).contains(statusCode) {
                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                print("[Analytics] Supabase insert failed with status \(statusCode). Body: \(body)")
            }
#endif

            completion((200...299).contains(statusCode))
        }.resume()
    }
}

private final class BufferedSupabaseAnalyticsService: AnalyticsTracking {
    private enum StorageKey {
        static let queue = "analytics.buffered.queue.v1"
    }

    private let transport: AnalyticsEventTransporting
    private let identityProvider: AnalyticsIdentityProviding
    private let defaults: UserDefaults
    private let batchSize: Int
    private let workQueue = DispatchQueue(label: "MoneyManager.BufferedSupabaseAnalyticsService")
    private let sessionID: String

    private var trackedEvents: [AnalyticsEvent] = []
    private var bufferedEvents: [BufferedAnalyticsEvent]
    private var isFlushing = false
    private var pendingFlushCompletions: [((Bool) -> Void)] = []

    init(
        transport: AnalyticsEventTransporting,
        identityProvider: AnalyticsIdentityProviding,
        defaults: UserDefaults = .standard,
        batchSize: Int = 20,
        sessionID: String = UUID().uuidString.lowercased()
    ) {
        self.transport = transport
        self.identityProvider = identityProvider
        self.defaults = defaults
        self.batchSize = max(1, batchSize)
        self.sessionID = sessionID
        self.bufferedEvents = Self.loadQueue(from: defaults)
    }

    func track(_ event: AnalyticsEvent, properties: [String: AnalyticsPropertyValue]) {
        workQueue.async {
            self.trackedEvents.append(event)
            self.bufferedEvents.append(
                BufferedAnalyticsEvent(
                    eventID: UUID().uuidString.lowercased(),
                    userID: self.identityProvider.userID(),
                    sessionID: self.sessionID,
                    eventName: event.rawValue,
                    eventTimestamp: Date(),
                    properties: properties
                )
            )
            self.persistQueue()

            if self.bufferedEvents.count >= self.batchSize {
                self.flushInternal(completion: nil)
            }
        }
    }

    func allEvents() -> [AnalyticsEvent] {
        workQueue.sync {
            trackedEvents
        }
    }

    func flush(completion: ((Bool) -> Void)? = nil) {
        workQueue.async {
            self.flushInternal(completion: completion)
        }
    }

    private func flushInternal(completion: ((Bool) -> Void)?) {
        if let completion {
            pendingFlushCompletions.append(completion)
        }

        guard !isFlushing else {
            return
        }

        guard !bufferedEvents.isEmpty else {
            finishFlush(success: true)
            return
        }

        isFlushing = true
        sendNextBatch()
    }

    private func sendNextBatch() {
        guard !bufferedEvents.isEmpty else {
            finishFlush(success: true)
            return
        }

        let batch = Array(bufferedEvents.prefix(batchSize))
        transport.insert(events: batch) { success in
            self.workQueue.async {
                guard success else {
                    self.finishFlush(success: false)
                    return
                }

                self.bufferedEvents.removeFirst(batch.count)
                self.persistQueue()
                self.sendNextBatch()
            }
        }
    }

    private func finishFlush(success: Bool) {
        isFlushing = false
        let completions = pendingFlushCompletions
        pendingFlushCompletions.removeAll()
        completions.forEach { $0(success) }
    }

    private func persistQueue() {
        guard let data = try? JSONEncoder().encode(bufferedEvents) else {
            return
        }
        defaults.set(data, forKey: StorageKey.queue)
    }

    private static func loadQueue(from defaults: UserDefaults) -> [BufferedAnalyticsEvent] {
        guard
            let data = defaults.data(forKey: StorageKey.queue),
            let events = try? JSONDecoder().decode([BufferedAnalyticsEvent].self, from: data)
        else {
            return []
        }
        return events
    }
}

enum AnalyticsServiceFactory {
    static func makeDefault(bundle: Bundle = .main) -> AnalyticsTracking {
        guard let configuration = SupabaseAnalyticsConfiguration.fromBundle(bundle) else {
            return InMemoryAnalyticsService()
        }

#if DEBUG
        let batchSize = 1
#else
        let batchSize = 20
#endif

        return BufferedSupabaseAnalyticsService(
            transport: SupabaseAnalyticsTransport(configuration: configuration),
            identityProvider: UserDefaultsAnalyticsIdentityProvider(),
            batchSize: batchSize
        )
    }
}
