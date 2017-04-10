//
//  Constants.swift
//  VirtualTourist
//
//  Created by Dylan Miller on 3/31/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import UIKit

struct Constants {
    
    struct AnnotationId {
        
        static let pin = "pinAnnotation"
    }
    
    struct SegueName {
        
        static let photoAlbum = "photoAlbumSegue"
    }

    struct CellReuseId {
        
        static let photoAlbum = "PhotoAlbumCell"
    }
    
    struct ImageAlpha {
        
        static let selected: CGFloat = 0.25
        static let unselected: CGFloat = 1.0
    }
    
    struct CoreData {
        
        struct EntityName {
            
            static let pin = "Pin"
            static let photo = "Photo"
        }
        
        struct AttributeName {
            
            struct Pin {
                
                static let latitude = "latitude"
                static let longitude = "longitude"
            }
            
            struct Photo {
                
                static let imageUrlString = "imageUrlString"
                static let imageData = "imageData"
            }
        }

        struct RelationshipName {
            
            struct Pin {
                
                static let photos = "photos"
            }
            
            struct Photo {
                
                static let pin = "pin"
            }
        }
}
    
    struct Flickr {
        
        static let imageUrlCount = 21 // 3 columns * 7 rows

        struct Url {
        
            static let scheme = "https"
            static let host = "api.flickr.com"
            static let path = "/services/rest"
        }

        struct ParameterKeys {
            
            static let method = "method"
            static let apiKey = "api_key"
            static let latitude = "lat"
            static let longitude = "lon"
            static let safeSearch = "safe_search"
            static let extras = "extras"
            static let format = "format"
            static let noJsonCallback = "nojsoncallback"
            static let page = "page"
        }
        
        struct ParameterValues {
            
            static let method = "flickr.photos.search"
            static let apiKey = "700afd00ac01ac8ba1aebf1427c84fc5"
            static let useSafeSearch = "1"
            static let mediumUrl = "url_m"
            static let responseFormat = "json"
            static let disableJsonCallback = "1"
        }
        
        struct ResponseKeys {
            
            static let status = "stat"
            static let photos = "photos"
            static let pages = "pages"
            static let photo = "photo"
            static let mediumUrl = "url_m"
        }
        
        struct ResponseValues {
            
            static let okStatus = "ok"
        }
    }
}
