//
//  AppDelegate.swift
//  Puzzle15
//
//  Created by Klemenz, Oliver on 25.02.15.
//  Copyright (c) 2015 Klemenz, Oliver. All rights reserved.
//

import UIKit
import Foundation
import WatchConnectivity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate, WCSessionDelegate {

    var window: UIWindow?
    var rootViewController : UINavigationController?
    var gameViewController : GameViewController?

    var session = WCSession.default
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.rootViewController = self.window?.rootViewController as? UINavigationController
        self.gameViewController = self.rootViewController!.topViewController as? GameViewController
        
        self.window?.tintColor = UIColor(red: 61.0/255.0, green: 169.0/255.0, blue: 237.0/255.0, alpha: 1.0)
        UINavigationBar.appearance().barTintColor = UIColor.black
        self.rootViewController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        self.rootViewController?.navigationBar.setBackgroundImage(imageWithColor(UIColor.black, size: CGSize(width: 1, height: 1)), for: .default)
        self.rootViewController?.navigationBar.shadowImage = imageWithColor(UIColor.white, size: CGSize(width: 1, height: 1))
                
        session.delegate = self
        session.activate()
        
        return true
    }
    
    func imageWithColor(_ color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func alert(_ data : AnyObject) {
        let alertController = UIAlertController(title: NSLocalizedString("Puzzle of 15", comment: ""), message: "\(data)", preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil)
        alertController.addAction(defaultAction)
        self.rootViewController!.present(alertController, animated: true, completion: nil)
    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
    }

    public func sessionDidDeactivate(_ session: WCSession) {
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Swift.Void) {
        DispatchQueue.main.async {
            if self.gameViewController != nil {
                if let data = message["request"]  as? Dictionary<String, String> {
                    let movesNumber = data["moves"]
                    let moves = Int(movesNumber!)
                    let statusNumber = data["status"]
                    let statusInt = Int(statusNumber!)
                    let newStatus = GameStatus(rawValue: statusInt!)!
                    if newStatus == GameStatus.new {
                        self.gameViewController!.newGame()
                    } else {
                        self.gameViewController!.updateGame(moves!, newStatus: newStatus)
                    }
                    replyHandler([:])
                }
            }
        }
    }
}
