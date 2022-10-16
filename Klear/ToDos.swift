//
//  ToDos.swift
//  Klear
//
//  Created by Spencer Ward on 13/10/2022.
//  Copyright © 2022 Yorwos Pallikaropoulos. All rights reserved.
//

import Foundation

class ToDos {

    //    this holds the actual items
    private var listOfItems:[Item] = []
        
    init(items: [Item]) {
        listOfItems = items
    }
    
    func count() -> Int {
        return listOfItems.count
    }
    
    func setTitle(index: Int, title: String?) {
        listOfItems[index].title = title ?? ""
    }
    
    func setNotDone(index: Int) {
        listOfItems[index].done = false
    }
    
    func setDone(index: Int) {
        listOfItems[index].done = true
    }
    
    func toggleDone(index: Int) {
        listOfItems[index].done = !listOfItems[index].done
    }
    
    func getAt(index: Int) -> Item {
        return listOfItems[index]
    }
    
    func remove(at: Int) {
        listOfItems.remove(at: at)
    }
    
    func append(item: Item) {
        listOfItems.append(item)
    }
    
    func insert(item: Item, at: Int) {
        listOfItems.insert(item, at: at)
    }
    
    func swap(from: Int, to: Int) {
        var memo = listOfItems.map {
            ($0.title, $0.done)
        }
        memo.swapAt(from, to)
        
        for (index, element) in memo.enumerated() {
            print("Item \(index): \(element)")
            let savedItem = listOfItems[index]
            savedItem.title = element.0
            savedItem.done = element.1
        }
    }
    
    var indexOfLastDoneItem:Int{
        get{
            if let index = listOfItems.lastIndex(where: {$0.done == true }){
                return listOfItems.count > 0 ? index + 1 : index
            }else{
                return 0
            }
        }
    }
    
    var indexOfFirstNotDoneItem:Int{
        get{
            if let index = listOfItems.firstIndex(where: {$0.done == false }){
                return listOfItems.count > 0 ? index - 1 : index
            }else{
                return listOfItems.count - 1
            }
        }
    }
    
    //    helper for the calculation of colors
    var countOfNotDoneItems:Int{
        return listOfItems.filter({$0.done == false}).count
    }
    
    
    // model and tableView have opposite orders
    // new item is appended in the model array , but shown first in the tableView
    var orderedListOfItems:[Item] {
        get{
            var reversed = listOfItems
            reversed.reverse()
            return reversed
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
    
}
