//
//  CoreDataStack.swift
//  VirtualTourist
//
//  Created by Dylan Miller on 4/8/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import CoreData

// MARK: - CoreDataStack

struct CoreDataStack {
    
    static let shared = CoreDataStack(modelName: "Model")!

    // MARK: Properties
    
    private let modelURL: URL
    private let model: NSManagedObjectModel
    internal let coordinator: NSPersistentStoreCoordinator
    let context: NSManagedObjectContext
    internal let dbURL: URL
    
    // MARK: Initializers
    
    init?(modelName: String) {
        
        // Assumes the model is in the main bundle.
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            
            fatalError("Unable to find \(modelName) in the main bundle.")
        }
        self.modelURL = modelURL
        
        // Try to create the model from the URL.
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            
            fatalError("Unable to create a model from \(modelURL).")
        }
        self.model = model

        // Create the store coordinator.
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        // Create a context and add connect it to the coordinator.
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        
        // Add a SQLite store located in the documents folder.
        let fm = FileManager.default
        
        guard let docUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            
            fatalError("Unable to reach the documents folder.")
        }
        
        dbURL = docUrl.appendingPathComponent("model.sqlite")
        
        // Options for migration
        let options = [NSInferMappingModelAutomaticallyOption: true,NSMigratePersistentStoresAutomaticallyOption: true]
        
        
        do {
            
            try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: options as [NSObject : AnyObject]?)
        }
        catch {
            
            fatalError("Unable to add store at \(dbURL).")
        }
    }
    
    // MARK: Utils
    
    func addStoreCoordinator(_ storeType: String, configuration: String?, storeURL: URL, options : [NSObject:AnyObject]?) throws {
        
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL, options: nil)
    }
}

// MARK: - CoreDataStack (Removing Data)

internal extension CoreDataStack  {
    
    // Delete all the objects in the db. This won't delete the files, it will
    // just leave empty tables.
    func dropAllData() throws {
        
        try coordinator.destroyPersistentStore(at: dbURL, ofType: NSSQLiteStoreType, options: nil)
        try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: nil)
    }
}

// MARK: - CoreDataStack (Save Data)

extension CoreDataStack {
    
    func save() {
        
        if context.hasChanges {
            
            do {
                
                try context.save()
            }
            catch {
                
                fatalError("Error while saving context: \(error)")
            }
        }
    }

    func autoSave(_ delayInSeconds : Int) {
        
        if delayInSeconds > 0 {
            
            save()
            
            let delayInNanoSeconds = UInt64(delayInSeconds) * NSEC_PER_SEC
            let time = DispatchTime.now() + Double(Int64(delayInNanoSeconds)) / Double(NSEC_PER_SEC)
            
            DispatchQueue.main.asyncAfter(deadline: time) {
                
                self.autoSave(delayInSeconds)
            }
        }
    }
}
