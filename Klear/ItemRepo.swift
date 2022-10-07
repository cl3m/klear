//
//  Item.swift
//  Klear
//
//  Created by Spencer Ward on 06/10/2022.
//  Copyright © 2022 Yorwos Pallikaropoulos. All rights reserved.
//

import Foundation
import CoreData

class ItemRepo: NSManagedObject {
    
    @NSManaged var title: String
    @NSManaged var done: Bool
    
    class func make() -> Item? {
        let cdStack = CoreDataStack.regularStore()
        return makeIn(moc: cdStack.moc!)
    }

    class func makeIn(moc: NSManagedObjectContext) -> Item? {
        let newObject = NSEntityDescription.insertNewObject(forEntityName: "Item", into:moc) as! Item
        return newObject
    }
    
    class func save() {
        let cdStack = CoreDataStack.regularStore()
        try! cdStack.moc?.save()
    }
    
    class func all() -> [Item] {
        let cdStack = CoreDataStack.regularStore()
        return allIn(moc: cdStack.moc!)
    }
    
    class func allIn(moc: NSManagedObjectContext) -> [Item] {
        let request = Item.fetchRequest()
        
         do {
             return try moc.fetch(request)
         } catch {
             return []
         }
    }
    
    override func awakeFromInsert() {
        title = ""
    }
}
