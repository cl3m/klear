//
//  Item.swift
//  Klear
//
//  Created by Spencer Ward on 06/10/2022.
//  Copyright © 2022 Yorwos Pallikaropoulos. All rights reserved.
//

import Foundation
import CoreData

let listsName = "_LISTS_"

class ItemRepo {
    private let moc = CoreDataStack.regularStore().moc!
    
    class func create() -> ToDo {
        return ToDo(title: "", done: false)
    }
    
    class func clear(moc: NSManagedObjectContext, list: List) {
        let items = allRaw(moc: moc, list: list)
        items.forEach { moc.delete($0) }
        try! moc.save()
    }
    
    class func saveIn(moc: NSManagedObjectContext, todos: ToDos, name: String) {
        print("Saving to " + name + ": " + todos.to_s())
        if name == listsName {
            let lists = getLists(moc)
            for list in lists {
                if !todos.todos.map(\.title).contains(list.title ?? "") {
                    moc.delete(list)
                } else {
                    list.order = Int16(todos.todos.map(\.title).firstIndex(of: list.title!) ?? 0)
                }
            }
            for list in todos.todos.map(\.title) {
                if !lists.map(\.title).contains(list) {
                    let newList = create(moc, name: list)
                    newList.order = Int16(todos.todos.map(\.title).firstIndex(of: list) ?? 0)
                }
            }
            try! moc.save()
        } else {
            let list = getList(moc: moc, name: name)
            clear(moc: moc, list: list)
            
            todos.listOfItems.enumerated().forEach({ el in
                let item = NSEntityDescription.insertNewObject(forEntityName: "Item", into:moc) as! Item
                item.title = el.element.title
                item.done = el.element.done
                item.order = Int16(el.offset)
                item.list = list
                try! moc.save()
            })
        }
    }
    
    class func allIn(moc: NSManagedObjectContext, name: String? = nil) -> (String, ToDos) {
        if name == listsName {
            let lists = try! moc.fetch(NSFetchRequest<List>(entityName: "List")).sorted(by: { $0.order > $1.order})
            let todos = ToDos(items: lists.map { ToDo(title: $0.title ?? "", done: false)})
            print("Loaded from " + name! + ": " + todos.to_s())
            return (name!, todos)
        } else {
            let list = getList(moc: moc, name: name ?? getLists(moc).first?.title ?? "Personal")
            let items = allRaw(moc: moc, list: list).sorted(by: { $0.order < $1.order})
            let todos = ToDos(items: items.map { ToDo(title: $0.title ?? "", done: $0.done)})
            print("Loaded from " + (list.title ?? "") + ": " + todos.to_s())
            return (list.title ?? "", todos)
        }
    }
    

    private class func allRaw(moc: NSManagedObjectContext, list: List) -> [Item] {
        let request = NSFetchRequest<Item>(entityName: "Item")
        let predicate = NSPredicate(format: "list == %@", list)
        request.predicate = predicate
        return try! moc.fetch(request)
    }
    
    private class func getList(moc: NSManagedObjectContext, name: String) -> List {
        let request = NSFetchRequest<List>(entityName: "List")
        let predicate = NSPredicate(format: "title == '" + name + "'")
        request.predicate = predicate
        if let list = try! moc.fetch(request).first {
            return list
        } else {
            return create(moc, name: name)
        }
    }
    
    private class func create(_ moc: NSManagedObjectContext, name: String) -> List {
        let list = NSEntityDescription.insertNewObject(forEntityName: "List", into:moc) as! List
        list.title = name
        list.order = 0
        try! moc.save()
        return list
    }
    
    private class func getLists(_ moc: NSManagedObjectContext) -> [List] {
        return try! moc.fetch(NSFetchRequest<List>(entityName: "List"))
    }
}
