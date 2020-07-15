/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 Network Browser
 */

// https://developer.apple.com/documentation/network/building_a_custom_peer-to-peer_protocol

import Foundation
import Network

// let coreLog = ToolLogger(prefix: "☀️", enable: false)

@available(iOS 13.0, *)
public protocol NetworkBrowserDelegate: AnyObject {
    func changed(browser: NetworkBrowser, results: Set<NWBrowser.Result>)
}

@available(iOS 13.0, *)
public class NetworkBrowser {
    private weak var delegate: NetworkBrowserDelegate?
    private var browser: NWBrowser!
    public private(set) var type: String!
    private var timestamp: Date?

    public init() {}

    @discardableResult
    public func start(type: String, delegate: NetworkBrowserDelegate?) -> Self {
        // coreLog.entered(self)

        self.type = type
        self.delegate = delegate

        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        browser = NWBrowser(for: .bonjour(type: type, domain: nil), using: parameters)
        browser.stateUpdateHandler = { newState in
            switch newState {
                case .setup:
                    // coreLog.info("The browser has been initialized but not started.")
                    break

                case .ready:
                    // coreLog.info("The browser is registered for discovering services.")
                    break

                case .cancelled:
                    // coreLog.info("The browser has been canceled.")
                    break

                case let .failed(error):
                    // Restart the browser if it fails.
                    // coreLog.error("The browser has encountered a fatal error \(error), restarting")
                    self.browser.cancel()
                    self.start(type: self.type, delegate: self.delegate)

                default:
                    break
            }
        }

        browser.browseResultsChangedHandler = { [weak self] results, _ in

            guard let self = self else { return }

            // 【⚠️⚠️⚠️】Workaround for browseResultsChangedHandler is invoked again in short time without advertiser
            if let timestamp = self.timestamp, timestamp.timeIntervalSince1970 + 0.5 > Date().timeIntervalSince1970 {
                // coreLog.error("browseResultsChangedHandler is invoked again within 0.5 second, count = \(results.count)")
                return
            }

            // coreLog.info("🍎 browser changed count = \(results.count)", instance: self)

            self.timestamp = Date()

            self.delegate?.changed(browser: self, results: results)
        }

        browser.start(queue: .main)

        return self
    }
}
