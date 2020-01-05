//
//  GameViewController.swift
//  Puzzle15
//
//  Created by Klemenz, Oliver on 25.02.15.
//  Copyright (c) 2015 Klemenz, Oliver. All rights reserved.
//

import UIKit

enum GameStatus : NSInteger {
    case new      = 1
    case running  = 2
    case solved   = 3
    case canceled = 4
}

class GameViewController: UITableViewController {
    
    let dateFormatter = DateFormatter()
    let dateTimeFormatter = DateFormatter()
    let timeFormatter = DateFormatter()
    let diffFormatter = DateFormatter()
    
    var games = [NSMutableDictionary]()
    var gamesLoaded = false
    
    var _gameDays = [Date]()
    var _gamesByDay = Dictionary<Date, [NSMutableDictionary]>()

    var clearButton : UIBarButtonItem?
    var infoButton : UIBarButtonItem?
    var testButton : UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        self.clearButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(GameViewController.didTapClear))

        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(GameViewController.didTapInfo), for: .touchUpInside)
        self.infoButton = UIBarButtonItem(customView: infoButton)
        //self.testButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "test")
        self.navigationItem.rightBarButtonItems = [self.infoButton!] // , self.testButton!
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(GameViewController.refresh), for: UIControl.Event.valueChanged)
        self.refreshControl = refreshControl
        self.refreshControl?.tintColor = UIColor.white
        
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.doesRelativeDateFormatting = true
        
        dateTimeFormatter.dateStyle = .medium
        dateTimeFormatter.timeStyle = .medium
        
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .medium
        
        diffFormatter.dateFormat = "HH:mm:ss"
        
        refresh()
    }
    
    func test() {
        updateGame(0, newStatus: GameStatus.running)
    }
    
    func alert(_ data : AnyObject) {
        let alertController = UIAlertController(title: NSLocalizedString("Puzzle of 15", comment: ""), message: "\(data)", preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil)
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if editing {
            self.navigationItem.rightBarButtonItems = [self.clearButton!]
        } else {
            self.navigationItem.rightBarButtonItems = [self.infoButton!]  // , self.testButton!
        }
    }

    func store() {
        UserDefaults.standard.set(games, forKey:"games")
        UserDefaults.standard.synchronize()
    }
    
    @objc func refresh() {
        games = []
        _gameDays = []
        _gamesByDay = [:]

        if let data = UserDefaults.standard.object(forKey: "games") as? [NSDictionary] {
            for entry in data {
                games.append(entry.mutableCopy() as! NSMutableDictionary)
            }
            games.sort(by: { (game1, game2) -> Bool in
                if let startDate1 = game1["start"] as? Date {
                    if let startDate2 = game2["start"] as? Date {
                        return startDate1.compare(startDate2) == ComparisonResult.orderedDescending
                    }
                }
                return false
            })

            for game in games {
                if let dayDate = dayDate(game) {
                    var gamesByDay = _gamesByDay[dayDate]
                    if gamesByDay == nil {
                        gamesByDay = [game]
                        _gameDays.append(dayDate)
                    } else {
                        gamesByDay?.append(game)
                    }
                    _gamesByDay[dayDate] = gamesByDay
                }
            }
            
            _gameDays.sort(by: { $0.compare($1) == ComparisonResult.orderedDescending })
        }
        
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
        gamesLoaded = true
    }
    
    func dayDate(_ game : NSDictionary) -> Date? {
        if let date = game["start"] as? Date {
            let calender = Calendar(identifier: Calendar.Identifier.gregorian)
            let units = Set<Calendar.Component>([.year, .month, .day])
            let components = calender.dateComponents(units, from: date)
            return calender.date(from: components)
        }
        return nil
    }
    
    @objc func didTapClear() {
        let alertController = UIAlertController(title: NSLocalizedString("Puzzle of 15", comment:""), message: NSLocalizedString("Which records?", comment:""), preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment:""), style: .cancel) { (action) in
        }
        alertController.addAction(cancelAction)
        let clearAllAction = UIAlertAction(title: NSLocalizedString("Clear all game records", comment:""), style: .destructive) { (action) in
            self.games.removeAll(keepingCapacity: false)
            self.store()
            self.refresh()
            self.setEditing(false, animated: true)
        }
        alertController.addAction(clearAllAction)

        let clearCanceledAction = UIAlertAction(title: NSLocalizedString("Clear canceled game records", comment:""), style: .default) { (action) in
            for index in stride(from: self.games.count - 1, through: 0, by: -1) {
                let game = self.games[index]
                if let statusCode = game["status"] as? Int {
                    if let status = GameStatus(rawValue: statusCode) {
                        if status == GameStatus.canceled {
                            self.games.remove(at: index)
                        }
                    }
                }
            }
            self.store()
            self.refresh()
            self.setEditing(false, animated: true)
        }
        alertController.addAction(clearCanceledAction)

        self.present(alertController, animated: true) {
        }
    }
    
    @objc func didTapInfo() {
        var message = NSLocalizedString("Your highscores: \n", comment: "")
        
        var bestMovesGame : NSDictionary?
        var bestMoves : Int = -1
        var bestTimeGame : NSDictionary?
        var bestSeconds : Int = -1

        for game in self.games {
            let (_, moves, seconds, status) = gameData(game)
            if status != nil && status! == GameStatus.solved {
                if bestMoves == -1 || moves < bestMoves {
                    bestMovesGame = game
                    bestMoves = moves
                }
                if bestSeconds == -1 || seconds < bestSeconds {
                    bestTimeGame = game
                    bestSeconds = seconds
                }
            }
        }
        let calendar = Calendar.current

        if bestMovesGame != nil {
            let (formattedDate, moves, seconds, _) = gameData(bestMovesGame!)

            var components = DateComponents()
            components.setValue(seconds, for: Calendar.Component.second)
            let diffTime = diffFormatter.string(from: calendar.date(from: components)!)
            message += NSLocalizedString("\nGame solved with fewest moves:", comment: "")
            message += NSLocalizedString("\n\(formattedDate)\nMoves: \(moves)\nTime: \(diffTime)", comment: "")
        }
        if bestTimeGame != nil {
            if bestMovesGame != nil {
                message += "\n---"
            }
            let (formattedDate, moves, seconds, _) = gameData(bestMovesGame!)
            var components = DateComponents()
            components.setValue(seconds, for: Calendar.Component.second)
            let diffTime = diffFormatter.string(from: calendar.date(from: components)!)
            message += NSLocalizedString("\nGame solved in shortest time:", comment: "")
            message += NSLocalizedString("\n\(formattedDate)\nMoves: \(moves)\nTime: \(diffTime)", comment: "")
        }
        if  bestMovesGame == nil && bestTimeGame == nil {
            message = NSLocalizedString("\nPuzzle was not solved yet!\n\nConnect an Apple Watch to play.", comment: "")
        }
        
        let alertController = UIAlertController(title: NSLocalizedString("Puzzle of 15", comment:""), message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: NSLocalizedString("OK", comment:""), style: .cancel) { (action) in
        }
        alertController.addAction(action)
        
        self.present(alertController, animated: true) {
        }
    }
    
    func gameData(_ game : NSDictionary) -> (String, Int, Int, GameStatus?) {
        if let startDate = game["start"] as? Date {
            if let endDate = game["end"] as? Date {
                if let statusCode = game["status"] as? Int {
                    if let status = GameStatus(rawValue: statusCode) {
                        let calendar = Calendar.current
                        let units = Set<Calendar.Component>([.second])
                        let components = calendar.dateComponents(units, from: startDate, to: endDate)
                        let seconds = components.second
                        return (dateTimeFormatter.string(from: startDate), game["moves"] as! Int, seconds!, status)
                    }
                }
            }
        }
        return ("", 0, 0, nil)
    }
    
    func hasActiveGame() -> Bool {
        for dayDate in _gameDays {
            if let gamesByDay = _gamesByDay[dayDate] {
                for game in gamesByDay {
                    if let statusCode = game["status"] as? Int {
                        if let status = GameStatus(rawValue: statusCode) {
                            if status == GameStatus.new || status == GameStatus.running {
                                return true
                            }
                        }
                    }
                }
            }
        }
        return false
    }
    
    func updateGame(_ moves: Int, newStatus : GameStatus) {
        if !gamesLoaded {
            refresh()
        }
        if (newStatus != .canceled && !hasActiveGame()) {
            newGame()
        }
        var section = 0
        for dayDate in _gameDays {
            var row = 0
            if let gamesByDay = _gamesByDay[dayDate] {
                for game in gamesByDay {
                    if let statusCode = game["status"] as? Int {
                        if let status = GameStatus(rawValue: statusCode) {
                            if status == GameStatus.new || status == GameStatus.running {
                                if status == GameStatus.new {
                                    game.setValue(Date(), forKey:"start")
                                    game.setValue(GameStatus.running.rawValue, forKey:"status")
                                }
                                if newStatus == GameStatus.solved {
                                    game.setValue(GameStatus.solved.rawValue, forKey:"status")
                                }
                                if newStatus == GameStatus.canceled {
                                    game.setValue(GameStatus.canceled.rawValue, forKey:"status")
                                }
                                if newStatus != GameStatus.canceled {
                                    game.setValue(moves, forKey:"moves")
                                }
                                game.setValue(Date(), forKey:"end")
                                if readSettingsMoveMultiple() {
                                    game.setValue(true, forKey:"moveMulti")
                                }
                                self.store()
                                self.tableView.reloadRows(at: [IndexPath(row: row, section: section)], with: .automatic)
                                return
                            }
                        }
                    }
                    row += 1
                }
            }
            section += 1
        }
    }
    
    func newGame() {
        if !gamesLoaded {
            refresh()
        }

        var section = 0
        for dayDate in _gameDays {
            var row = 0
            for game in _gamesByDay[dayDate]! {
                if let statusCode = game["status"] as? Int {
                    if let status = GameStatus(rawValue: statusCode) {
                        if status == GameStatus.new {
                            return
                        } else if status != GameStatus.solved {
                            game.setValue(GameStatus.canceled.rawValue, forKey:"status")
                            self.tableView.reloadRows(at: [IndexPath(row: row, section: section)], with: .automatic)
                        }
                    }
                }
                row += 1
            }
            section += 1
        }
        
        let game = NSMutableDictionary()
        game["start"] = Date()
        game["moves"] = 0
        game["status"] = GameStatus.new.rawValue
        game["moveMulti"] = readSettingsMoveMultiple()
        self.games.insert(game, at: 0)
        
        self.store()
        
        tableView.beginUpdates()
        
        if let dayDate = self.dayDate(game) {
            var gamesByDay = _gamesByDay[dayDate]
            if gamesByDay == nil {
                gamesByDay = [game]
                _gameDays.insert(dayDate, at: 0)
                tableView.insertSections(IndexSet(integer: 0), with: .fade)
            } else {
                gamesByDay?.insert(game, at: 0)
            }
            _gamesByDay[dayDate] = gamesByDay
        }
        
        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
        
        tableView.endUpdates()
    }
    
    func readSettingsMoveMultiple() -> Bool {
        if let defaults = UserDefaults(suiteName: "group.de.oklemenz.Puzzle15") {
            if (defaults.value(forKey: "allow_move_multiple_tiles") != nil) {
                return defaults.value(forKey: "allow_move_multiple_tiles") as! Bool
            }
        }
        return false
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return _gamesByDay.keys.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < _gameDays.count {
            return _gamesByDay[_gameDays[section]]!.count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < _gameDays.count {
            let dayDate = _gameDays[section]
            return dateFormatter.string(from: dayDate)
        }
        return ""
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) 

        let bgColorView = UIView()
        bgColorView.backgroundColor = UIApplication.shared.delegate?.window??.tintColor
        cell.selectedBackgroundView = bgColorView

        let accessoryLabel = UILabel()
        accessoryLabel.textColor = UIColor.white
        cell.accessoryView = accessoryLabel
        
        let dayDate = _gameDays[(indexPath as NSIndexPath).section]
        let game = _gamesByDay[dayDate]![(indexPath as NSIndexPath).row]
        
        let moves = game["moves"] as! Int
        let sPlural = moves != 1 ? "s" : ""
        cell.textLabel!.text = NSLocalizedString("\(moves) move\(sPlural)", comment: "")
        if game["moveMulti"] as! Bool {
            cell.textLabel!.text = cell.textLabel!.text! + " (multiple moved)"
        }

        var statusText = ""
        if let statusCode = game["status"] as? Int {
            let status = GameStatus(rawValue: statusCode)!
            switch (status) {
                case .new:
                    statusText = NSLocalizedString("New", comment:"")
                case .running:
                    statusText = NSLocalizedString("Running", comment:"")
                case .solved:
                    statusText = NSLocalizedString("Solved", comment:"")
                case .canceled:
                    statusText = NSLocalizedString("Canceled", comment:"")
            }
        
            if let startDate = game["start"] as? Date {
                if let endDate = game["end"] as? Date {
                    let calendar = Calendar.current
                    let units = Set<Calendar.Component>([.second])
                    let components = calendar.dateComponents(units, from: startDate, to: endDate)
                    
                    let startTime = timeFormatter.string(from: startDate)
                    let endTime = timeFormatter.string(from: endDate)
                    
                    if status == GameStatus.solved || status == GameStatus.canceled {
                        cell.detailTextLabel?.text = "\(statusText) : \(startTime) - \(endTime)"
                    } else {
                        cell.detailTextLabel?.text = "\(statusText) : \(startTime)"
                    }

                    let diffTime = diffFormatter.string(from: calendar.date(from: components)!)
                    accessoryLabel.text = diffTime
                } else {
                    let startTime = timeFormatter.string(from: startDate)
                    cell.detailTextLabel?.text = "\(statusText) : \(startTime)"
                    accessoryLabel.text = "--:--:--"
                }
            }
        }
        
        if let statusCode = game["status"] as? Int {
            let status = GameStatus(rawValue: statusCode)!
            switch (status) {
                case .new:
                    cell.imageView?.image = UIImage(named: "dot")
                case .running:
                    cell.imageView?.image = UIImage(named: "dot")
                case .solved:
                    cell.imageView?.image = UIImage(named: "check")
                case .canceled:
                    cell.imageView?.image = UIImage(named: "cross")
            }
        }
    
        accessoryLabel.sizeToFit()
        
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()

            let dayDate = _gameDays[(indexPath as NSIndexPath).section]
            var gamesByDay = _gamesByDay[dayDate]!
            let game = gamesByDay[(indexPath as NSIndexPath).row]
            
            let index = games.firstIndex(of: game)!
            games.remove(at: index)
            
            tableView.deleteRows(at: [indexPath], with: .fade)
            gamesByDay.remove(at: (indexPath as NSIndexPath).row)
            
            if gamesByDay.count == 0 {
                _gamesByDay.removeValue(forKey: dayDate)
                _gameDays.remove(at: (indexPath as NSIndexPath).section)
                tableView.deleteSections(IndexSet(integer: (indexPath as NSIndexPath).section), with: .fade)
            } else {
                _gamesByDay[dayDate] = gamesByDay
            }
            
            tableView.endUpdates()
            
            self.store()
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.contentView.backgroundColor = UIColor.darkGray
        header.textLabel!.textColor = UIColor.white
        header.alpha = 0.8
    }
}
