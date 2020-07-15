//
//  ViewController.swift
//  RemoteLoggerMonitor
//
//  Created by k2moons on 2020/07/15.
//  Copyright © 2020 k2terada. All rights reserved.
//

import UIKit
import Logger
import RemoteLogger

class ViewController: UIViewController {

    let monitor = RemoteLoggerMonitor()

    override func viewDidLoad() {
        super.viewDidLoad()

        monitor.strat()
    }
}

