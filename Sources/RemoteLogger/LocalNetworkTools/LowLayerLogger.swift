//
//  LowLayerLogger.swift
//  BwTools
//
//  Created by k_terada on 2020/07/07.
//  Copyright © 2020 k2moons. All rights reserved.
//

import Foundation
import os

let lllog = LowLayerLogger(prefix: "", enable: true)

class LowLayerLogger {
    let prefix: String
    let enable: Bool

    init(prefix: String = "", enable: Bool = true) {
        self.prefix = prefix
        self.enable = enable
    }

    func log(
        level: Level,
        message: Any,
        instance: Any,
        file: String,
        function: String,
        line: Int
    ) {
        guard enable else { return }

        let _message: String = (message as? String) ?? String(describing: message)

        let formattedMessage = formatter(
            level: level,
            message: _message,
            instance: instance,
            file: file,
            function: function,
            line: line
        )

        os_log("%s %s", prefix, formattedMessage)

        if level == .fatal {
            assert(false, formattedMessage)
        }
    }

    private func formatter(
        level: Level,
        message: String,
        instance: Any,
        file: String,
        function: String,
        line: Int

    ) -> String {
        // ----------------------
        // PreFix

        var string: String = "\(preFix(level))"

        // ----------------------
        // Date / Thread

        switch level {
            case .trace: break
            case .info: break
            default:
                // Date
//                let timestamp: String = Date().string(dateFormat: "yyyy/MM/dd HH:mm:ss.SSS z")
//                if timestamp.isNotEmpty {
//                    string = "\(string) [\(timestamp)]"
//                }

                // Thread
                string += " [\(getThreadName())]"
        }

        // ----------------------
        // Message

        var classInfoSepalator = ""

        if level != .trace {
            string = "\(string) \(message)"
            classInfoSepalator = " -- "
        }

        // ----------------------
        // Class Name /Function Name

        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let className = String(describing: instance)

        if className.isEmpty, let _fileName = fileName.components(separatedBy: ".").first {
            string = "\(string) \(classInfoSepalator) \(_fileName):\(function)"
        } else {
            string += "\(classInfoSepalator) \(String(describing: type(of: instance))):\(function)"
        }

        // ----------------------
        // Postfix

        if level == .trace {
            string += " -- " + " \(message)"
        }

        // ----------------------
        // File Name / Line Number

        string += " \(fileName):\(line)"

        return string
    }

    private func getThreadName() -> String {
        var threadName: String = "main"

        if !Thread.isMainThread {
            if let _threadName = Thread.current.name, !_threadName.isEmpty {
                threadName = _threadName
            } else if let _queueName = String(validatingUTF8: __dispatch_queue_get_label(nil)), !_queueName.isEmpty {
                threadName = _queueName
            } else {
                threadName = Thread.current.description
            }
        }

        return threadName
    }
}

extension LowLayerLogger {
    enum Level: String, Codable, CaseIterable {
        /// Appropriate for messages that contain information only when debugging a program.
        case trace

        /// Appropriate for messages that contain information normally of use only when
        /// debugging a program.
        case debug

        /// Appropriate for informational messages.
        case info

        /// Appropriate for conditions that are not error conditions, but that may require
        /// special handling.
        case notice

        /// Appropriate for messages that are not error conditions, but more severe than
        /// `.notice`.
        case warning

        /// Appropriate for error conditions.
        case error

        /// Appropriate for critical error conditions that usually require immediate
        /// attention.
        case fatal

        case `deinit`
    }

    func preFix(_ level: LowLayerLogger.Level) -> String {
        switch level {
            case .trace: return "➡️"
            case .debug: return "🕶"
            case .info: return "📗"
            case .notice: return "📙"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .fatal: return "🔥"
            case .deinit: return "❎"
        }
    }
}

extension LowLayerLogger {
    @inlinable
    func entered(_ instance: Any = "", message: Any = "", function: String = #function, file: String = #file, line: Int = #line) {
        self.log(level: .trace, message: message, instance: instance, file: file, function: function, line: line)
    }

    @inlinable
    func info(_ message: Any, instance: Any = "", function: String = #function, file: String = #file, line: Int = #line) {
        self.log(level: .info, message: message, instance: instance, file: file, function: function, line: line)
    }

    @inlinable
    func debug(_ message: Any, instance: Any = "", function: String = #function, file: String = #file, line: Int = #line) {
        self.log(level: .debug, message: message, instance: instance, file: file, function: function, line: line)
    }

    @inlinable
    func notice(_ message: Any, instance: Any = "", function: String = #function, file: String = #file, line: Int = #line) {
        self.log(level: .notice, message: message, instance: instance, file: file, function: function, line: line)
    }

    @inlinable
    func warning(_ message: Any, instance: Any = "", function: String = #function, file: String = #file, line: Int = #line) {
        self.log(level: .warning, message: message, instance: instance, file: file, function: function, line: line)
    }

    @inlinable
    func error(_ message: Any, instance: Any = "", function: String = #function, file: String = #file, line: Int = #line) {
        self.log(level: .error, message: message, instance: instance, file: file, function: function, line: line)
    }

    @inlinable
    func fatal(_ message: Any, instance: Any = "", function: String = #function, file: String = #file, line: Int = #line) {
        self.log(level: .fatal, message: message, instance: instance, file: file, function: function, line: line)
    }

    @inlinable
    func `deinit`(_ message: Any, instance: Any = "", function: String = #function, file: String = #file, line: Int = #line) {
        self.log(level: .deinit, message: message, instance: instance, file: file, function: function, line: line)
    }
}
