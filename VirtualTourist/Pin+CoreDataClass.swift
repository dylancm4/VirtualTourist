//
//  Pin+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Dylan Miller on 4/8/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import Foundation
import CoreData

@objc(Pin)
public class Pin: NSManagedObject {
    
    convenience init(latitude: Double, longitude: Double, insertInto context: NSManagedObjectContext) {
        
        if let entity = NSEntityDescription.entity(forEntityName: Constants.CoreData.EntityName.pin, in: context) {
            
            self.init(entity: entity, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
        }
        else {
            
            fatalError("Unable to find entity name \(Constants.CoreData.EntityName.pin).")
        }
    }
}
