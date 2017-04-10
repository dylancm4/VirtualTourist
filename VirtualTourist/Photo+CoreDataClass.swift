//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Dylan Miller on 4/8/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {
    
    convenience init(imageUrlString: String, insertInto context: NSManagedObjectContext) {
        
        if let entity = NSEntityDescription.entity(forEntityName: Constants.CoreData.EntityName.photo, in: context) {
            
            self.init(entity: entity, insertInto: context)
            self.imageUrlString = imageUrlString
            self.imageData = nil
        }
        else {
            
            fatalError("Unable to find entity name \(Constants.CoreData.EntityName.photo).")
        }
    }
}
