//
//  UIView+Find.swift
//  BwTools
//
//  Created by k2moons on 2017/12/15.
//  Copyright (c) 2017 k2moons. All rights reserved.
//

import UIKit

// MARK: - FirstResponder

extension UIView {
    // 自Viewの上のFirstResponderを【再帰的に】探す。
    // 通常はbaseViewなどを渡す。
    public func findFirstResponder() -> UIView? {
        if self.isFirstResponder {
            return self
        }

        for view in self.subviews {
            let result = view.findFirstResponder()
            if result != nil {
                return result
            }
        }

        return nil
    }

    // 次のFirstResponderを【再帰的に】探す
    public func findNextFirstResponder(from responders: [UIView]) -> UIView? {
        if responders.isEmpty { return nil }
        let firstResponder = self.findFirstResponder()
        var found = false
        for view in responders {
            if found {
                return view
            }
            found = (view == firstResponder)
        }
        return responders[0] // 見つからなかったので先頭へ
    }

    /// 配列で与えられたViewの中から現在のFirstResponderを見つけて、次のFirstResponderを設定する
    /// **** RxSwiftを使っている場合はうまく動作しません ****
    ///
    /// - Parameter responders: FirstResponderになりうるViewの配列
    public func nextFirstResponder(with responders: [UIView]) {
        if responders.isEmpty { return }
        let firstResponder = self.findFirstResponder()
        if let _firstResponder = firstResponder {
            var found = false
            for view in responders {
                if found {
                    DispatchQueue.main.async {
                        _firstResponder.resignFirstResponder()
                        view.becomeFirstResponder()
                    }
                    return
                }
                found = (view == _firstResponder)
            }

            DispatchQueue.main.async {
                _firstResponder.resignFirstResponder()
                responders[0].becomeFirstResponder()
            }
        }
    }

    // 前のFirstResponderを探す
    public func findPreviousFirstResponder(from responders: [UIView]) -> UIView? {
        if responders.isEmpty { return nil }
        let firstResponder = self.findFirstResponder()
        var found: UIView? = responders[responders.count - 1] // 最後尾
        for view in responders {
            if view == firstResponder {
                return found // 最初のFirstResponderが指定されたら最後尾を返す
            }
            found = view
        }
        log.fatal("見つからなかった")
        return found // 見つからなかった
    }
}
