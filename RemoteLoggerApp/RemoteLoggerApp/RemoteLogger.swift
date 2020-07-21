//
//  RemoteLogger.swift
//  RemoteLogger
//
//  Created by k_terada on 2020/07/06.
//  Copyright © 2020 k2moons. All rights reserved.
//

import Foundation
import Logger
import PPublisher
import RemoteLogger

extension Logger {
    public static func remoteLogger() -> Logger {
        return Logger(RemoteLogger.shared)
    }

    public var monitorNamePublisher: Publisher<String> {
        RemoteLogger.shared.monitorNamePublisher
    }
}

public class RemoteLogger: LoggerDependency {
    static let shared = RemoteLogger()

    var monitorNamePublisher = Publisher<String>()

    private let manager = RemoteLoggerManager.shared

    private init() {
        // netlog.debug("(1) configuration", instance: self)

        manager.browseAdvertiser(listener: self)
    }

    public func preFix(_ level: Logger.Level) -> String {
        switch level {
            case .trace: return "===>"
            case .debug: return "[🟡 DEBG]"
            case .info: return "[🔵 INFO]"
            case .notice: return "[🟢 NOTE]"
            case .warning: return "⚠️⚠️⚠️"
            case .error: return "❌❌❌"
            case .fatal: return "🔥🔥🔥"
        }
    }

    public func getTimeStampType(_ level: Logger.Level) -> Logger.TimeStampType {
        .full
    }

    public func log(level: Logger.Level, message: String, formattedMessage: String) {
        print(formattedMessage)
        manager.sendLog(formattedMessage)
    }
}

@available(iOS 13.0, *)
extension RemoteLogger: RemoteLoggerBrowserDelegate {
    public func changed(advertisers: [AdvertiserInfo]) {
        guard !manager.isNetworkConnected else {
            monitorNamePublisher.publish("Not Connected")
            return
        }

        // netlog.debug("(2) Found Advertiser and select it", instance: self)

        if let advertiser = advertisers.first {
            manager.selectedAdvertiser = advertiser
            monitorNamePublisher.publish(advertiser.name)

            // netlog.debug("(3) Start to connect with passcode", instance: self)

            manager.connectToAdvertiser(passcode: "PASSCODE")
        }
        else {
            monitorNamePublisher.publish("Not Connected")
        }
    }

    public func ready() {
        // netlog.debug("(4) Connection Ready", instance: self)

        _ = manager.setReceiverToAdvertiser(self)
    }
}

@available(iOS 13.0, *)
extension RemoteLogger: RemoteLoggerReceiveDelegate {
    public func ready(_ sender: RemoteLoggerManager) {}

    public func failed(_ sender: RemoteLoggerManager) {}

    public func received(_ sender: RemoteLoggerManager, log: String?) {
        //
    }

    public func received(_ sender: RemoteLoggerManager, control: String?) {
        //
    }
}
