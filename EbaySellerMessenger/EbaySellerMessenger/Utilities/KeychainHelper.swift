import Foundation
import Security

final class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}

    private let service = "com.ebaymessenger.app"

    func save(_ data: Data, key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess {
            throw KeychainError.saveFailed(status)
        }
    }

    func load(key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.loadFailed(status)
        }
        return data
    }

    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    func saveToken(_ token: EbayToken) throws {
        let data = try JSONEncoder().encode(token)
        try save(data, key: "ebay_token")
    }

    func loadToken() -> EbayToken? {
        guard let data = try? load(key: "ebay_token") else { return nil }
        return try? JSONDecoder().decode(EbayToken.self, from: data)
    }

    func saveCredentials(_ credentials: (clientId: String, clientSecret: String)) throws {
        let dict = ["clientId": credentials.clientId, "clientSecret": credentials.clientSecret]
        let data = try JSONEncoder().encode(dict)
        try save(data, key: "ebay_credentials")
    }

    func loadCredentials() -> (clientId: String, clientSecret: String)? {
        guard let data = try? load(key: "ebay_credentials"),
              let dict = try? JSONDecoder().decode([String: String].self, from: data),
              let clientId = dict["clientId"],
              let clientSecret = dict["clientSecret"] else { return nil }
        return (clientId, clientSecret)
    }

    func clearAll() {
        delete(key: "ebay_token")
        delete(key: "ebay_credentials")
    }
}

enum KeychainError: Error, LocalizedError {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status): return "Keychain save failed: \(status)"
        case .loadFailed(let status): return "Keychain load failed: \(status)"
        }
    }
}
