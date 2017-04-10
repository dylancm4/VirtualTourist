//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Dylan Miller on 4/9/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var imageData: NSData?
    @NSManaged public var imageUrlString: String?
    @NSManaged public var pin: Pin?

}
