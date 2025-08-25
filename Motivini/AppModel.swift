//
//  AppModel.swift
//  Motivini
//
//  Created by James Di Cesare on 2025-08-25.
//


import Foundation
import SwiftUI

final class AppModel: ObservableObject {
    // MARK: - Published State
    @Published var members: [Member] = []
    @Published var seriesTemplates: [SeriesTemplate] = []
    @Published var logs: [LogEntry] = []
    @Published var seriesInstances: [SeriesInstance] = []
    @Published var ledger: [LedgerEntry] = []
    @Published var parentPIN: String = "1234" // default; change in Settings
    @Published var isParentMode: Bool = false
    @Published var selectedChildId: UUID?

    // MARK: - Init / Persist
    init() {
        if let loaded = DataStore.shared.load() {
            self.members = loaded.members
            self.seriesTemplates = loaded.seriesTemplates
            self.logs = loaded.logs
            self.seriesInstances = loaded.seriesInstances
            self.ledger = loaded.ledger
            self.parentPIN = loaded.parentPIN
            self.selectedChildId = loaded.selectedChildId
        } else {
            seed()
            persist()
        }
        if selectedChildId == nil {
            selectedChildId = members.first(where: { $0.role == .child })?.id
        }
    }

    func persist() {
        let state = PersistedState(
            members: members,
            seriesTemplates: seriesTemplates,
            logs: logs,
            seriesInstances: seriesInstances,
            ledger: ledger,
            parentPIN: parentPIN,
            selectedChildId: selectedChildId
        )
        DataStore.shared.save(state)
    }

    // MARK: - Seed Data
    func seed() {
        let parent = Member(name: "Alex", role: .parent, avatar: "person.fill")
        let child = Member(name: "Mia", role: .child, avatar: "face.smiling")
        members = [parent, child]

        func series(_ title: String, category: String, threshold: Int, award: Int, window: SeriesWindow = .weekly, perDay: Int = 1) -> SeriesTemplate {
            SeriesTemplate(title: title, category: category, threshold: threshold, awardPoints: award, window: window, perDayLimit: perDay, appliesToMemberIds: [child.id])
        }

        seriesTemplates = [
            series("Make Bed", category: "Room", threshold: 5, award: 2, perDay: 1),
            series("Load Dishwasher", category: "Kitchen", threshold: 5, award: 2, perDay: 1),
            series("Clear Table", category: "Kitchen", threshold: 5, award: 2, perDay: 1),
            series("Homework (20+ min)", category: "Learning", threshold: 5, award: 2, perDay: 1),
            series("Brush Teeth", category: "Hygiene", threshold: 10, award: 2, window: .weekly, perDay: 2)
        ]

        logs = []
        seriesInstances = []
        ledger = []
        parentPIN = "1234"
        selectedChildId = child.id
    }

    // MARK: - Helpers

    func children() -> [Member] { members.filter { $0.role == .child } }
    func parents() -> [Member] { members.filter { $0.role == .parent } }

    func balance(for childId: UUID) -> Int {
        ledger.filter { $0.memberId == childId }.map(\.points).reduce(0, +)
    }

    func pendingLogs(for childId: UUID?) -> [LogEntry] {
        logs.filter { $0.status == .pending && (childId == nil || $0.childId == childId!) }
            .sorted(by: { $0.timestamp < $1.timestamp })
    }

    func approvedCountForToday(childId: UUID, templateId: UUID, date: Date) -> Int {
        let cal = Calendar.current
        return logs.filter {
            $0.status == .approved &&
            $0.childId == childId &&
            $0.templateId == templateId &&
            cal.isDate($0.timestamp, inSameDayAs: date)
        }.count
    }

    func currentWindow(for window: SeriesWindow, reference: Date = Date()) -> (start: Date, end: Date) {
        let cal = Calendar.current
        switch window {
        case .daily:
            let start = cal.startOfDay(for: reference)
            let end = cal.date(byAdding: .day, value: 1, to: start)!
            return (start, end)
        case .weekly:
            let weekday = cal.component(.weekday, from: reference)
            let diffToMonday = (weekday + 5) % 7
            let start = cal.date(byAdding: .day, value: -diffToMonday, to: cal.startOfDay(for: reference))!
            let end = cal.date(byAdding: .day, value: 7, to: start)!
            return (start, end)
        case .monthly:
            let comps = cal.dateComponents([.year, .month], from: reference)
            let start = cal.date(from: comps)!
            let end = cal.date(byAdding: .month, value: 1, to: start)!
            return (start, end)
        }
    }

    func instance(for childId: UUID, template: SeriesTemplate, at date: Date = Date()) -> SeriesInstance {
        let win = currentWindow(for: template.window, reference: date)
        if let idx = seriesInstances.firstIndex(where: {
            $0.childId == childId && $0.templateId == template.id &&
            $0.windowStart == win.start && $0.windowEnd == win.end
        }) {
            return seriesInstances[idx]
        } else {
            let inst = SeriesInstance(templateId: template.id, childId: childId, windowStart: win.start, windowEnd: win.end, approvedCount: 0, mintedAtThresholds: [])
            seriesInstances.append(inst)
            persist()
            return inst
        }
    }

    private func updateInstance(_ updated: SeriesInstance) {
        if let idx = seriesInstances.firstIndex(where: { $0.id == updated.id }) {
            seriesInstances[idx] = updated
        } else {
            seriesInstances.append(updated)
        }
    }

    // MARK: - Child action: Log completion (creates PENDING)
    func childLogCompletion(childId: UUID, template: SeriesTemplate, note: String? = nil) {
        let log = LogEntry(templateId: template.id, childId: childId, timestamp: Date(), note: note, status: .pending)
        logs.append(log)
        persist()
        Haptics.lightTap()
    }

    // MARK: - Parent action: Approve / Reject
    func parentApprove(log: LogEntry) {
        guard let logIndex = logs.firstIndex(where: { $0.id == log.id }) else { return }
        guard let template = seriesTemplates.first(where: { $0.id == log.templateId }) else { return }

        // Enforce per-day limit
        let todaysApproved = approvedCountForToday(childId: log.childId, templateId: log.templateId, date: log.timestamp)
        if todaysApproved >= template.perDayLimit {
            logs[logIndex].status = .rejected
            persist()
            Haptics.warning()
            return
        }

        // Approve
        logs[logIndex].status = .approved

        // Increment instance count in correct window
        var inst = instance(for: log.childId, template: template, at: log.timestamp)
        let win = currentWindow(for: template.window, reference: log.timestamp)
        if inst.windowStart != win.start || inst.windowEnd != win.end {
            inst = SeriesInstance(templateId: template.id, childId: log.childId, windowStart: win.start, windowEnd: win.end, approvedCount: 0, mintedAtThresholds: [])
        }

        inst.approvedCount += 1

        // Mint points if threshold crossed in this window and not already minted
        if inst.approvedCount >= template.threshold && !inst.mintedAtThresholds.contains(template.threshold) {
            let entry = LedgerEntry(memberId: log.childId, date: Date(), type: .earn, points: template.awardPoints, description: "\(template.title) completed \(template.threshold)×", photoFilename: nil)
            ledger.append(entry)
            inst.mintedAtThresholds.append(template.threshold)
            Haptics.success()
        }

        updateInstance(inst)
        persist()
    }

    func parentReject(log: LogEntry) {
        if let idx = logs.firstIndex(where: { $0.id == log.id }) {
            logs[idx].status = .rejected
            persist()
            Haptics.warning()
        }
    }

    // MARK: - Redeem points (with optional photo)
    func redeem(childId: UUID, title: String, points: Int, image: UIImage?) {
        guard points > 0 else { return }
        let current = balance(for: childId)
        guard current >= points else { Haptics.error(); return }

        var photoName: String?
        if let image = image {
            photoName = DataStore.shared.saveImage(image)
        }

        let entry = LedgerEntry(memberId: childId, date: Date(), type: .redeem, points: -points, description: "Redeemed: \(title)", photoFilename: photoName)
        ledger.append(entry)
        persist()
        Haptics.success()
    }

    // MARK: - Derived data
    func redemptions(for childId: UUID) -> [RewardRedemption] {
        ledger.filter { $0.memberId == childId && $0.type == .redeem }
            .sorted { $0.date > $1.date }
            .map { RewardRedemption(id: $0.id, date: $0.date, title: $0.description.replacingOccurrences(of: "Redeemed: ", with: ""), pointsSpent: abs($0.points), photoFilename: $0.photoFilename) }
    }

    // MARK: - Parent Mode
    func unlockParentMode(pin: String) -> Bool {
        if pin == parentPIN {
            isParentMode = true
            Haptics.success()
            return true
        } else {
            Haptics.error()
            return false
        }
    }

    func lockParentMode() {
        isParentMode = false
    }
}
