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
    class func makeIn(moc: NSManagedObjectContext) -> Item? {
        print("Make new item")
        let newObject = NSEntityDescription.insertNewObject(forEntityName: "Item", into:moc) as! Item
        return newObject
    }

    class func allIn(moc: NSManagedObjectContext) -> ToDos {
        print("get all items")
        let request = NSFetchRequest<Item>(entityName: "Item")
        
         do {
             return try ToDos(items: moc.fetch(request))
         } catch {
             return ToDos(items: [])
         }
    }
}
