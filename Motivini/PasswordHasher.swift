//
//  PasswordHasher.swift
//  Motivini
//
//  Created by James Di Cesare on 2025-08-26.
//


import Foundation
import CryptoKit

enum PasswordHasher {
    static func hash(_ password: String) -> String {
        let data = Data(password.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
