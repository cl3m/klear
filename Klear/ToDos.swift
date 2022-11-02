//
//  ToDos.swift
//  Klear
//
//  Created by Spencer Ward on 13/10/2022.
//  Copyright © 2022 Yorwos Pallikaropoulos. All rights reserved.
//

import Foundation

class ToDo: CustomStringConvertible {
    var title: String
    var done: Bool
    
    init(title: String, done: Bool) {
        self.title = title
        self.done = done
    }
    
    func toggle() {
        done = !done
    }
    
    var description: String {
        return "\(title)\(done ? "✅":"")"
    }
}

class ToDos {
    //    this holds the actual items
    private(set) var listOfItems:[ToDo] = []
        
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
        if (at < count()) {
            listOfItems.remove(at: at)
        }
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
    
    func forEach(_ body: (ToDo) -> Void) {
        listOfItems.forEach(body)
    }
    
    var indexOfFirstNotDoneItem:Int{
        get{
            if let index = listOfItems.firstIndex(where: {!$0.done}){
                return listOfItems.count > 0 ? index - 1 : index
            }else{
                return listOfItems.count - 1
            }
        }
    }
    
    //    helper for the calculation of colors
    var countOfNotDoneItems:Int{
        return listOfItems.filter({!$0.done}).count
    }
    
    
    // model and tableView have opposite orders
    // new item is appended in the model array , but shown first in the tableView
    var todos:[ToDo] {
        get{
            var reversed = listOfItems
            reversed.reverse()
            return reversed
        }
    }
    
    var indexOfFirstDoneItem: Int{
        get{
            if let index = todos.firstIndex(where: { $0.done}) {
                return index
            }else{
                return 0
            }
        }
    }
    
    var indexOfLastDoneItem:Int{
        get{
            if let index = listOfItems.lastIndex(where: {$0.done}){
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
        listOfItems.map { "\($0)" }.joined(separator: ", ")
    }
}
