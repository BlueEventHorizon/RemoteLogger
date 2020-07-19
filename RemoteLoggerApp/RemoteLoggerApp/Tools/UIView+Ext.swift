//
//  UIView+Ext.swift
//  BwTools
//
//  Created by k2moons on 2017/10/23.
//  Copyright (c) 2017 k2moons. All rights reserved.
//

import UIKit

extension UIView {
    private func setAlpha(_ alpha: CGFloat) {
        // 0, 1.0 以外は復元できないかも
        if (self.alpha != Const.Opacity.none) || (self.alpha != Const.Opacity.full) {
            self.alpha = alpha
        }

        for view in self.subviews {
            view.setAlpha(alpha)
        }
    }

    public var subviewsAlpha: CGFloat {
        set {
            self.setAlpha(newValue)
        }
        get {
            self.alpha
        }
    }

    // MARK: - UIViewの外景

    // UIViewの外景をレクトアングルにするための半径を指定する
    @IBInspectable
    public var cornerRadius: CGFloat {
        set {
            self.layer.cornerRadius = newValue
            if self is UILabel {
                let label = self as! UILabel
                label.clipsToBounds = true
            }
            self.setNeedsLayout()
        }
        get {
            self.layer.cornerRadius
        }
    }

    // UIViewの外枠の線を描画する（幅）
    @IBInspectable
    public var borderWidth: CGFloat {
        set {
            self.layer.borderWidth = newValue
            self.setNeedsLayout()
        }
        get {
            self.layer.borderWidth
        }
    }

    // UIViewの外枠の線を描画する（色）
    @IBInspectable
    public var borderColor: UIColor {
        set {
            self.layer.borderColor = newValue.cgColor
            self.setNeedsLayout()
        }
        get {
            if let _borderColor = self.layer.borderColor {
                return UIColor(cgColor: _borderColor)
            }
            return UIColor.clear
        }
    }

    // MARK: - 相対座標

    // 指定されたViewに対する相対座標を返す
    public func relativePosition(on baseView: UIView? = nil, point: CGPoint = CGPoint.zero) -> CGPoint {
        let _baseView = baseView ?? self.superview

        if let _view = self.superview {
            // 親Viewあり

            let newPoint = CGPoint(x: point.x + self.frame.origin.x,
                                   y: point.y + self.frame.origin.y)
            if _view == _baseView {
                return newPoint // 終了
            }
            else {
                return _view.relativePosition(on: _baseView, point: newPoint)
            }
        }

        log.fatal("見つかりませんでした")

        return point
    }

    public func relativeInsets(to baseView: UIView? = nil, insets: UIEdgeInsets = UIEdgeInsets.zero) -> UIEdgeInsets {
        let _baseView = baseView ?? self.superview

        if let _view = self.superview {
            // 親Viewあり
            let newInsets: UIEdgeInsets = UIEdgeInsets(top: insets.top + self.frame.origin.y,
                                                       left: insets.left + self.frame.origin.x,
                                                       bottom: insets.bottom + (_view.frame.size.height - self.frame.size.height - self.frame.origin.y),
                                                       right: insets.bottom + (_view.frame.size.width - self.frame.size.width - self.frame.origin.x))
            if _view == _baseView {
                return newInsets // 終了
            }
            else {
                return _view.relativeInsets(to: _baseView, insets: newInsets)
            }
        }

        log.fatal("見つかりませんでした")

        return insets
    }

    // MARK: - autoresizingMask

    // Constraintが設定されていないViewに対してautoresizingMaskを有効に働かせる
    public func autoFit() {
        // autoresizingMaskを有効にする
        self.translatesAutoresizingMaskIntoConstraints = true

        // 親ビューの bounds が変更された時に 幅・高さ を自動調整する。
        // これが無いとlayoutSubviewsが呼ばれない？
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        /*
         public struct UIViewAutoresizing: OptionSet {

         public init(rawValue: UInt)

         public static var flexibleLeftMargin: UIViewAutoresizing { get }

         public static var flexibleWidth: UIViewAutoresizing { get }

         public static var flexibleRightMargin: UIViewAutoresizing { get }

         public static var flexibleTopMargin: UIViewAutoresizing { get }

         public static var flexibleHeight: UIViewAutoresizing { get }

         public static var flexibleBottomMargin: UIViewAutoresizing { get }
         }
         */
    }

    // MARK: - Keyborad

    public func add(barButtonItems: [UIBarButtonItem], height: Float) {}

    // MARK: - UIImage

    public func capture() -> UIImage? {
        var capturedImage: UIImage?

        // キャプチャする範囲を取得.
        let rect = self.bounds

        // ビットマップ画像のcontextを作成.
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        if let _context = UIGraphicsGetCurrentContext() {
            // 対象のview内の描画をcontextに複写する.
            self.layer.render(in: _context)

            // 現在のcontextのビットマップをUIImageとして取得.
            capturedImage = UIGraphicsGetImageFromCurrentImageContext()
        }
        // contextを閉じる.
        UIGraphicsEndImageContext()

        return capturedImage
    }
}
