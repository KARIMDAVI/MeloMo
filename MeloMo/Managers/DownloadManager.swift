import Foundation
import Combine

@MainActor
final class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()
    
    @Published var downloadingTrackIds: Set<String> = []
    @Published var downloadedTrackIds: Set<String> = []
    
    private var session: URLSession!
    private let fileManager = FileManager.default
    private let downloadsFolder: URL
    
    // Mapping of Task to Track ID
    private var activeDownloads: [URLSessionDownloadTask: String] = [:]
    
    override init() {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.downloadsFolder = docs.appendingPathComponent("JamendoVault", isDirectory: true)
        
        super.init()
        
        if !fileManager.fileExists(atPath: downloadsFolder.path) {
            try? fileManager.createDirectory(at: downloadsFolder, withIntermediateDirectories: true)
        }
        
        self.session = URLSession(configuration: .background(withIdentifier: "com.melomo.download"),
                                  delegate: self,
                                  delegateQueue: .main)
        
        loadDownloadedTracks()
    }
    
    func download(_ track: MusicTrack) {
        guard let url = track.streamURL, !downloadedTrackIds.contains(track.id) else { return }
        
        let task = session.downloadTask(with: url)
        activeDownloads[task] = track.id
        downloadingTrackIds.insert(track.id)
        task.resume()
    }
    
    func localURL(for trackId: String) -> URL? {
        let fileURL = downloadsFolder.appendingPathComponent("\(trackId).mp3")
        return fileManager.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
    
    func delete(_ trackId: String) {
        let fileURL = downloadsFolder.appendingPathComponent("\(trackId).mp3")
        try? fileManager.removeItem(at: fileURL)
        downloadedTrackIds.remove(trackId)
    }
    
    private func loadDownloadedTracks() {
        guard let files = try? fileManager.contentsOfDirectory(at: downloadsFolder, includingPropertiesForKeys: nil) else { return }
        let ids = files.compactMap { $0.lastPathComponent.replacingOccurrences(of: ".mp3", with: "") }
        downloadedTrackIds = Set(ids)
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let trackId = activeDownloads[downloadTask] else { return }
        
        let destination = downloadsFolder.appendingPathComponent("\(trackId).mp3")
        
        do {
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.moveItem(at: location, to: destination)
            
            DispatchQueue.main.async {
                self.downloadedTrackIds.insert(trackId)
                self.downloadingTrackIds.remove(trackId)
                self.activeDownloads.removeValue(forKey: downloadTask)
            }
        } catch {
            print("Download Move Error: \(error)")
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Download Task Error: \(error.localizedDescription)")
            if let downloadTask = task as? URLSessionDownloadTask,
               let trackId = activeDownloads[downloadTask] {
                DispatchQueue.main.async {
                    self.downloadingTrackIds.remove(trackId)
                    self.activeDownloads.removeValue(forKey: downloadTask)
                }
            }
        }
    }
}
