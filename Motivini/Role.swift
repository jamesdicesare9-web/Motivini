//
//  Role.swift
//  Motivini
//
//  Created by James Di Cesare on 2025-08-25.
//


import Foundation

// MARK: - Basics

enum Role: String, Codable, CaseIterable, Identifiable {
    case parent
    case child
    var id: String { rawValue }
}

struct Member: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var role: Role
    var avatar: String // SF Symbol or emoji
}

// MARK: - Punch-Card Series

enum SeriesWindow: String, Codable, CaseIterable, Identifiable {
    case weekly, daily, monthly
    var id: String { rawValue }
}

struct SeriesTemplate: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var category: String
    var threshold: Int           // e.g. 5 completions
    var awardPoints: Int         // e.g. 2 points
    var window: SeriesWindow     // weekly/daily/monthly
    var perDayLimit: Int         // e.g. 1 (or 2 for teeth AM/PM)
    var appliesToMemberIds: [UUID] // which kids
    var requiresPhoto: Bool = false
}

enum LogStatus: String, Codable, CaseIterable, Identifiable {
    case pending
    case approved
    case rejected
    var id: String { rawValue }
}

struct LogEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var templateId: UUID
    var childId: UUID
    var timestamp: Date
    var note: String?
    var status: LogStatus = .pending
}

// A "window instance" of a series for a child (e.g., this week)
struct SeriesInstance: Identifiable, Codable, Hashable {
    var id = UUID()
    var templateId: UUID
    var childId: UUID
    var windowStart: Date
    var windowEnd: Date
    var approvedCount: Int = 0
    var mintedAtThresholds: [Int] = [] // supports future multi-tier
}

// MARK: - Points, Rewards, Ledger

enum LedgerType: String, Codable, CaseIterable, Identifiable {
    case earn
    case redeem
    case adjust
    var id: String { rawValue }
}

struct LedgerEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var memberId: UUID
    var date: Date
    var type: LedgerType
    var points: Int            // positive for earn, negative for redeem
    var description: String
    var photoFilename: String? // for redeemed item photos
}

// A lightweight "reward redemption" view model item (derived from ledger)
struct RewardRedemption: Identifiable, Hashable {
    var id: UUID
    var date: Date
    var title: String
    var pointsSpent: Int
    var photoFilename: String?
}
