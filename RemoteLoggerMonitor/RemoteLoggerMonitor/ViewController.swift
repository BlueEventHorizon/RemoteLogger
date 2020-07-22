//
//  ViewController.swift
//  RemoteLoggerMonitor
//
//  Created by k2moons on 2020/07/15.
//  Copyright © 2020 k2terada. All rights reserved.
//

import Logger
import PPublisher
// import RemoteLogger
import UIKit

class ViewController: UIViewController {
    private let monitor = RemoteLoggerMonitor()
    private var appName: String?
    private var logall: String = ""

    @IBOutlet weak var loggerName: UILabel!
    @IBOutlet weak var collectionParentView: UIView!
    @IBOutlet weak var textView: UITextView!
    @IBAction func pushedClear(_ sender: Any) {
        logall = ""
        textView.text = logall
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        title = appName

        collectionParentView.layer.borderWidth = 1.0
        collectionParentView.layer.borderColor = UIColor.lightGray.cgColor
        collectionParentView.layer.cornerRadius = 4.0
        textView.isEditable = false

        monitor.receivedLog.subscribe(self) { log in
            self.logall = self.logall + log + "\n"
            self.textView.text = self.logall
        }

        monitor.receivedControl.subscribe(self) { control in
            self.loggerName.text = control
        }

        monitor.strat()
    }
}
