/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 NWParameters extension
 */

// https://developer.apple.com/documentation/network/building_a_custom_peer-to-peer_protocol

import CryptoKit
import Foundation
import Network

@available(iOS 13.0, *)
extension NWParameters {
    // Create parameters for use in PeerConnection and PeerListener.
    convenience init(preSharedCode code: String, passcode: String, definition: NWProtocolFramer.Definition) {
        // coreLog.entered()

        // Create parameters with custom TLS and TCP options.
        self.init(tls: NWParameters.tlsOptions(code: code, passcode: passcode), tcp: NWParameters.tcpOption())

        // Enable using a peer-to-peer link.
        self.includePeerToPeer = true

        // Add your custom NetworkedLogger protocol to support NetworkedLogger messages.
        let options = NWProtocolFramer.Options(definition: definition)
        self.defaultProtocolStack.applicationProtocols.insert(options, at: 0)
    }

    // Customize TCP options to enable keepalives.
    private static func tcpOption() -> NWProtocolTCP.Options {
        // coreLog.entered(self)

        let tcpOptions = NWProtocolTCP.Options()

        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveIdle = 2 // sec

        return tcpOptions
    }

    // Create TLS options using a passcode to derive a pre-shared key.
    private static func tlsOptions(code: String, passcode: String) -> NWProtocolTLS.Options {
        // coreLog.entered(self)

        let tlsOptions = NWProtocolTLS.Options()

        let authenticationKey = SymmetricKey(data: passcode.data(using: .utf8)!)
        var authenticationCode = HMAC<SHA256>.authenticationCode(for: code.data(using: .utf8)!, using: authenticationKey)

        let authenticationDispatchData = withUnsafeBytes(of: &authenticationCode) { (ptr: UnsafeRawBufferPointer) in
            DispatchData(bytes: ptr)
        }

        sec_protocol_options_add_pre_shared_key(tlsOptions.securityProtocolOptions,
                                                authenticationDispatchData as __DispatchData,
                                                stringToDispatchData(code)! as __DispatchData)

        #if targetEnvironment(macCatalyst)
            sec_protocol_options_append_tls_ciphersuite(tlsOptions.securityProtocolOptions,
                                                        tls_ciphersuite_t(rawValue: UInt16(TLS_PSK_WITH_AES_128_GCM_SHA256))!)
        #else
            sec_protocol_options_append_tls_ciphersuite(tlsOptions.securityProtocolOptions,
                                                        tls_ciphersuite_t(rawValue: TLS_PSK_WITH_AES_128_GCM_SHA256)!)
        #endif

        return tlsOptions
    }

    // Create a utility function to encode strings as pre-shared key data.
    private static func stringToDispatchData(_ string: String) -> DispatchData? {
        // coreLog.entered(self)

        guard let stringData = string.data(using: .unicode) else {
            return nil
        }

        let dispatchData = withUnsafeBytes(of: stringData) { (ptr: UnsafeRawBufferPointer) in
            DispatchData(bytes: UnsafeRawBufferPointer(start: ptr.baseAddress, count: stringData.count))
        }

        return dispatchData
    }
}
