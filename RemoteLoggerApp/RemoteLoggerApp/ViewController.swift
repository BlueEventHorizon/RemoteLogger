//
//  ViewController.swift
//  RemoteLoggerApp
//
//  Created by k2moons on 2020/07/15.
//  Copyright © 2020 k2terada. All rights reserved.
//

import UIKit
import Logger
import RemoteLogger

let log = Logger.remoteLogger()

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        testLogOut()
    }

    private func testLogOut() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            log.debug("Hellow World", instance: self)
            self.testLogOut()
        }
    }
}

