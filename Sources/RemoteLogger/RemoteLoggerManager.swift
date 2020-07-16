//
//  RemoteLoggerManager.swift
//  RemoteLoggerManager
//
//  Created by k_terada on 2020/06/21.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import Network

public struct AdvertiserInfo {
    let name: String
    let type: String?
    let domain: String?
    let hashValueRef: Int
}

@available(iOS 13.0, *)
public protocol RemoteLoggerReceiveDelegate: AnyObject {
    func ready(_ sender: RemoteLoggerManager)
    func failed(_ sender: RemoteLoggerManager)
    func received(_ sender: RemoteLoggerManager, log: String?)
    func received(_ sender: RemoteLoggerManager, control: String?)
}

public protocol RemoteLoggerBrowserDelegate: AnyObject {
    func changed(advertisers: [AdvertiserInfo])
    func ready()
}

@available(iOS 13.0, *)
public class RemoteLoggerManager {
    public static let shared = RemoteLoggerManager()
    public init() {} // No need to be a singleton

    private var networkBrowser: NetworkBrowser?
    private var networkAdvertiser: NetworkAdvertiser?
    private(set) var networkConnection: NetworkConnection?

    private weak var listener: RemoteLoggerBrowserDelegate?
    private weak var receiver: RemoteLoggerReceiveDelegate?

    // Which advertiser to be connected is selected by upper layer module.
    public var selectedAdvertiser: AdvertiserInfo?

    private var results: [NWBrowser.Result] = [NWBrowser.Result]()
    private(set) var advertisers = [AdvertiserInfo]()

    private var advertiserType = "_remotelogger._tcp"
    private var preSharedCode = "preSharedCode"
    private var advertisingName: String = "DefaultAdvertisingName"
    private var passcode: String = ""

    public func setPreSharedCode(advertiserType: String, preSharedCode: String) {
        self.advertiserType = advertiserType
        self.preSharedCode = preSharedCode
    }

    public func cancelConnection() {
        // netlog.entered(self)

        if let networkConnection = self.networkConnection {
            networkConnection.cancel()
        }
        self.networkConnection = nil
    }

    public var isNetworkConnected: Bool {
        self.networkConnection != nil
    }
}

// MARK: - Advertiser

@available(iOS 13.0, *)
extension RemoteLoggerManager {
    public func startAdvertiser(advertisingName name: String, passcode: String, receiver: RemoteLoggerReceiveDelegate) {
        // netlog.entered(self)

        advertisingName = name
        self.receiver = receiver

        if let listener = networkAdvertiser {
            // If your app is already listening, just update the name.
            listener.change(advertisingName: advertisingName)
        }
        else {
            // If your app is not yet listening, start a new listener.
            networkAdvertiser = NetworkAdvertiser().start(
                type: advertiserType,
                advertisingName: advertisingName,
                preSharedCode: preSharedCode,
                passcode: passcode,
                definition: RemoteLoggerProtocol.definition,
                advertiser: self, // NetworkAdvertiserDelegate
                connector: self // NetworkConnectionDelegate
            )
        }
    }
}

// MARK: - Browser extension

// BrowserはNetworkConnectionに直接接続する

@available(iOS 13.0, *)
extension RemoteLoggerManager {
    public func browseAdvertiser(listener: RemoteLoggerBrowserDelegate) {
        // netlog.entered(self)

        self.listener = listener

        networkBrowser = NetworkBrowser()
            .start(
                type: advertiserType,
                delegate: self // NetworkBrowserDelegate
            )
    }

    public func connectToAdvertiser(passcode: String) {
        // netlog.entered(self)

        guard let selectedAdvertiser = selectedAdvertiser else { return }

        for result in self.results {
            let peerEndpoint = result.endpoint
            if peerEndpoint.hashValue == selectedAdvertiser.hashValueRef {
                connectToAdvertiser(endpoint: result.endpoint, interface: result.interfaces.first, passcode: passcode, definition: RemoteLoggerProtocol.definition)
                return
            }
        }
    }

    private func connectToAdvertiser(endpoint: NWEndpoint, interface: NWInterface?, passcode: String, definition: NWProtocolFramer.Definition) {
        // netlog.entered(self)

        // Client Network Connection
        networkConnection = NetworkConnection(
            endpoint: endpoint,
            interface: interface,
            preSharedCode: preSharedCode,
            passcode: passcode,
            definition: definition,
            connector: self // NetworkConnectionDelegate
        )
    }

    public func setReceiverToAdvertiser(_ receiver: RemoteLoggerReceiveDelegate) -> Bool {
        // netlog.entered(self)

        guard let networkConnection = networkConnection else { return false }

        self.receiver = receiver

        networkConnection.connector = self

        return networkConnection.initiatedConnection
    }

    public func getAdvertiserName() -> String? {
        // netlog.entered(self)

        guard let selectedAdvertiser = selectedAdvertiser else { return nil }

        for result in self.results {
            let peerEndpoint = result.endpoint
            if peerEndpoint.hashValue == selectedAdvertiser.hashValueRef {
                return selectedAdvertiser.name
            }
        }

        return nil
    }
}

// MARK: - Browser NetworkBrowserDelegate

@available(iOS 13.0, *)
extension RemoteLoggerManager: NetworkBrowserDelegate {
    public func changed(browser: NetworkBrowser, results: Set<NWBrowser.Result>) {
        // netlog.entered(self)

        var foundSelectedAdvertiser = false

        self.results = [NWBrowser.Result]()
        self.advertisers = [AdvertiserInfo]()

        // Choose advertiser except myself
        for result in results {
            if case let NWEndpoint.service(name: name, type: type, domain: domain, interface: _) = result.endpoint {
                if name != self.advertisingName {
                    // netlog.debug("NetworkBrowser found \(name)")
                    self.results.append(result)
                    let advertiser = AdvertiserInfo(name: name, type: type, domain: domain, hashValueRef: result.endpoint.hashValue)
                    if advertiser.hashValueRef == selectedAdvertiser?.hashValueRef {
                        foundSelectedAdvertiser = true
                    }
                    advertisers.append(advertiser)
                }
            }
        }

        if selectedAdvertiser != nil, !foundSelectedAdvertiser {
            // may be disconnected
            selectedAdvertiser = nil
            cancelConnection()
        }

        listener?.changed(advertisers: advertisers)
    }
}

// MARK: - Both

// NetworkListenerDelegateとあるけど、どちらかも呼ばれます。
// Listenerだけがconnected()を使います。
@available(iOS 13.0, *)
extension RemoteLoggerManager: NetworkAdvertiserDelegate {
    public func connected(_ connection: NetworkConnection) {
        // netlog.entered(self)

        if receiver != nil {
            return
        }

        // Advertiserは接続されると、networkConnectionが上書きされる

        networkConnection = connection
        networkConnection?.connector = self
    }
}

@available(iOS 13.0, *)
extension RemoteLoggerManager: NetworkConnectionDelegate {
    // When a connection becomes ready, move into RemoteLogger mode.
    public func ready(connection: NetworkConnection) {
        // netlog.entered(self)

        if let receiver = receiver {
            receiver.ready(self)
            return
        }

        // これで画面を遷移する。遷移すると上書きされる
        listener?.ready()
    }

    // Ignore connection failures and messages prior to starting a RemoteLogger.
    public func failed(connection: NetworkConnection) {
        // netlog.entered(self)

        self.networkConnection = nil

        if let receiver = receiver {
            receiver.failed(self)
            return
        }
    }

    public func canceled(connection: NetworkConnection) {
        // netlog.entered(self)

        self.networkConnection = nil

        if let receiver = receiver {
            receiver.failed(self)
            return
        }
    }

    public func received(connection: NetworkConnection, content: Data?, message: NWProtocolFramer.Message) {
        // netlog.entered(self)

        if let receiver = receiver {
            guard let content = content else {
                return
            }
            switch message.remoteLoggerMessageType {
                case .invalid:
                    // netlog.error("Received invalid message")
                    break
                case .log:
                    let log_message = String(data: content, encoding: .unicode)
                    receiver.received(self, log: log_message)
                case .control:
                    let control_message = String(data: content, encoding: .unicode)
                    receiver.received(self, control: control_message)
            }
            return
        }
    }
}

@available(iOS 13.0, *)
extension RemoteLoggerManager {
    public func sendLog(_ message: String) {
        // netlog.entered(self)

        guard isNetworkConnected else { return }

        networkConnection?.sendLog(message)
    }

    public func sendControl(_ control: String) {
        // netlog.entered(self)

        guard isNetworkConnected else { return }

        networkConnection?.sendControl(control)
    }
}
