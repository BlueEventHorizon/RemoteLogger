/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 Network Connection
 */

// https://developer.apple.com/documentation/network/building_a_custom_peer-to-peer_protocol

import Foundation
import Network

@available(iOS 13.0, *)
public protocol NetworkConnectionDelegate: AnyObject {
    func ready(connection: NetworkConnection)
    func failed(connection: NetworkConnection)
    func canceled(connection: NetworkConnection)
    func received(connection: NetworkConnection, content: Data?, message: NWProtocolFramer.Message)
}

@available(iOS 13.0, *)
public class NetworkConnection {
    public weak var connector: NetworkConnectionDelegate?
    private(set) var connection: NWConnection?
    private(set) var definition: NWProtocolFramer.Definition
    public let initiatedConnection: Bool

    // Create an outbound connection when the user initiates a connection.
    public init(
        endpoint: NWEndpoint,
        interface: NWInterface?,
        preSharedCode: String,
        passcode: String,
        definition: NWProtocolFramer.Definition,
        connector: NetworkConnectionDelegate
    ) {
        // coreLog.entered()

        let connection = NWConnection(to: endpoint, using: NWParameters(preSharedCode: preSharedCode, passcode: passcode, definition: definition))
        self.connection = connection
        self.definition = definition
        self.connector = connector

        self.initiatedConnection = true

        start()
    }

    // Handle an inbound connection when the user receives a connection request in PeerListener.
    public init(
        connection: NWConnection,
        definition: NWProtocolFramer.Definition,
        connector: NetworkConnectionDelegate
    ) {
        // coreLog.entered()

        self.connection = connection
        self.definition = definition
        self.connector = connector

        self.initiatedConnection = false

        start()
    }

    // Handle the user exiting the NetworkedLogger.
    public func cancel() {
        // coreLog.entered(self)

        if let connection = self.connection {
            connection.cancel()
            self.connection = nil
        }
    }

    // Handle starting the peer-to-peer connection for both inbound and outbound connections.
    private func start() {
        // coreLog.entered(self)

        guard let connection = connection else { return }

        connection.stateUpdateHandler = { newState in
            switch newState {
                case .setup:
                    // coreLog.info("initial state")

                case let .waiting(error):
                    // coreLog.error("no destination \(error.localizedDescription)")

                case .preparing:
                    // coreLog.info("waiting connection")

                case .ready:
                    // coreLog.info("\(connection) established")

                    // When the connection is ready, start receiving messages.
                    self.receive()

                    self.connector?.ready(connection: self)

                case let .failed(error):
                    // coreLog.error("\(connection) failed with \(error.localizedDescription)")

                    // Cancel the connection upon a failure.
                    connection.cancel()

                    self.connector?.failed(connection: self)

                case .cancelled:
                    // coreLog.info("cancelled")

                    connection.cancel()

                    self.connector?.canceled(connection: self)
            }
        }

        // Start the connection establishment.
        connection.start(queue: .main)
    }

    // Receive a message, deliver it to your connector, and continue receiving more messages.
    public func receive() {
        // coreLog.entered(self)

        guard let connection = connection else { return }

        connection.receiveMessage { [weak self] content, context, _, error in

            guard let self = self else { return }

            // Extract your message type from the received context.

            if let message = context?.protocolMetadata(definition: self.definition) as? NWProtocolFramer.Message {
                self.connector?.received(connection: self, content: content, message: message)

                if error == nil {
                    // Continue to receive more messages until you receive and error.
                    self.receive()
                }
            }
        }
    }

    public func send(_ dataString: String, identifier: String, messages: [NWProtocolFramer.Message]) {
        // coreLog.entered(self)

        guard let connection = connection else { return }

        let context = NWConnection.ContentContext(identifier: identifier, metadata: messages)

        // Send the application content along with the message.
        connection.send(content: dataString.data(using: .unicode), contentContext: context, isComplete: true, completion: .idempotent)
    }
}
