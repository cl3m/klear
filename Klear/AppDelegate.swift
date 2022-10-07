//
//  AppDelegate.swift
//  Klear
//
//  Created by Yorwos Pallikaropoulos on 6/25/20.
//  Copyright © 2020 Yorwos Pallikaropoulos. All rights reserved.
//

import UIKit

import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
//        let cdStack = CoreDataStack.regularStore()
//        ItemRepo.makeIn(moc: cdStack.moc!)?.title = "blah"
//        try! cdStack.moc!.save()

        let dummyView = UIView()
        self.window?.addSubview(dummyView)
        dummyView.becomeFirstResponder()
        dummyView.resignFirstResponder()
        dummyView.removeFromSuperview()
        return true
    }

}


