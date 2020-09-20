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
    public func log(_ context: LogContext) {
        var preFix: String = ""

        switch context.level {
            case .trace: preFix = "➡️"
            case .debug: preFix = "[🛠 DEBG]"
            case .info: preFix = "[🔵 INFO]"
            case .notice: preFix = "[🟢 NOTE]"
            case .warning: preFix = "[⚠️ WARN]"
            case .error: preFix = "[🚫 ERRR]"
            case .fatal: preFix = "[🔥 FATAL]"
            case .deinit: preFix = "[❎ DEINIT]"
        }

        let formatted = preFix + context.buildMessage()
        manager.sendLog(formatted)
        print(formatted)
    }
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
