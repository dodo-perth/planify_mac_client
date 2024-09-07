// Models.swift

import Foundation

struct TokenResponse: Codable {
    let token: String
    let user_id: Int
    let email: String
}
