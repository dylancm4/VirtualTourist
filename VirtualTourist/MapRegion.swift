//
//  MapRegion.swift
//  VirtualTourist
//
//  Created by Dylan Miller on 3/3/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import MapKit

final class MapRegion: NSObject, NSCoding {
    
    static let currentKey = "currentMapRegion"
    static let latitudeKey = "latitude"
    static let longitudeKey = "longitude"
    static let latitudeDeltaKey = "latitudeDelta"
    static let longitudeDeltaKey = "longitudeDelta"

    var region = MKCoordinateRegion()
    
    init(_ region: MKCoordinateRegion) {
        
        self.region = region
    }
    
    init(obj: AnyObject) {
        
        region.center.latitude = obj.double(forKey: MapRegion.latitudeKey)
        region.center.longitude = obj.double(forKey: MapRegion.longitudeKey)
        region.span.latitudeDelta = obj.double(forKey: MapRegion.latitudeDeltaKey)
        region.span.longitudeDelta = obj.double(forKey: MapRegion.longitudeDeltaKey)
    }
    
    init(coder aDecoder: NSCoder) {
        
        region.center.latitude = aDecoder.decodeDouble(forKey: MapRegion.latitudeKey)
        region.center.longitude = aDecoder.decodeDouble(forKey: MapRegion.longitudeKey)
        region.span.latitudeDelta = aDecoder.decodeDouble(forKey: MapRegion.latitudeDeltaKey)
        region.span.longitudeDelta = aDecoder.decodeDouble(forKey: MapRegion.longitudeDeltaKey)
    }
    
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(region.center.latitude, forKey: MapRegion.latitudeKey)
        aCoder.encode(region.center.longitude, forKey: MapRegion.longitudeKey)
        aCoder.encode(region.span.latitudeDelta, forKey: MapRegion.latitudeDeltaKey)
        aCoder.encode(region.span.longitudeDelta, forKey: MapRegion.longitudeDeltaKey)
    }
    

    static var _current: MapRegion?
    class var current: MapRegion? {
        
        get {
            
            if (_current == nil) {
                
                let defaults = UserDefaults.standard
                
                if let data = defaults.object(forKey: currentKey) as? Data {
                    
                    _current = NSKeyedUnarchiver.unarchiveObject(with: data) as? MapRegion
                }
            }
            return _current
        }
        set(mapRegion) {
            
            _current = mapRegion
            
            // Do not block the main thread.
            DispatchQueue.global(qos: .background).async {
                
                let defaults = UserDefaults.standard
                
                if let mapRegion = mapRegion {
                    
                    let data = NSKeyedArchiver.archivedData(withRootObject: mapRegion)
                    defaults.set(data, forKey: currentKey)
                }
                else {
                    
                    defaults.removeObject(forKey: currentKey)
                }
                
                defaults.synchronize()
            }
        }
    }
}
