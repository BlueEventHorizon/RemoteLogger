//
//  RemoteLogger.swift
//  RemoteLogger
//
//  Created by k_terada on 2020/07/06.
//  Copyright © 2020 k2moons. All rights reserved.
//

import Foundation
import Logger

public extension Logger {
    static func remoteLogger() -> Logger {
        if #available(iOS 14.0, *) {
            return Logger(RemoteLogger())
        }
        else {
            return Logger()
        }
    }
}

@available(iOS 13.0, *)
class RemoteLogger: LoggerDependency {
    let manager = RemoteLoggerManager()
    var enabled: Bool = false

    init() {
        // coreLog.debug("(1) configuration", instance: self)

        manager.listener = self
        manager.browseAdvertiser()
    }

    func preFix(_ level: Logger.Level) -> String {
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

    func getTimeStampType(_ level: Logger.Level) -> Logger.TimeStampType {
        .full
    }

    func log(level: Logger.Level, message: String, formattedMessage: String) {
        print(formattedMessage)
        if enabled {
            manager.sendLog(formattedMessage)
        }
    }
}

@available(iOS 13.0, *)
extension RemoteLogger: RemoteLoggerBrowserDelegate {
    func changed(advertisers: [AdvertiserInfo]) {
        guard !manager.isNetworkConnected else { return }

        // coreLog.debug("(2) Found Advertiser and select it", instance: self)

        manager.selectedAdvertiser = advertisers.first

        // coreLog.debug("(3) Start to connect with passcode", instance: self)

        manager.connectToAdvertiser(passcode: "PASSCODE")
    }

    func ready() {
        // coreLog.debug("(4) Connection Ready", instance: self)

        _ = manager.setReceiverToAdvertiser(self)
        enabled = true
    }
}

@available(iOS 13.0, *)
extension RemoteLogger: RemoteLoggerReceiveDelegate {
    func ready(_ sender: RemoteLoggerManager) {}

    func failed(_ sender: RemoteLoggerManager) {
        //
    }

    func received(_ sender: RemoteLoggerManager, log: String?) {
        print("🍎 \(log ?? "")")
    }

    func received(_ sender: RemoteLoggerManager, control: String?) {
        print("🍏 \(control ?? "")")
    }
}
