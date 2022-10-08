//
//  CoreDataStack.swift
//  Klear
//
//  Created by Spencer Ward on 06/10/2022.
//  Copyright © 2022 Yorwos Pallikaropoulos. All rights reserved.
//

import CoreData

class CoreDataStack {
    
    var moc: NSManagedObjectContext?
    
    
    // in memory store
    convenience init() {
        self.init(storeUrl: nil)
    }
    
    init(storeUrl:NSURL?) {
        print("!!!!!!!! NEW MOC")

        let modelUrl = Bundle.main.url(forResource: "Model", withExtension: "momd")
        let model = NSManagedObjectModel(contentsOf: modelUrl!)
        let psc = NSPersistentStoreCoordinator(managedObjectModel: model!)
        let storeType = (storeUrl != nil) ? NSSQLiteStoreType : NSInMemoryStoreType
        
        do {
            try psc.addPersistentStore(
                ofType: storeType,
                configurationName: nil,
                at: storeUrl as URL?,
                options: nil
            )
        }
        catch {}

        moc = NSManagedObjectContext(concurrencyType:NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        moc!.persistentStoreCoordinator = psc
    }
    
    class func regularStore() -> CoreDataStack {
        return CoreDataStack(storeUrl: CoreDataStack.storeUrl())
    }

    class func storeUrl() -> NSURL {
        

        let fm = FileManager.default
        let documentDirUrl = fm.containerURL(
              forSecurityApplicationGroupIdentifier: "group.com.skw.klear")!

        //        let urls = fm.urls(for: .documentDirectory, in:.userDomainMask) as [NSURL]
//        let documentDirUrl = urls[0]
        let dataDir = documentDirUrl.appendingPathComponent("NoteNote/Data")
        let sqliteUrl = dataDir.appendingPathComponent("notenote.sqlite")
        
        do {
            try fm.createDirectory(at: dataDir, withIntermediateDirectories: true)
        } catch {}
//
//        if fm.createDirectory(at: dataDir!, withIntermediateDirectories: true, attributes: nil) {
////            println("Created directory \(dataDir)")
//        }
//
//
        if fm.fileExists(atPath: sqliteUrl.path) {
            print("File exists")

        } else {
            NSData().write(to: sqliteUrl, atomically: true)
        }

        return sqliteUrl as NSURL
    }
    
}
