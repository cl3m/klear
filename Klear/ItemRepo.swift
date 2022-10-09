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


    class func makeIn(moc: NSManagedObjectContext) -> Item? {
        print("Make new item")
        let newObject = NSEntityDescription.insertNewObject(forEntityName: "Item", into:moc) as! Item
        return newObject
    }

    class func allIn(moc: NSManagedObjectContext) -> [Item] {
        print("get all items")
        let request = NSFetchRequest<Item>(entityName: "Item")
//        let request = Item.fetchRequest()
        
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
