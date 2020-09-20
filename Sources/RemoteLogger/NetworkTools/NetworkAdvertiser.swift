/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 Implement Network Advertiser
 */

// https://developer.apple.com/documentation/network/building_a_custom_peer-to-peer_protocol

import Foundation
import Network

@available(iOS 13.0, *)
public protocol NetworkAdvertiserDelegate: AnyObject {
    func connected(_ connection: NetworkConnection)
}

@available(iOS 13.0, *)
public class NetworkAdvertiser {
    private weak var advertiser: NetworkAdvertiserDelegate?

    private weak var connector: NetworkConnectionDelegate?

    private var listener: NWListener!

    public private(set) var type: String
    public private(set) var preSharedCode: String
    public private(set) var definition: NWProtocolFramer.Definition

    public private(set) var name: String!
    public private(set) var passcode: String!

    // ここで、１個だけを接続するようにしているが、マルチで接続しても良い。
    // その場合は、cancel()はいらないし、networkConnectionを保持して判定する必要もない
    private var networkConnection: NetworkConnection?

    public init(
        type: String,
        preSharedCode: String,
        definition: NWProtocolFramer.Definition
    ) {
        self.type = type
        self.preSharedCode = preSharedCode
        self.definition = definition
    }

    // Start listening and advertising.
    @discardableResult
    public func start(
        advertisingName name: String,
        passcode: String,
        advertiser: NetworkAdvertiserDelegate?,
        connector: NetworkConnectionDelegate?
    ) -> Self {
        // internalLog.entered(self)

        self.name = name
        self.passcode = passcode

        self.advertiser = advertiser
        self.connector = connector

        if let listener = self.listener {
            listener.cancel()
            self.listener = nil
        }

        do {
            // Create the listener object.
            let listener = try NWListener(using: NWParameters(preSharedCode: preSharedCode, passcode: passcode, definition: definition))
            self.listener = listener

            // Set the service to advertise.
            listener.service = NWListener.Service(name: self.name, type: type)

            listener.stateUpdateHandler = { newState in
                switch newState {
                    case .ready:
                        internalLog.info("Listener ready on \(String(describing: listener.port))")

                    case let .failed(error):
                        // If the listener fails, re-start.
                        internalLog.error("Listener failed with \(error), restarting")
                        listener.cancel()
                        self.start(advertisingName: name, passcode: self.passcode, advertiser: self.advertiser, connector: self.connector)

                    case .setup:
                        internalLog.info("Listener setup")

                    case let .waiting(error):
                        internalLog.error("Listener waiting with \(error)")

                        guard let networkConnection = self.networkConnection else { return }

                        networkConnection.cancel()
                        self.networkConnection = nil

                    case .cancelled:
                        internalLog.warning("Listener cancelled")
                }
            }

            listener.newConnectionHandler = { newConnection in

                // ここで、１個だけを接続するようにしているが、マルチで接続しても良い。
                // その場合は、cancel()はいらないし、networkConnectionを保持して判定する必要もない
                if self.networkConnection == nil {
                    if let advertiser = self.advertiser, let connector = self.connector {
                        // Accept a new connection.
                        let connection = NetworkConnection(connection: newConnection, definition: self.definition, connector: connector)
                        self.networkConnection = connection

                        advertiser.connected(connection)
                    }
                }
                else {
                    // If a NetworkConnection is already in progress, reject it.
                    newConnection.cancel()
                }
            }

            // Start listening, and request updates on the main queue.
            listener.start(queue: .main)
        }
        catch {
            // internalLog.error("Failed to create listener")
            abort()
        }

        return self
    }

    // If the user changes their name, update the advertised name.
    public func change(advertisingName: String) {
        // internalLog.entered(self)

        self.name = advertisingName
        if let listener = listener {
            // Reset the service to advertise.
            listener.service = NWListener.Service(name: self.name, type: type)
        }
    }
}

