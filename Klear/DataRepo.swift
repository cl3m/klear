//
//  DataRepo.swift
//  Klear
//
//  Created by Spencer Ward on 06/10/2022.
//  Copyright © 2022 Yorwos Pallikaropoulos. All rights reserved.
//

import CoreData

class CoreDataContextProvider {
    // Returns the current container view context
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // The persistent container
    private var persistentContainer: NSPersistentContainer

    init(completionClosure: ((Error?) -> Void)? = nil) {
        // Create a persistent container
        persistentContainer = NSPersistentContainer(name: "Model")
        persistentContainer.loadPersistentStores() { (description, error) in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")

            }
            completionClosure?(error)
        }
    }
    // Creates a context for background work
    func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
}
