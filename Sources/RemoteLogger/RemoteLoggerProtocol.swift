/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 RemoteLogger Protocol
 */

// https://developer.apple.com/documentation/network/building_a_custom_peer-to-peer_protocol

import Foundation
import Network

let remoteLoggerProtocolFramerLable: String = "RemoteLoggerProtocol"

// Define the types of commands your NetworkedLogger will use.
enum RemoteLoggerMessageType: UInt32 {
    case invalid = 0
    case log = 1
    case control = 2

    var identifier: String {
        switch self {
            case .invalid:
                return "invalid"
            case .log:
                return "log"
            case .control:
                return "control"
        }
    }
}

@available(iOS 13.0, *)
class RemoteLoggerProtocol: NWProtocolFramerImplementation {
    // Create a global definition of your NetworkedLogger protocol to add to connections.
    static let definition = NWProtocolFramer.Definition(implementation: RemoteLoggerProtocol.self)

    // Set a name for your protocol for use in debugging.
    static var label: String { remoteLoggerProtocolFramerLable }

    // Set the default behavior for most framing protocol functions.
    required init(framer: NWProtocolFramer.Instance) {}
    func start(framer: NWProtocolFramer.Instance) -> NWProtocolFramer.StartResult { .ready }
    func wakeup(framer: NWProtocolFramer.Instance) {}
    func stop(framer: NWProtocolFramer.Instance) -> Bool { true }
    func cleanup(framer: NWProtocolFramer.Instance) {}

    // Whenever the application sends a message, add your protocol header and forward the bytes.
    func handleOutput(framer: NWProtocolFramer.Instance, message: NWProtocolFramer.Message, messageLength: Int, isComplete: Bool) {
        // Extract the type of message.
        let type = message.networkedLoggerMessageType

        // Create a header using the type and length.
        let header = NetworkedLoggerProtocolHeader(type: type.rawValue, length: UInt32(messageLength))

        // Write the header.
        framer.writeOutput(data: header.encodedData)

        // Ask the connection to insert the content of the application message after your header.
        do {
            try framer.writeOutputNoCopy(length: messageLength)
        }
        catch {
            // coreLog.error("Hit error writing \(error)")
        }
    }

    // Whenever new bytes are available to read, try to parse out your message format.
    func handleInput(framer: NWProtocolFramer.Instance) -> Int {
        while true {
            // Try to read out a single header.
            var tempHeader: NetworkedLoggerProtocolHeader?
            let headerSize = NetworkedLoggerProtocolHeader.encodedSize
            let parsed = framer.parseInput(minimumIncompleteLength: headerSize,
                                           maximumLength: headerSize) { (buffer, _) -> Int in
                guard let buffer = buffer else {
                    return 0
                }
                if buffer.count < headerSize {
                    return 0
                }
                tempHeader = NetworkedLoggerProtocolHeader(buffer)
                return headerSize
            }

            // If you can't parse out a complete header, stop parsing and ask for headerSize more bytes.
            guard parsed, let header = tempHeader else {
                return headerSize
            }

            // Create an object to deliver the message.
            var messageType = RemoteLoggerMessageType.invalid
            if let parsedMessageType = RemoteLoggerMessageType(rawValue: header.type) {
                messageType = parsedMessageType
            }
            let message = NWProtocolFramer.Message(networkedLoggerMessageType: messageType)

            // Deliver the body of the message, along with the message object.
            if !framer.deliverInputNoCopy(length: Int(header.length), message: message, isComplete: true) {
                return 0
            }
        }
    }
}

// Extend framer messages to handle storing your command types in the message metadata.
@available(iOS 13.0, *)
extension NWProtocolFramer.Message {
    convenience init(networkedLoggerMessageType: RemoteLoggerMessageType) {
        self.init(definition: RemoteLoggerProtocol.definition)
        self.networkedLoggerMessageType = networkedLoggerMessageType
    }

    var networkedLoggerMessageType: RemoteLoggerMessageType {
        get {
            if let type = self["NetworkedLoggerMessageType"] as? RemoteLoggerMessageType {
                return type
            }
            else {
                return .invalid
            }
        }
        set {
            self["NetworkedLoggerMessageType"] = newValue
        }
    }
}

// Define a protocol header struct to help encode and decode bytes.
struct NetworkedLoggerProtocolHeader: Codable {
    let type: UInt32
    let length: UInt32

    init(type: UInt32, length: UInt32) {
        self.type = type
        self.length = length
    }

    init(_ buffer: UnsafeMutableRawBufferPointer) {
        var tempType: UInt32 = 0
        var tempLength: UInt32 = 0
        withUnsafeMutableBytes(of: &tempType) { typePtr in
            typePtr.copyMemory(from: UnsafeRawBufferPointer(start: buffer.baseAddress!.advanced(by: 0),
                                                            count: MemoryLayout<UInt32>.size))
        }
        withUnsafeMutableBytes(of: &tempLength) { lengthPtr in
            lengthPtr.copyMemory(from: UnsafeRawBufferPointer(start: buffer.baseAddress!.advanced(by: MemoryLayout<UInt32>.size),
                                                              count: MemoryLayout<UInt32>.size))
        }
        type = tempType
        length = tempLength
    }

    var encodedData: Data {
        var tempType = type
        var tempLength = length
        var data = Data(bytes: &tempType, count: MemoryLayout<UInt32>.size)
        data.append(Data(bytes: &tempLength, count: MemoryLayout<UInt32>.size))
        return data
    }

    static var encodedSize: Int {
        MemoryLayout<UInt32>.size * 2
    }
}

@available(iOS 13.0, *)
extension NetworkConnection {
    // Handle sending a "select character" message.
    public func sendLog(_ log_message: String) {
        // Create a message object to hold the command type.
        let message = NWProtocolFramer.Message(networkedLoggerMessageType: .log)

        send(log_message, identifier: RemoteLoggerMessageType.log.identifier, messages: [message])
    }

    // Handle sending a "move" message.
    public func sendControl(_ control: String) {
        // Create a message object to hold the command type.
        let message = NWProtocolFramer.Message(networkedLoggerMessageType: .control)

        send(control, identifier: RemoteLoggerMessageType.control.identifier, messages: [message])
    }
}
