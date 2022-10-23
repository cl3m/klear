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
    
    class func clear(moc: NSManagedObjectContext, list: String) {
        let items = allRaw(moc: moc, list: list)
        items.forEach { moc.delete($0) }
        try! moc.save()
    }
    
    class func saveIn(moc: NSManagedObjectContext, todos: ToDos, list: String) {
        print("Saving to " + list + ": " + todos.to_s())
        clear(moc: moc, list: list)
        
        todos.forEach {
            let item = NSEntityDescription.insertNewObject(forEntityName: "Item", into:moc) as! Item
            item.title = $0.getTitle()
            item.done = $0.isDone()
            item.list = list
            try! moc.save()
        }
    }
    
    class func allIn(moc: NSManagedObjectContext, list: String) -> ToDos {
        let items = allRaw(moc: moc, list: list)
        let todos = ToDos(items: items.map { ToDo(title: $0.title ?? "", done: $0.done)})
        print("Loaded from " + list + ": " + todos.to_s())
        return todos
    }
    

    private class func allRaw(moc: NSManagedObjectContext, list: String) -> [Item] {
        let request = NSFetchRequest<Item>(entityName: "Item")
        let predicate = NSPredicate(format: "list == '" + list + "'")
        request.predicate = predicate
        return try! moc.fetch(request)
    }
    
}
