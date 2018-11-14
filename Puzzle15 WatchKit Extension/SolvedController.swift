//
//  SolvedController.swift
//  SlidingPuzzle
//
//  Created by Klemenz, Oliver on 18.02.15.
//  Copyright (c) 2015 Klemenz, Oliver. All rights reserved.
//

import WatchKit
import Foundation

class SolvedController: WKInterfaceController {

    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var detailLabel: WKInterfaceLabel!
    override func awake(withContext context: Any?) {
        
        titleLabel.setText(NSLocalizedString("Solved!", comment: ""))
        detailLabel.setText(NSLocalizedString("You successfully solved Puzzle of 15.", comment: ""))
        
        if let parameter = context as? Dictionary<String, String> {
            if let moves = Int(parameter["moves"]!) {
                let movesPlural = moves != 1 ? "s" : ""
                detailLabel.setText(NSLocalizedString("You successfully solved Puzzle of 15 in \(moves) move\(movesPlural).", comment: ""))
            }
        }
    }
    
    @IBAction func didTapPlayAgain() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "ActionNotification"), object: self, userInfo : [ "action" : "shuffleTiles" ])
        UserDefaults.standard.set("shuffleTiles", forKey: "action")
        UserDefaults.standard.synchronize()
        self.dismiss()
    }
}
