//
//  PushNotificationManager.swift
//  Motivini
//
//  Created by James Di Cesare on 2025-08-26.
//


import Foundation
import UserNotifications

final class PushNotificationManager {
static let shared = PushNotificationManager()
private init() {}

func requestPermission() async -> Bool {
do { return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) } catch { return false }
}
}