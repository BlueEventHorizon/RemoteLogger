//
//  RemoteLogger.swift
//  RemoteLogger
//
//  Created by k_terada on 2020/07/06.
//  Copyright © 2020 k2moons. All rights reserved.
//

import Foundation

#if canImport(Logger)
    import Logger
#endif

#if canImport(PPublisher)
    import PPublisher
#endif

#if canImport(RemoteLogger)
    import RemoteLogger
#endif

extension Logger {
    public static func remoteLogger() -> Logger {
        if #available(iOS 13.0, *) {
            return Logger(RemoteLogger.shared)
        }
        else {
            return Logger()
        }
    }

    @available(iOS 13.0, *)
    public var monitorNamePublisher: Publisher<String> {
        RemoteLogger.shared.monitorNamePublisher
    }

    @available(iOS 13.0, *)
    public var myname: String {
        set {
            RemoteLogger.shared.myname = newValue
        }
        get {
            ""
        }
    }
}

@available(iOS 13.0, *)
public class RemoteLogger {
    static let shared = RemoteLogger()

    var monitorNamePublisher = Publisher<String>()

    private let manager = RemoteLoggerManager.shared

    private init() {
        // netlog.debug("(1) configuration", instance: self)

        manager.browseAdvertiser(delegate: self, autoConnect: true, passcode: "PASSCODE", receiveDelegate: nil)
    }

    public var myname: String {
        set {
            manager.sendControl(newValue)
        }
        get {
            ""
        }
    }
}

extension RemoteLogger: LoggerDependency {
    // if return false, Logger does not execute log(_ message: String)
    public func log(_ context: LogContext) -> Bool {
        let level: String = preFix(context.level)

        var formattedMessage: String = ""

        switch context.level {
            case .trace:
                formattedMessage = "\(level) \(context.methodName())\(context.addSpacer(" -- ", to: context.message))"
            case .debug:
                formattedMessage = "\(level) [\(context.timestamp())] [\(context.threadName())]\(context.addSpacer(" ", to: context.message)) -- \(context.methodName()) \(context.lineInfo())"
            case .info:
                formattedMessage = "\(level) [\(context.timestamp())]\(context.addSpacer(" ", to: context.message)) -- \(context.lineInfo())"
            case .notice:
                formattedMessage = "\(level) [\(context.timestamp())]\(context.addSpacer(" ", to: context.message)) -- \(context.methodName()) \(context.lineInfo())"
            case .warning:
                formattedMessage = "\(level) [\(context.timestamp())] [\(context.threadName())]\(context.addSpacer(" ", to: context.message)) -- \(context.methodName()) \(context.lineInfo())"
            case .error:
                formattedMessage = "\(level) [\(context.timestamp())] [\(context.threadName())]\(context.addSpacer(" ", to: context.message)) -- \(context.methodName()) \(context.lineInfo())"
            case .fatal:
                formattedMessage = "\(level) [\(context.timestamp())] [\(context.threadName())]\(context.addSpacer(" ", to: context.message)) -- \(context.methodName()) \(context.lineInfo())"
            case .deinit:
                formattedMessage = "\(level) [\(context.timestamp())]\(context.addSpacer(" -- ", to: context.message)) -- \(context.lineInfo())"
        }
        manager.sendLog(formattedMessage)
        return true
    }

//    public func log(_ message: String) {
//
//    }
}

@available(iOS 13.0, *)
extension RemoteLogger: RemoteLoggerBrowserDelegate {
    public func changed(advertisers: [AdvertiserInfo]) {
        guard !manager.isNetworkConnected else {
            monitorNamePublisher.publish("Not Connected")
            return
        }
    }

    public func connected(advertiser: AdvertiserInfo) {
        monitorNamePublisher.publish(advertiser.name)
    }

    public func ready() {}
}
