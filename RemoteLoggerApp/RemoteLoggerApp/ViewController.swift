//
//  ViewController.swift
//  RemoteLoggerApp
//
//  Created by k2moons on 2020/07/15.
//  Copyright © 2020 k2terada. All rights reserved.
//

import Logger
import PPublisher
import RemoteLogger
import UIKit

let log = Logger.remoteLogger()

class ViewController: UIViewController {
    private var checkButtonType: CheckButtonType?
    private var bag = SubscriptionBag()
    private var keyboardManager = KeyboardManager.shared
    @IBOutlet weak var top: NSLayoutConstraint!
    @IBOutlet weak var bottom: NSLayoutConstraint!
    @IBOutlet weak var targetViewToScroll: UIView!

    @IBOutlet weak var monitorNameLabel: UILabel!
    @IBOutlet weak var logMessageTextField: UITextField!

    @IBOutlet weak var logLebelSelectorStack: UIStackView!

    @IBAction func sendLog(_ sender: Any) {
        sendLog()
    }

    @IBOutlet var checkButton: [UIButton]!

    @IBAction func checked(_ sender: UIButton) {
        var tag = -1
        var index = -1
        for button in checkButton.enumerated() {
            if button.element == sender {
                index = button.offset
                tag = button.element.tag
                break
            }
        }

        if tag >= 0 {
            updateCheckBox(index: index)
            checkButtonType = CheckButtonType(rawValue: tag)
        }
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

        for button in checkButton.enumerated() {
            if button.element.tag == 0 {
                updateCheckBox(index: button.offset)
                checkButtonType = CheckButtonType(rawValue: 0)
                break
            }
        }

        log.monitorNamePublisher.subscribe(self) { [weak self] name in
            self?.monitorNameLabel.text = name
        }
        .unsubscribed(by: bag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        keyboardManager.setAction(owner: self, baseView: self.view, targetViewToScroll: self.targetViewToScroll, topConstraint: top, bottomConstraint: bottom)
        logMessageTextField.returnKeyType = .done
        logMessageTextField.delegate = self
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        keyboardManager.removeAction()
    }

    private func sendLog() {
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

extension ViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        textField.resignFirstResponder()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
