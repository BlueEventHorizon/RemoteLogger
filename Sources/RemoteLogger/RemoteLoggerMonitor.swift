//
//  RemoteLoggerMonitor.swift
//  RemoteLoggerMonitor
//
//  Created by k_terada on 2020/07/07.
//  Copyright © 2020 k2terada. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
class RemoteLoggerMonitor {
    var monitor: RemoteLoggerManager?

    init() {
        configure()
    }

    func configure() {
        monitor = RemoteLoggerManager()
    }

    func strat() {
        monitor?.startAdvertiser(advertisingName: "RemoteLoggerMonitor", passcode: "PASSCODE", receiver: self)
    }
}

@available(iOS 13.0, *)
extension RemoteLoggerMonitor: RemoteLoggerReceiveDelegate {
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
