//
//  Role.swift
//  Motivini
//
//  Created by James Di Cesare on 2025-08-25.
//


import Foundation

enum Role: String, Codable, CaseIterable, Identifiable {
    case parent, child
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var emoji: String { self == .parent ? "🧑‍🍼" : "🧒" }
}
