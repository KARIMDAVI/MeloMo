// BackendClient.swift
// URLSession-based client for the MeloMo Python backend.
// No Alamofire needed — URLSession handles async/await perfectly fine for a 2-endpoint API.
// Decision: singleton over injected dependency. At this scale, one backend = one client.
import Foundation

final class BackendClient {
    static let shared = BackendClient()

    // Debug builds hit localhost so you can run the backend locally during dev.
    // After deploying to Render, update the production URL.
    #if DEBUG
    private let baseURL = URL(string: "http://localhost:8000")!
    #else
    private let baseURL = URL(string: "https://melomo-backend.onrender.com")!
    #endif

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    // MARK: - Mood Generate

    func generatePlaylist(input: String, sourceOverride: String? = nil) async throws -> MoodGenerateResponse {
        var req = URLRequest(url: baseURL.appending(path: "/mood/generate"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 15   // Render cold start can take ~3s; 15s is generous

        req.httpBody = try encoder.encode(MoodGenerateRequest(input: input, sourceOverride: sourceOverride))

        let (data, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw BackendError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return try decoder.decode(MoodGenerateResponse.self, from: data)
    }

    // MARK: - Export

    func exportPlaylist(tracks: [TrackResponse], destination: String,
                        authToken: String, playlistName: String,
                        userId: String? = nil) async throws -> ExportResponse {
        var req = URLRequest(url: baseURL.appending(path: "/playlist/export"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 30   // Exporting 25 tracks involves many downstream API calls

        let body = ExportRequest(tracks: tracks, destination: destination,
                                 authToken: authToken, playlistName: playlistName, userId: userId)
        req.httpBody = try encoder.encode(body)

        let (data, _) = try await URLSession.shared.data(for: req)
        return try decoder.decode(ExportResponse.self, from: data)
    }
}

// MARK: - Codable DTOs (mirrors backend models.py)
// Using .convertFromSnakeCase decoder so CodingKeys can be omitted for simple fields.

struct MoodGenerateRequest: Encodable {
    let input: String
    let sourceOverride: String?
}

struct MoodGenerateResponse: Decodable {
    let mood: String
    let category: String
    let energy: Double
    let explanation: String
    let source: String
    let topMoods: [MoodSuggestion]
    let tracks: [TrackResponse]
}

struct MoodSuggestion: Decodable {
    let mood: String
    let category: String
    let confidence: Double
}

struct TrackResponse: Codable {
    let id: String
    let title: String
    let artist: String
    let album: String?
    let duration: Double
    let streamUrl: String?
    let videoId: String?
    let artworkUrl: String?
    let source: String
    let energy: Double
    let matchReason: String

    /// Convert backend track to the iOS MusicTrack model.
    func toMusicTrack() -> MusicTrack {
        MusicTrack(
            id: id,
            title: title,
            artist: artist,
            album: album,
            artworkURL: artworkUrl.flatMap(URL.init),
            duration: duration,
            energy: energy,
            streamURL: streamUrl.flatMap(URL.init),
            matchReason: matchReason
        )
    }
}

struct ExportRequest: Encodable {
    let tracks: [TrackResponse]
    let destination: String
    let authToken: String
    let playlistName: String
    let userId: String?
}

struct ExportResponse: Decodable {
    let playlistId: String
    let matchedCount: Int
    let totalCount: Int
    let playlistUrl: String?
}

enum BackendError: LocalizedError {
    case serverError(Int)
    var errorDescription: String? {
        if case .serverError(let code) = self { return "Backend returned HTTP \(code)" }
        return "Unknown backend error"
    }
}
