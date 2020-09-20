//
//  KeyboardManager.swift
//  BwTools
//
//  Created by k2moons on 2017/10/23.
//  Copyright (c) 2017 k2moons. All rights reserved.
//

import Logger
import UIKit

public final class KeyboardManager {
    public enum Action: String, CaseIterable {
        case willChange
        case willHide
    }

    // MARK: - Property

    private let log = Logger()

    // キーボードが表示された時の挙動を（子クラスで）記述する
    public private(set) var keyboardHandler: ((_ type: KeyboardManager.Action, _ height: CGFloat, _ duration: TimeInterval) -> Void)?

    private var isResistedKeyboardNotification = false

    private static var owners = [UIViewController]()
    public private(set) var baseView: UIView? // Constraintでキーボードを避ける場合の移動するUIViewの親UIView
    private var targetViewToScroll: UIView? // Constraintでキーボードを避ける場合の移動するUIView
    private var top: NSLayoutConstraint? // Constraintでキーボードを避ける場合の移動するUIViewの上側のConstraint
    private var bottom: NSLayoutConstraint? // Constraintでキーボードを避ける場合の移動するUIViewの下側のConstraint

    private var disableAutoHideByScrolling: Bool = false // 入力位置を移動するためにスクロールするので、この期間キーボードを閉じない

    public var heghitMargin: CGFloat = 18.0
    // public var showTouchViewAlways: Bool = false           // true: 常にタッチ用のViewを表示する

    private var textOfFirstResponder: String?
    private var firstResponderStoredText: UIView?
    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        UITapGestureRecognizer(target: self, action: #selector(hideKyeoboardTap))
    }()

    public static let shared = KeyboardManager()
    private init() {}

    deinit {
        log.deinit(self)
        removeAction()
    }

    // MARK: - API

    /// キーボードの制御を行う（SCrollViewが表示されている場合はownerのみ指定で可だが・・・）
    ///
    /// - Parameters:
    ///   - owner: 登録するUIViewController（必須）
    ///   - baseView: ownerの最上位のUIView
    ///   - targetViewToScroll: 移動するUIView
    ///   - moveTop: 移動するUIViewの上部Constraint
    ///   - moveBottom: 移動するUIViewの下部Constraint
    ///   - action: 移動時に呼び出されるクロージャ（Constraintを指定する場合は自動で移動後に呼び出される。その場合は必須ではない。）
    public func setAction(
        owner: UIViewController,
        baseView: UIView,
        targetViewToScroll: UIView,
        topConstraint: NSLayoutConstraint? = nil,
        bottomConstraint: NSLayoutConstraint? = nil,
        action: ((_ type: Action, _ height: CGFloat, _ duration: TimeInterval) -> Void)? = nil
    ) {
        self.baseView = baseView
        self.targetViewToScroll = targetViewToScroll
        self.top = topConstraint
        self.bottom = bottomConstraint
        self.keyboardHandler = action

        resistKeyboardNotification()
        configuretHideByTouch(on: true)

        if let scrollView = targetViewToScroll as? UIScrollView {
            hideKeyboardByScrolling(scrollView: scrollView)
        }
    }

    public func showKeyboard(responder: UIView) {
        if responder.canBecomeFirstResponder {
            responder.becomeFirstResponder()
            self.disableAutoHideByScrolling = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.99) {
                self.disableAutoHideByScrolling = false
            }
        }
    }

    public func hideKeyboardByScrolling(scrollView: UIScrollView) {
        addKVO(scrollView: scrollView) {
            // 入力位置を移動するためにスクロールするので、この期間キーボードを閉じない
            guard !self.disableAutoHideByScrolling else {
                // log.warning("自前でスクロール中")
                return
            }

            // log.info("スクロールしました")
            DispatchQueue.main.async {
                self.baseView?.findFirstResponder()?.resignFirstResponder()
            }
        }
    }

    /// 登録したクロージャを削除する
    /// クロージャのオーナーのみが削除できる
    /// - Parameter owner: クロージャのオーナー
    public func removeAction() {
        // keyboardUtil.removeAction()の前にキーボードを消すこと

        self.baseView?.findFirstResponder()?.resignFirstResponder()

        DispatchQueue.main.async {
            self.unresistKeyboardNotification()
            self.configuretHideByTouch(on: false)

            self.removeKVO()

            self.baseView = nil
            self.targetViewToScroll = nil
            self.top = nil
            self.bottom = nil
            self.keyboardHandler = nil
        }
    }

    /// キーボードの位置に従って指定されたUIViewの位置をずらす。topとbottomのConstraintが必要。
    /// - Parameters:
    ///   - shiftLength: 移動量
    ///   - duration: 移動アニメーション時間
    ///   - baseView: 移動しない親View
    ///   - targetViewToScroll: 移動させたいView
    ///   - moveCompletion: クロージャー
    private func changeConstraint(
        shift shiftLength: CGFloat,
        duration: TimeInterval,
        baseView: UIView,
        targetViewToScroll: UIView,
        completion moveCompletion: (() -> Void)? = nil
    ) {
        baseView.layoutIfNeeded()

        let shift = shiftLength

        // log.info("shift = \(shift)")

        var animate = false

        baseView.layoutIfNeeded()

        if shift > 0 {
            animate = self.top?.constant != -shift
            if animate {
                self.top?.constant = -shift // レイアウト変更
                self.bottom?.constant = shift // レイアウト変更
            }
        }
        else if shift < 0 {
            // log.warning("移動量がマイナス!?")
            animate = self.top?.constant != -shift
            if animate {
                self.top?.constant = -shift // レイアウト変更
                self.bottom?.constant = shift // レイアウト変更

                if self.top?.constant ?? 0 > 0 {
                    self.top?.constant = 0
                }
                if self.bottom?.constant ?? 0 < 0 {
                    self.bottom?.constant = 0
                }
            }
        }
        else {
            // log.info("元に戻る")

            animate = self.top?.constant != 0
            if animate {
                self.top?.constant = 0 // レイアウト変更
                self.bottom?.constant = 0 // レイアウト変更
            }
        }

        self.disableAutoHideByScrolling = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.99) {
            self.disableAutoHideByScrolling = false
        }

        if animate {
            UIView.animate(withDuration: duration, animations: {
                baseView.layoutIfNeeded()
            }, completion: { _ in
                moveCompletion?()
            })
        }
        else {
            baseView.layoutIfNeeded()
            moveCompletion?()
        }
    }

    // MARK: -

    /// キーボードの表示・非表示の処理を実行する
    ///
    /// - Parameters:
    ///   - action: 通知の種類
    ///   - height: キーボードの高さ
    ///   - notification: NSNotification
    private func action(action: KeyboardManager.Action, shiftLength: CGFloat, notification: NSNotification) {
        // キーボードのアニメーション時間を取得
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? Const.Duration.normal

        // 下記が設定されている場合はscrollViewの移動を【自動】で行う
        if let _baseView = self.baseView, let _targetViewToScroll = self.targetViewToScroll {
            var shift: CGFloat = 0.0
            let keyboardTop = _baseView.frame.size.height - shiftLength

            if let firstResponder = _targetViewToScroll.findFirstResponder() {
                let firstResponderTop = firstResponder.relativePosition(on: _baseView) // 画面内の位置
                let firstResponderBottom = firstResponderTop.y + firstResponder.frame.size.height
                // log.info("firstResponderBottom: \(firstResponderBottom)")

                // scrollViewがUIScrollViewの場合、UIScrollViewをスクロールして位置を調整する。それでも移動が足らない場合は、残り移動量を返す。
                if let scrollView = self.targetViewToScroll as? UIScrollView {
                    let _contentView = scrollView.subviews.first!

                    let maxScroll: CGFloat = _contentView.frame.size.height - scrollView.frame.size.height
                    let scrolled: CGFloat = scrollView.contentOffset.y
                    let restScroll: CGFloat = maxScroll - scrolled
                    var toScroll: CGFloat = 0

                    shift = (firstResponderBottom - scrolled) - keyboardTop
                    if let bottomConstarint = self.bottom?.constant {
                        shift += bottomConstarint
                    }
                    else if let topConstraint = self.top?.constant {
                        shift -= topConstraint // topConstraintはマイナスなので減算
                    }

                    // log.info("shift: \(shift)")
                    if maxScroll > 0, restScroll > 0, shift > 0 {
                        toScroll = shift

                        if toScroll > restScroll {
                            toScroll = restScroll
                        }
                        shift -= toScroll
                    }

                    // log.info("スクロールで移動: \(toScroll)")
                    if toScroll != 0 {
                        self.disableAutoHideByScrolling = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.99) {
                            self.disableAutoHideByScrolling = false
                        }
                    }
                    scrollView.scrollRectToVisible(CGRect(origin: CGPoint(x: 0, y: scrolled + toScroll), size: scrollView.frame.size), animated: true)
                }
                else {
                    // log.info("*** UIScrollViewがありません ***")
                    // log.info("入力底部 = \(firstResponderBottom) キーボード上部 = \(keyboardTop)")

                    shift = firstResponderBottom - keyboardTop
                    if let bottomConstarint = self.bottom?.constant {
                        shift += bottomConstarint
                    }
                    else if let topConstraint = self.top?.constant {
                        shift -= topConstraint // topConstraintはマイナスなので減算
                    }
                }
            }
            else {
                // log.info("*** firstResponderが見つかりません ***")
            }

            // log.info("コンストレインで移動: \(shift)")
            // Constraintが設定されている場合は、Constraintを操作して画面入力部をキーボードに隠れないように移動する。
            self.changeConstraint(shift: shift, duration: duration, baseView: _baseView, targetViewToScroll: _targetViewToScroll) {
                if let _keyboardHandler = self.keyboardHandler {
                    // ハンドラーがある場合は呼び出す
                    _keyboardHandler(action, shift, duration)
                }
            }
        }
    }

    // MARK: - KVO for UIScrollView

    // https://developer.apple.com/videos/play/wwdc2017/201/
    // https://qiita.com/BlueEventHorizon/items/bf37428b54b937728dc7

    private var keyValueObservations = [NSKeyValueObservation]()

    private func addKVO(scrollView: UIScrollView, _ closure: @escaping () -> Void) {
        let keyValueObservation = scrollView.observe(\.contentOffset, options: [.new]) { _, change in
            if change.newValue == nil {
                return
            }
            // log.info("スクロールしました")
            closure()
        }
        keyValueObservations.append(keyValueObservation)
    }

    private func removeKVO() {
        for keyValueObservation in keyValueObservations {
            keyValueObservation.invalidate()
        }
        keyValueObservations.removeAll()
    }

    // MARK: - Touchでキーボードを閉じる

    private func configuretHideByTouch(on: Bool) {
        // tapされた時の動作を宣言する
        if on {
            tapGestureRecognizer.numberOfTapsRequired = 1
            baseView?.isUserInteractionEnabled = true
            baseView?.addGestureRecognizer(tapGestureRecognizer)
        }
        else {
            baseView?.removeGestureRecognizer(tapGestureRecognizer)
        }
    }

    // キーボード以外をタップするとキーボードが下がるメソッド
    @objc func hideKyeoboardTap(recognizer: UITapGestureRecognizer) {
        baseView?.endEditing(true)
    }

    // MARK: - NotificationCenter for Keyboard

    /// キーボードの表示・非表示時の処理ををNotificationCenterに登録する
    public func resistKeyboardNotification() {
        log.entered(self)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
    }

    /// キーボードの表示・非表示時の処理ををNotificationCenterから削除する
    public func unresistKeyboardNotification() {
        log.entered(self)

        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)

        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
    }

    // キーボードの高さが変わることを通知
    // キーボードの高さは同じでもFirstResponderが変わり、位置が変わるので【毎回】通知する必要がある。
    @objc func keyboardWillChange(notification: NSNotification) {
        log.entered(self)
        let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        if let height = keyboardSize?.size.height {
            // log.info("キーボード高さ: \(height)")
            DispatchQueue.main.async {
                self.action(action: .willChange, shiftLength: (height > 0) ? (height + self.heghitMargin) : 0, notification: notification)
            }
        }
    }

    // キーボードが現れる
    @objc func keyboardWillShow(notification: NSNotification) {
        //  log.entered(self)
        //  showHeight(notification: notification)
    }

    // キーボードが現れた
    @objc func keyboardDidShow(notification: NSNotification) {
        //  log.entered(self)
        //  showHeight(notification: notification)

        storeFirstResponderText()
    }

    // キーボードが消える
    @objc func keyboardWillHide(notification: NSNotification) {
        //  log.entered(self)
        //  showHeight(notification: notification)

        DispatchQueue.main.async {
            self.action(action: .willHide, shiftLength: 0.0, notification: notification)
        }
    }

    // キーボードが消えた
    @objc func keyboardDidHide(notification: NSNotification) {
        //  log.entered(self)
        //  showHeight(notification: notification)

        clearFirstResponderText()
    }

    public func showHeight(notification: NSNotification) {
        let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        if let height = keyboardSize?.size.height {
            log.info("キーボード高さ: \(height)")
        }
    }
}

extension KeyboardManager {
    // MARK: - FirstResponderがテキストを扱うUIViewであった場合、キーボード、ピッカーの入力前のテキストを保存、復帰する

    public func restoreFirstResponderText() {
        if let _firstResponder = firstResponderStoredText {
            if let _textField = _firstResponder as? UITextField {
                _textField.text = textOfFirstResponder
            }
            else if let _textView = _firstResponder as? UITextView {
                _textView.text = textOfFirstResponder
            }
            else if let _searchBar = _firstResponder as? UISearchBar {
                _searchBar.text = textOfFirstResponder
            }
        }
    }

    private func storeFirstResponderText() {
        if let _firstResponder = self.targetViewToScroll?.findFirstResponder() {
            firstResponderStoredText = _firstResponder

            if let _textField = _firstResponder as? UITextField {
                textOfFirstResponder = _textField.text
            }
            else if let _textView = _firstResponder as? UITextView {
                textOfFirstResponder = _textView.text
            }
            else if let _searchBar = _firstResponder as? UISearchBar {
                textOfFirstResponder = _searchBar.text
            }
        }
    }

    private func clearFirstResponderText() {
        firstResponderStoredText = nil
        textOfFirstResponder = nil
    }
}
