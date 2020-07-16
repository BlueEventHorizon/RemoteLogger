//
//  RemoteLoggerMonitor.swift
//  RemoteLoggerMonitor
//
//  Created by k_terada on 2020/07/07.
//  Copyright © 2020 k2terada. All rights reserved.
//

import Foundation
import RemoteLogger

@available(iOS 13.0, *)
public class RemoteLoggerMonitor {
    private var monitor: RemoteLoggerManager?

    public init() {
        configure()
    }

    private func configure() {
        monitor = RemoteLoggerManager.shared
    }

    public func strat() {
        monitor?.startAdvertiser(advertisingName: UUID().uuidString, passcode: "PASSCODE", receiver: self)
    }
}

@available(iOS 13.0, *)
extension RemoteLoggerMonitor: RemoteLoggerReceiveDelegate {
    public func ready(_ sender: RemoteLoggerManager) {}

    public func failed(_ sender: RemoteLoggerManager) {
        //
    }

    public func received(_ sender: RemoteLoggerManager, log: String?) {
        print("🍎 \(log ?? "")")
    }

    public func received(_ sender: RemoteLoggerManager, control: String?) {
        print("🍏 \(control ?? "")")
    }
}
