//
//  ApiService.swift
//  Banter-iOS
//

import Foundation
import Network

/// Errors the app can actually explain to the user.
enum ApiError: LocalizedError {
    case offline
    case http(Int)
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .offline: "The device is offline."
        case .http(let status): "The server answered with status \(status)."
        case .decoding(let detail): "The response had an unexpected shape: \(detail)."
        }
    }
}

/// Thin wrapper over URLSession: GET a URL and decode the JSON into whatever type the caller asks for.
protocol ApiService {
    func get<T: Decodable>(_ url: URL) async throws -> T
}

extension ApiService {
    func get<T: Decodable>(_ url: URL) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw ApiError.offline
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ApiError.http(http.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            throw ApiError.decoding(describe(error))
        }
    }

    /// Turns a DecodingError into "missing key 'wins' at children[0].standings" instead of a wall of text.
    private func describe(_ error: DecodingError) -> String {
        func path(_ context: DecodingError.Context) -> String {
            context.codingPath.map { $0.intValue.map { "[\($0)]" } ?? $0.stringValue }.joined(separator: ".")
        }
        switch error {
        case .keyNotFound(let key, let context): return "missing key '\(key.stringValue)' at \(path(context))"
        case .typeMismatch(let type, let context): return "expected \(type) at \(path(context))"
        case .valueNotFound(let type, let context): return "null where \(type) expected at \(path(context))"
        case .dataCorrupted(let context): return "corrupt data at \(path(context))"
        @unknown default: return "\(error)"
        }
    }
}

/// Answers "are we online right now?" by watching the network path.
///
/// Main-actor bound so the flag has one home: the path monitor writes it there, and tools read it with `await`.
@MainActor
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private(set) var isOnline = false
    private let monitor = NWPathMonitor()

    private init() {
        monitor.pathUpdateHandler = { path in
            Task { @MainActor in
                NetworkMonitor.shared.isOnline = path.status == .satisfied
            }
        }
        monitor.start(queue: DispatchQueue(label: "banter.network-monitor"))
        isOnline = monitor.currentPath.status == .satisfied
    }
}
