//
//  DataStore.swift
//  Motivini
//
//  Created by James Di Cesare on 2025-08-25.
//


import Foundation
import UIKit

final class DataStore {
    static let shared = DataStore()
    private init() {}

    private let fileName = "app_model.json"

    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(fileName)
    }

    func save(_ state: PersistedState) {
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Save error:", error)
        }
    }

    func load() -> PersistedState? {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode(PersistedState.self, from: data)
            return decoded
        } catch {
            return nil
        }
    }

    // Save an image to Documents and return the filename.
    func saveImage(_ uiImage: UIImage) -> String? {
        guard let data = uiImage.jpegData(compressionQuality: 0.8) else { return nil }
        let name = UUID().uuidString + ".jpg"
        let url = imageURL(for: name)
        do {
            try data.write(to: url, options: .atomic)
            return name
        } catch {
            print("Image save error:", error)
            return nil
        }
    }

    func imageURL(for filename: String) -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(filename)
    }
}

// MARK: - Persisted App State container (Codable)

struct PersistedState: Codable {
    var members: [Member]
    var seriesTemplates: [SeriesTemplate]
    var logs: [LogEntry]
    var seriesInstances: [SeriesInstance]
    var ledger: [LedgerEntry]
    var parentPIN: String
    var selectedChildId: UUID?
}
