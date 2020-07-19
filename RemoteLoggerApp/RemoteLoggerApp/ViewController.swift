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
import PPublisher

let log = Logger.remoteLogger()

class ViewController: UIViewController {

    var checkButtonType: CheckButtonType?
    var bag = SubscriptionBag()

    @IBOutlet weak var monitorNameLabel: UILabel!
    @IBOutlet weak var logMessageTextField: UITextField!
    @IBAction func senfLog(_ sender: Any) {
        guard let message = logMessageTextField.text else { return }

        switch checkButtonType {
            case .debug:
                log.debug(message)
            case .info:
                log.info(message)
            case .notice:
                log.notice(message)
            case .warning:
                log.warning(message)
            case .error:
                log.error(message)
            case .none:
                break
        }
    }

    @IBOutlet var checkButton: [UIButton]!

    @IBAction func checked(_ sender: UIButton) {
        var index = -1
        for button in checkButton.enumerated() {
            if button.element == sender {
                index = button.offset
                break
            }
        }

        updateCheckBox(index: index)

        checkButtonType = CheckButtonType(rawValue: index)
    }

    enum CheckButtonType: Int, CaseIterable {
        case debug
        case info
        case notice
        case warning
        case error
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        updateCheckBox(index: 0)

        log.monitorNamePublisher.subscribe(self) { [weak self] (name) in
            self?.monitorNameLabel.text = name
        }
        .unsubscribed(by: bag)
    }

    private func updateCheckBox(index: Int) {
        for button in checkButton.enumerated() {
            let on = (index == button.offset)
            button.element.tintColor = on ? UIColor.blue : UIColor.lightGray
            let textColor = on ? UIColor.blue : UIColor.lightGray
            let name = on ? "checkmark.square.fill" : "checkmark.square"
            let image = UIImage(systemName: name)
            button.element.setTitleColor(textColor, for: .normal)
            button.element.setImage(image, for: .normal)
        }
    }
}

