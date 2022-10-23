//
//  ToDos.swift
//  Klear
//
//  Created by Spencer Ward on 13/10/2022.
//  Copyright © 2022 Yorwos Pallikaropoulos. All rights reserved.
//

import Foundation

class ToDo {
    private var title: String
    private var done: Bool

    init(title: String, done: Bool) {
        self.title = title
        self.done = done
    }
    
    func setTitle(title: String?) {
        self.title = title ?? ""
    }

    func getTitle() -> String {
        return title
    }
    
    func isDone() -> Bool {
        return done
    }
    
    func isNotDone() -> Bool {
        return !done
    }
    
    func setNotDone() {
        done = false
    }
    
    func setDone() {
        done = true
    }
    
    func toggleDone() {
        done = !done
    }

    func to_s() -> String {
        "<" + title + "> " + String(done)
    }
}

class ToDos {
    //    this holds the actual items
    private var listOfItems:[ToDo] = []
        
    init(items: [ToDo]) {
        listOfItems = items
    }
    
    func count() -> Int {
        return listOfItems.count
    }
    
    func getAt(index: Int) -> ToDo {
        return listOfItems[index]
    }
    
    func remove(at: Int) {
        listOfItems.remove(at: at)
    }
    
    func append(item: ToDo) {
        listOfItems.append(item)
    }
    
    func insert(item: ToDo, at: Int) {
        listOfItems.insert(item, at: at)
    }
    
    func swap(from: Int, to: Int) {
        listOfItems.swapAt(from, to)
    }
    

    
 
    
    var indexOfFirstNotDoneItem:Int{
        get{
            if let index = listOfItems.firstIndex(where: {$0.isNotDone() }){
                return listOfItems.count > 0 ? index - 1 : index
            }else{
                return listOfItems.count - 1
            }
        }
    }
    
    //    helper for the calculation of colors
    var countOfNotDoneItems:Int{
        return listOfItems.filter({$0.isNotDone()}).count
    }
    
    
    // model and tableView have opposite orders
    // new item is appended in the model array , but shown first in the tableView
    var orderedListOfItems:[ToDo] {
        get{
            var reversed = listOfItems
            reversed.reverse()
            return reversed
        }
    }
    
    var indexOfFirstDoneItem: Int{
        get{
            if let index = orderedListOfItems.firstIndex(where: { $0.isDone() }) {
                return index
            }else{
                return 0
            }
        }
    }
    
    var indexOfLastDoneItem:Int{
        get{
            if let index = listOfItems.lastIndex(where: {$0.isDone() }){
                return listOfItems.count > 0 ? index + 1 : index
            }else{
                return 0
            }
        }
    }
    
    //    convert from row number to index and vice versa
    //    (same algorithm used in both cases, used differently for clarity
    func rowNumberToIndex(from index:Int) -> Int{
        return (listOfItems.count - 1 - index)
    }
    
    func indexToRowNumber(from row: Int) -> Int {
        return rowNumberToIndex(from: row)
    }
    
    func to_s() -> String {
        listOfItems.map { $0.to_s() }.joined(separator: ", ")
    }
}
