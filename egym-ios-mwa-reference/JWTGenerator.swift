import Foundation
import Security

struct JWTGenerator {
    enum JWTError: Error {
        case invalidKey
        case signingFailed
    }

    /// Generate an RS256 JWT with `sub` = memberId, valid for 24 hours.
    static func generateMembershipJWT(memberId: String, privateKeyPEM: String) throws -> String {
        let privateKey = try loadPrivateKey(from: privateKeyPEM)

        let header = ["alg": "RS256", "typ": "JWT"]
        let now = Date()
        let payload: [String: Any] = [
            "sub": memberId,
            "iat": Int(now.timeIntervalSince1970),
            "exp": Int(now.addingTimeInterval(86400).timeIntervalSince1970)
        ]

        let headerData = try JSONSerialization.data(withJSONObject: header)
        let payloadData = try JSONSerialization.data(withJSONObject: payload)

        let headerB64 = base64URLEncode(headerData)
        let payloadB64 = base64URLEncode(payloadData)

        let signingInput = "\(headerB64).\(payloadB64)"
        guard let signingData = signingInput.data(using: .utf8) else {
            throw JWTError.signingFailed
        }

        let signature = try sign(data: signingData, with: privateKey)
        let signatureB64 = base64URLEncode(signature)

        return "\(headerB64).\(payloadB64).\(signatureB64)"
    }

    private static func loadPrivateKey(from pem: String) throws -> SecKey {
        let stripped = pem
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN RSA PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END RSA PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard var keyData = Data(base64Encoded: stripped) else {
            throw JWTError.invalidKey
        }

        // If the key is PKCS#8 wrapped (BEGIN PRIVATE KEY), strip the ASN.1 header
        // to get the raw PKCS#1 RSA key that SecKeyCreateWithData expects.
        if pem.contains("BEGIN PRIVATE KEY") {
            keyData = try stripPKCS8Header(keyData)
        }

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
        ]

        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error) else {
            if let err = error?.takeRetainedValue() {
                print("[JWTGenerator] SecKey creation failed: \(err)")
            }
            throw JWTError.invalidKey
        }
        return secKey
    }

    /// Strip the PKCS#8 ASN.1 header to extract the inner PKCS#1 RSA private key.
    /// PKCS#8 structure: SEQUENCE { INTEGER(version), SEQUENCE { OID, NULL }, OCTET STRING { PKCS#1 key } }
    private static func stripPKCS8Header(_ keyData: Data) throws -> Data {
        var index = 0
        let bytes = [UInt8](keyData)

        guard bytes.count > 0, bytes[index] == 0x30 else { throw JWTError.invalidKey }
        index += 1

        // Skip the outer SEQUENCE length
        index = skipASN1Length(bytes, index: index)

        // Expect INTEGER (version = 0)
        guard bytes[index] == 0x02 else { throw JWTError.invalidKey }
        index += 1
        let versionLength = Int(bytes[index])
        index += 1 + versionLength

        // Expect SEQUENCE (AlgorithmIdentifier)
        guard bytes[index] == 0x30 else { throw JWTError.invalidKey }
        index += 1
        let algIdLength = readASN1Length(bytes, index: &index)
        index += algIdLength

        // Expect OCTET STRING containing the PKCS#1 key
        guard bytes[index] == 0x04 else { throw JWTError.invalidKey }
        index += 1
        _ = readASN1Length(bytes, index: &index)

        // The rest is the PKCS#1 RSA private key
        return Data(bytes[index...])
    }

    private static func skipASN1Length(_ bytes: [UInt8], index: Int) -> Int {
        var idx = index
        _ = readASN1Length(bytes, index: &idx)
        return idx
    }

    private static func readASN1Length(_ bytes: [UInt8], index: inout Int) -> Int {
        guard index < bytes.count else { return 0 }
        if bytes[index] < 0x80 {
            let length = Int(bytes[index])
            index += 1
            return length
        } else {
            let numBytes = Int(bytes[index] & 0x7F)
            index += 1
            var length = 0
            for _ in 0..<numBytes {
                length = (length << 8) | Int(bytes[index])
                index += 1
            }
            return length
        }
    }

    private static func sign(data: Data, with key: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            key,
            .rsaSignatureMessagePKCS1v15SHA256,
            data as CFData,
            &error
        ) as Data? else {
            throw JWTError.signingFailed
        }
        return signature
    }

    private static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
