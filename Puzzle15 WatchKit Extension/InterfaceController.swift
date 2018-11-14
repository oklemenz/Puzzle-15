//
//  InterfaceController.swift
//  Puzzle15 WatchKit Extension
//
//  Created by Klemenz, Oliver on 17.02.15.
//  Copyright (c) 2015 Klemenz, Oliver. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class InterfaceController: WKInterfaceController, WCSessionDelegate {
    
    var session : WCSession?
    
    let STORE_CONTEXT : String = "context"
    
    let PUZZLE_SIZE : Int = 4
    let PUZZLE_EMPTY_TILE : Int = 16
    var PUZZLE_MOVE_MULTI : Bool = true

    @objc(_TtCC27Puzzle15_WatchKit_Extension19InterfaceController7Context) final class Context : NSObject, NSCoding {
        var moves : NSNumber = 0
        var status : NSNumber = 0
        var correct : NSNumber = 0
        var incorrect : NSNumber = 0
        var tileValues : [NSNumber] = []
        
        override init() {
        }
        
        init(moves : NSNumber, status : NSNumber, correct : NSNumber, incorrect : NSNumber, tileValues : [NSNumber]) {
            self.moves = moves
            self.status = status
            self.correct = correct
            self.incorrect = incorrect
            self.tileValues = tileValues
        }

        required convenience init(coder decoder: NSCoder) {
            self.init()
            self.moves = decoder.decodeObject(forKey: "moves") as! NSNumber
            self.status = decoder.decodeObject(forKey: "status") as! NSNumber
            self.correct = decoder.decodeObject(forKey: "correct") as! NSNumber
            self.incorrect = decoder.decodeObject(forKey: "incorrect") as! NSNumber
            self.tileValues = decoder.decodeObject(forKey: "tileValues") as! [NSNumber]
        }
        
        func encode(with coder: NSCoder) {
            coder.encode(self.moves, forKey : "moves")
            coder.encode(self.status, forKey : "status")
            coder.encode(self.correct, forKey : "correct")
            coder.encode(self.incorrect, forKey : "incorrect")
            coder.encode(self.tileValues, forKey : "tileValues")
        }
    }
    
    struct Position {
        var row : Int = 0
        var column : Int = 0
        
        init (row: Int, column: Int) {
            self.row = row
            self.column = column
        }
    }
    
    enum TileMove {
        case up
        case down
        case left
        case right
        case none
    }
    
    enum GameStatus : NSInteger {
        case new      = 1
        case running  = 2
        case solved   = 3
        case canceled = 4
    }
    
    var status : GameStatus = GameStatus.new
    var moves : Int = 0
    var tiles : [WKInterfaceButton] = []
    var tileValues : [Int] = []
    
    @IBOutlet weak var tile01: WKInterfaceButton!
    @IBOutlet weak var tile02: WKInterfaceButton!
    @IBOutlet weak var tile03: WKInterfaceButton!
    @IBOutlet weak var tile04: WKInterfaceButton!
    @IBOutlet weak var tile05: WKInterfaceButton!
    @IBOutlet weak var tile06: WKInterfaceButton!
    @IBOutlet weak var tile07: WKInterfaceButton!
    @IBOutlet weak var tile08: WKInterfaceButton!
    @IBOutlet weak var tile09: WKInterfaceButton!
    @IBOutlet weak var tile10: WKInterfaceButton!
    @IBOutlet weak var tile11: WKInterfaceButton!
    @IBOutlet weak var tile12: WKInterfaceButton!
    @IBOutlet weak var tile13: WKInterfaceButton!
    @IBOutlet weak var tile14: WKInterfaceButton!
    @IBOutlet weak var tile15: WKInterfaceButton!
    @IBOutlet weak var tile16: WKInterfaceButton!

    @IBAction func tile01Tap() {
        tileTap(0)
    }

    @IBAction func tile02Tap() {
        tileTap(1)
    }

    @IBAction func tile03Tap() {
        tileTap(2)
    }

    @IBAction func tile04Tap() {
        tileTap(3)
    }

    @IBAction func tile05Tap() {
        tileTap(4)
    }

    @IBAction func tile06Tap() {
        tileTap(5)
    }

    @IBAction func tile07Tap() {
        tileTap(6)
    }

    @IBAction func tile08Tap() {
        tileTap(7)
    }

    @IBAction func tile09Tap() {
        tileTap(8)
    }

    @IBAction func tile10Tap() {
        tileTap(9)
    }
    
    @IBAction func tile11Tap() {
        tileTap(10)
    }

    @IBAction func tile12Tap() {
        tileTap(11)
    }
    
    @IBAction func tile13Tap() {
        tileTap(12)
    }
    
    @IBAction func tile14Tap() {
        tileTap(13)
    }
    
    @IBAction func tile15Tap() {
        tileTap(14)
    }
    
    @IBAction func tile16Tap() {
        tileTap(15)
    }
    
    func setTitle() {
        let movePlural = moves != 1 ? "s" : ""
        self.setTitle(NSLocalizedString("\(moves) move\(movePlural)", comment : ""))
    }
    
    @objc func showSolvedDialog() {
        self.presentController(withName: "solvedController", context: [ "moves" : "\(moves)"])
    }
    
    func initTiles() {
        tiles = [tile01, tile02, tile03, tile04, tile05, tile06, tile07, tile08, tile09, tile10, tile11, tile12, tile13, tile14, tile15, tile16]
    }
    
    func setTileForIndex(_ index : Int) {
        if let tile = tileForIndex(index) {
            if let value = tileValueForIndex(index) {
                if value != PUZZLE_EMPTY_TILE {
                    tile.setBackgroundImageNamed(String(format: "t%02d", value))
                } else {
                    tile.setBackgroundImage(nil)
                }
            }
        }
    }

    func setTileForPosition(_ position : Position) {
        if let index = indexForPosition(position) {
            setTileForIndex(index)
        }
    }
    
    func isSolvable() -> Bool {
        var inversions = 0
        for i in 0..<PUZZLE_EMPTY_TILE {
            let tileValue = tileValueForIndex(i)
            if tileValue != PUZZLE_EMPTY_TILE {
                for j in i+1..<PUZZLE_EMPTY_TILE {
                    let compareTileValue = tileValueForIndex(j)
                    if tileValue > compareTileValue && compareTileValue != PUZZLE_EMPTY_TILE {
                        inversions += 1
                    }
                }
            }
        }
        if PUZZLE_SIZE % 2 == 1 { // Puzzle odd
            return inversions % 2 == 0 // Inversion even
        } else { // Puzzle event
            return (inversions % 2 == 0) == (emptyTile()!.row % 2 == 1) // Inversion even iff empty odd row
        }
    }
    
    func shuffleTiles(_ level : Int) {
        tileValues = []
        for (index, _) in tiles.enumerated() {
            tileValues.append(index + 1)
        }
        tileValues.shuffle()
        for (index, _) in tileValues.enumerated() {
            setTileForIndex(index)
        }
        if !isSolvable() {
            if self[0, 0] != PUZZLE_EMPTY_TILE && self[0, 1] != PUZZLE_EMPTY_TILE {
                swapTile(Position(row: 0, column: 0), to: Position(row: 0, column: 1))
            } else {
                swapTile(Position(row: PUZZLE_SIZE - 1, column: PUZZLE_SIZE - 1), to: Position(row: PUZZLE_SIZE - 1, column: PUZZLE_SIZE - 2))
            }
        }
        if !isSolvable() {
            shuffleTiles(level + 1)
        }
        if level == 0 {
            moves = 0
            checkTiles()
        }
    }

    func solveTiles() {
        tileValues = []
        for (index, _) in tiles.enumerated() {
            tileValues.append(index + 1)
        }
        for (index, _) in tileValues.enumerated() {
            setTileForIndex(index)
        }
        moves = 0
        status = GameStatus.canceled
        checkTiles()
    }
    
    func emptyTile() -> Position? {
        for (index, tileValue) in tileValues.enumerated() {
            if tileValue == PUZZLE_EMPTY_TILE {
                return positionForIndex(index)
            }
        }
        return nil
    }
    
    func tileTap(_ index : Int) {
        let tileValue = tileValues[index]
        if (tileValue == PUZZLE_EMPTY_TILE) {
            return
        }
        if let position = positionForIndex(index) {
            if var movePosition = emptyTile() {
                if PUZZLE_MOVE_MULTI {
                    var delta = 0
                    var direction = 0
                    if position.row == movePosition.row {
                        if position.column < movePosition.column {
                            delta = movePosition.column - position.column
                            direction = -1
                        } else {
                            delta = position.column - movePosition.column
                            direction = 1
                        }
                        for _ in 0..<delta {
                            let newPosition = Position(row: movePosition.row, column: movePosition.column + direction)
                            swapTile(newPosition, to: movePosition)
                            movePosition = newPosition
                        }
                    } else if position.column == movePosition.column {
                        if position.row < movePosition.row {
                            delta = movePosition.row - position.row
                            direction = -1
                        } else {
                            delta = position.row - movePosition.row
                            direction = 1
                        }
                        for _ in 0..<delta {
                            let newPosition = Position(row: movePosition.row + direction, column: movePosition.column)
                            swapTile(newPosition, to: movePosition)
                            movePosition = newPosition
                        }
                    }
                } else {
                    swapTile(position, to: movePosition)
                }
            }
        }
        moves += 1
        checkTiles()
    }
    
    func swapTile(_ from : Position, to : Position) {
        if let fromValue = tileValueForPosition(from) {
            if let toValue = tileValueForPosition(to) {
                setTileValueForPosition(from, value: toValue)
                setTileValueForPosition(to, value: fromValue)
                setTileForPosition(from)
                setTileForPosition(to)
            }
        }
    }
    
    func checkTiles() {
        setTitle()
        
        if PUZZLE_MOVE_MULTI {
            if let emptyTilePos = emptyTile() {
                for (index, tile) in tiles.enumerated() {
                    if let position = positionForIndex(index) {
                        tile.setEnabled(position.row == emptyTilePos.row ||
                                        position.column == emptyTilePos.column)
                    }
                }
            }
        } else {
            for (index, tile) in tiles.enumerated() {
                if let position = positionForIndex(index) {
                    tile.setEnabled(tileMoveDirection(position) != TileMove.none)
                }
            }
        }
        
        if status == GameStatus.new || status == GameStatus.running {
            if checkTilesSolved() {
                status = GameStatus.solved
                Timer.scheduledTimer(timeInterval: 0.25, target: self, selector:  #selector(InterfaceController.showSolvedDialog), userInfo: nil, repeats: false)
            } else if moves > 0 {
                status = GameStatus.running
            }
        }

        store()

        callParentApp([ "moves" : "\(moves)", "status" : "\(status.rawValue)"])
    }
    
    func tileMoveDirection(_ position : Position) -> TileMove {
        if tileValueForPosition(Position(row: position.row - 1, column: position.column)) == PUZZLE_EMPTY_TILE {
            return TileMove.up
        }
        if tileValueForPosition(Position(row: position.row + 1, column: position.column)) == PUZZLE_EMPTY_TILE {
            return TileMove.down
        }
        if tileValueForPosition(Position(row: position.row, column: position.column - 1)) == PUZZLE_EMPTY_TILE {
            return TileMove.left
        }
        if tileValueForPosition(Position(row: position.row, column: position.column + 1)) == PUZZLE_EMPTY_TILE {
            return TileMove.right
        }
        return TileMove.none
    }
    
    func tileContext() -> Context {
        var correct = 0
        var incorrect = 0
        for (index, tileValue) in tileValues.enumerated() {
            if tileValue != PUZZLE_EMPTY_TILE {
                if tileValue == index + 1 {
                    correct += 1
                } else {
                    incorrect += 1
                }
            }
        }
        var contextTileValues : [NSNumber] = [];
        for (_, tileValue) in tileValues.enumerated() {
            contextTileValues.append(NSNumber(value: tileValue))
        }
        return Context(moves : NSNumber(value: moves),
                       status : NSNumber(value: status.rawValue),
                       correct : NSNumber(value: correct),
                       incorrect : NSNumber(value: incorrect),
                       tileValues : contextTileValues)
    }

    func checkTilesSolved() -> Bool {
        for (index, tileValue) in tileValues.enumerated() {
            if tileValue != index + 1 {
                return false
            }
        }
        return true
    }
    
    func tileValueForIndex(_ index : Int) -> Int? {
        if index >= 0 && index < tileValues.count {
            return tileValues[index]
        }
        return nil
    }

    func setTileValueForIndex(_ index : Int, value : Int) {
        if index >= 0 && index < tileValues.count {
            tileValues[index] = value
            
        }
    }
    
    func tileValueForPosition(_ position : Position) -> Int? {
        if let index = indexForPosition(position) {
            return tileValueForIndex(index)
        }
        return nil
    }

    func setTileValueForPosition(_ position : Position, value : Int) {
        if let index = indexForPosition(position) {
            setTileValueForIndex(index, value: value)
        }
    }
    
    func tileForIndex(_ index : Int) -> WKInterfaceButton? {
        if index >= 0 && index < tiles.count {
            return tiles[index]
        }
        return nil
    }
    
    func tileForPosition(_ position : Position) -> WKInterfaceButton? {
        if let index = indexForPosition(position) {
            if index >= 0 && index < tiles.count {
                return tiles[index]
            }
        }
        return nil
    }
    
    func indexForPosition(_ position : Position) -> Int? {
        if position.row >= 0 && position.row < PUZZLE_SIZE &&
           position.column >= 0 && position.column < PUZZLE_SIZE {
            return position.row * PUZZLE_SIZE + position.column
        }
        return nil
    }
    
    func positionForIndex(_ index : Int) -> Position? {
        if index >= 0 && index < tiles.count {
            return Position(row: index / PUZZLE_SIZE, column: index % PUZZLE_SIZE)
        }
        return nil
    }
    
    subscript(row: Int, column: Int) -> Int {
        get {
            return tileValueForPosition(Position(row: row, column: column))!
        }
        set {
            setTileValueForPosition(Position(row: row, column: column), value: newValue)
        }
    }
    
    func load() -> Bool {
        if let data = UserDefaults.standard.object(forKey: STORE_CONTEXT) as? Data {
            do {
                let context = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? InterfaceController.Context
                if let context = context {
                    moves = context.moves.intValue
                    status = GameStatus(rawValue: context.status.intValue)!
                    tileValues = []
                    for (_, tileValue) in context.tileValues.enumerated() {
                        tileValues.append(tileValue.intValue)
                    }
                    for (index, _) in tileValues.enumerated() {
                        setTileForIndex(index)
                    }
                    return true
                }
            } catch _ {
            }
        }
        return false
    }
    
    func store() {
        let data = NSKeyedArchiver.archivedData(withRootObject: tileContext())
        UserDefaults.standard.set(data, forKey: STORE_CONTEXT)
        UserDefaults.standard.synchronize()
    }
    
    @IBAction func didTapMenuContinue() {
    }
    
    @IBAction func didTapMenuSolve() {
        solveTiles()
    }
    
    @IBAction func didTapMenuShuffle() {
        newGame()
    }
    
    func newGame() {
        status = GameStatus.new
        shuffleTiles(0)
    }

    func handleAction() {
        if let action = UserDefaults.standard.object(forKey: "action") as? String {
            if action == "shuffleTiles" {
                newGame()
            }
        }
        UserDefaults.standard.removeObject(forKey: "action")
        UserDefaults.standard.synchronize()
    }
    
    @objc func readSettings() {
        var newMoveMulti = true
        if let defaults = UserDefaults(suiteName: "group.de.oklemenz.Puzzle15") {
            if (defaults.value(forKey: "allow_move_multiple_tiles") != nil) {
                newMoveMulti = defaults.value(forKey: "allow_move_multiple_tiles") as! Bool
            } else {
                newMoveMulti = true
                defaults.set(newMoveMulti, forKey: "allow_move_multiple_tiles")
            }
        }
        if PUZZLE_MOVE_MULTI != newMoveMulti {
            PUZZLE_MOVE_MULTI = newMoveMulti
            checkTiles()
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        readSettings()
        initTiles()
        if load() {
            checkTiles()
        } else {
            newGame()
        }
    }

    override func willActivate() {
        super.willActivate()
        handleAction()
        NotificationCenter.default.addObserver(self, selector: #selector(InterfaceController.readSettings), name: UserDefaults.didChangeNotification, object: nil)
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    override func didDeactivate() {
        super.didDeactivate()
        NotificationCenter.default.removeObserver(self)
    }
    
    override func handleUserActivity(_ userInfo: [AnyHashable: Any]!) {
        super.handleUserActivity(userInfo)
        // Handle Handoff actvity
    }

    func updateUserActivity() {
        // self.updateUserActivity("de.oklemenz.SlidingPuzzle", userInfo:[ "data": "", "detailInfo": "" ], webpageURL:nil)
    }
    
    func callParentApp(_ userInfo : Dictionary<String, String>) {
        session?.sendMessage(["request" : userInfo], replyHandler: { (response) in
            }, errorHandler: { (error) in
            }
        )
    }
    
    @available(watchOS 2.2, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
     
    }
}
