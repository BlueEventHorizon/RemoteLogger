//
//  RemoteLoggerMonitor.swift
//  RemoteLoggerMonitor
//
//  Created by k_terada on 2020/07/07.
//  Copyright © 2020 k2terada. All rights reserved.
//

import Foundation

#if canImport(PPublisher)
    import PPublisher
#endif

#if canImport(RemoteLogger)
    import RemoteLogger
#endif

@available(iOS 13.0, *)
public class RemoteLoggerMonitor {
    private var monitor: RemoteLoggerManager?

    var receivedLog = Publisher<String>()
    var receivedControl = Publisher<String>()

    public init() {
        configure()
    }

    private func configure() {
        monitor = RemoteLoggerManager.shared
    }

    public func strat() {
        monitor?.startAdvertiser(advertisingName: "RemoteLoggerMonitor", passcode: "PASSCODE", receiver: self)
    }
}

@available(iOS 13.0, *)
extension RemoteLoggerMonitor: RemoteLoggerReceiveDelegate {
    public func ready(_ sender: RemoteLoggerManager) {}

    public func failed(_ sender: RemoteLoggerManager) {
        //
    }

    public func received(_ sender: RemoteLoggerManager, log: String?) {
        guard let log = log else { return }
        receivedLog.publish(log)
        print("🍎 \(log)")
    }

    public func received(_ sender: RemoteLoggerManager, control: String?) {
        guard let control = control else { return }
        receivedControl.publish(control)
        print("🍏 \(control)")
    }
}
