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
    class func create() -> ToDo {
        return ToDo(title: "", done: false)
    }
    
    class func clear(moc: NSManagedObjectContext) {
        let request = NSFetchRequest<Item>(entityName: "Item")
        let items = try! moc.fetch(request)
        items.forEach { moc.delete($0) }
        try! moc.save()
    }
    
    class func saveIn(moc: NSManagedObjectContext, todos: ToDos) {
        print("Saving items: " + todos.to_s())
        clear(moc: moc)

        todos.forEach {
            let item = NSEntityDescription.insertNewObject(forEntityName: "Item", into:moc) as! Item
            item.title = $0.getTitle()
            item.done = $0.isDone()
            try! moc.save()
        }
    }

    class func allIn(moc: NSManagedObjectContext) -> ToDos {
        let request = NSFetchRequest<Item>(entityName: "Item")
        let items = try! moc.fetch(request)
        let todos = ToDos(items: items.map { ToDo(title: $0.title ?? "", done: $0.done)})
        print("Loaded " + todos.to_s())
        return todos
    }
}
