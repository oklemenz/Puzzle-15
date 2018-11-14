//
//  GlanceController.swift
//  Puzzle15 WatchKit Extension
//
//  Created by Klemenz, Oliver on 17.02.15.
//  Copyright (c) 2015 Klemenz, Oliver. All rights reserved.
//

import WatchKit
import Foundation

class GlanceController: WKInterfaceController {

    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var detailLabel: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }

    override func willActivate() {
        super.willActivate()

        var correct = 0
        var incorrect = 15
        if let data = UserDefaults.standard.object(forKey: "context") as? Data {
            if let context = NSKeyedUnarchiver.unarchiveObject(with: data) as? InterfaceController.Context {
                correct = context.correct.intValue
                incorrect = context.incorrect.intValue
            }
        }
        if correct == 15 {
            titleLabel.setText(NSLocalizedString("Puzzle of 15 is solved!", comment:""))
            detailLabel.setText(NSLocalizedString("Select Shuffle from Menu to start new Game.", comment:""))
        } else {
            let correctPlural = correct != 1 ? "s" : ""
            let incorrectPlural = incorrect != 1 ? "s" : ""
            titleLabel.setText(NSLocalizedString("\(correct) tile\(correctPlural) correct", comment: ""))
            detailLabel.setText(NSLocalizedString("Solve the missing \(incorrect) tile\(incorrectPlural) to complete Puzzle of 15!", comment: ""))
        }
    }

    override func didDeactivate() {
        super.didDeactivate()
    }
}
