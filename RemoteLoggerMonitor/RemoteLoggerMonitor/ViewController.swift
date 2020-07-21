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
import PPublisher

class ViewController: UIViewController {

    let monitor = RemoteLoggerMonitor()
//    var flowLayout: UICollectionViewFlowLayout!
//    var collectionView: UICollectionView!

    @IBOutlet weak var collectionParentView: UIView!
    @IBOutlet weak var textView: UITextView!
    @IBAction func pushedClear(_ sender: Any) {
        logall = ""
        textView.text = logall
    }

    var logall: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.isEditable = false

        monitor.receivedLog.subscribe(self, latest: false, main: true) { (log) in
            self.logall = self.logall + log + "\n"
            self.textView.text = self.logall
        }
        
        monitor.strat()
    }
}

//extension ViewController {

    //func configure() {
        //        flowLayout = ColumnFlowLayout()
        //        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        //        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        //        collectionView.backgroundColor = UIColor.systemBackground
        //        collectionView.alwaysBounceVertical = true
        //        view.addSubview(collectionView)
        //
        //        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "UICollectionViewCell")
        //
        //        collectionView.dataSource = self
        //        collectionView.delegate = self
    //}
//}

//extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    //    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    //        <#code#>
    //    }
    //
    //    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    //        <#code#>
    //    }
//}

//
//class ColumnFlowLayout: UICollectionViewFlowLayout {
//
//}
