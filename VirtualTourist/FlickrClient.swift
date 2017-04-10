//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Dylan Miller on 4/1/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import Foundation
import GameplayKit

// Interfaces with the Flickr API.
class FlickrClient {
    
    // Shared instance.
    static let shared = FlickrClient()
    
    // Get a random array of image URLs for the specified latitude and
    // longitude.
    func getImageUrls(latitude: Double, longitude: Double, success: @escaping (_ imageUrlStrings: [String]) -> Void, failure: @escaping (_ error: Error) -> Void) {
        
        let funcSuccess = success
        let funcFailure = failure
        
        // Set up parameters.
        let parameters: [String : AnyObject] = [
            
            Constants.Flickr.ParameterKeys.method: Constants.Flickr.ParameterValues.method as AnyObject,
            Constants.Flickr.ParameterKeys.apiKey: Constants.Flickr.ParameterValues.apiKey as AnyObject,
            Constants.Flickr.ParameterKeys.latitude: latitude as AnyObject,
            Constants.Flickr.ParameterKeys.longitude: longitude as AnyObject,
            Constants.Flickr.ParameterKeys.safeSearch: Constants.Flickr.ParameterValues.useSafeSearch as AnyObject,
            Constants.Flickr.ParameterKeys.extras: Constants.Flickr.ParameterValues.mediumUrl as AnyObject,
            Constants.Flickr.ParameterKeys.format: Constants.Flickr.ParameterValues.responseFormat as AnyObject,
            Constants.Flickr.ParameterKeys.noJsonCallback: Constants.Flickr.ParameterValues.disableJsonCallback as AnyObject
        ]
        
        photosSearch(
            parameters: parameters,
            success: { (photosDict: [String : AnyObject]) in
                
                func displayError(_ error: String) {
                    
                    let userInfo = [NSLocalizedDescriptionKey : error]
                    funcFailure(NSError(domain: "FlickrClient", code: 1, userInfo: userInfo))
                }
                
                // GUARD: Is "pages" key in the photosDictionary?
                guard let totalPages = photosDict[Constants.Flickr.ResponseKeys.pages] as? Int else {
                    
                    displayError("Cannot find key '\(Constants.Flickr.ResponseKeys.pages)' in \(photosDict)")
                    return
                }
                
                // Return the photos from a random page.
                let randomPage = Int(arc4random_uniform(UInt32(totalPages))) + 1
                self.getImageUrls(
                    parameters: parameters,
                    withPageNumber: randomPage,
                    success: { (urls: [String]) in
                        
                        // The paging mechanism of flickr.photos.search is
                        // buggy and sometimes returns the same reults for
                        // different pages. We work around this problem by
                        // retreiving a random page with the default 250
                        // entries and then selecting 21 random entries from
                        // that page.
                        let urlsSlice = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: urls).prefix(Constants.Flickr.imageUrlCount)
                        funcSuccess(Array(urlsSlice) as! [String])
                    },
                    failure: { (error: Error) in
                        
                        funcFailure(error)
                    })
            },
            failure: { (error: Error) in
            
                funcFailure(error)
            })
    }
    
    // Get an array of image URLs for the specified URL parameters and page
    // number.
    private func getImageUrls(parameters: [String: AnyObject], withPageNumber: Int, success: @escaping (_ imageUrlStrings: [String]) -> Void, failure: @escaping (_ error: Error) -> Void) {
        
        let funcSuccess = success
        let funcFailure = failure
        
        // add the page to the method's parameters
        var parametersWithPageNumber = parameters
        parametersWithPageNumber[Constants.Flickr.ParameterKeys.page] = withPageNumber as AnyObject
        
        photosSearch(
            parameters: parametersWithPageNumber,
            success: { (photosDict: [String : AnyObject]) in
                
                func displayError(_ error: String) {
                    
                    let userInfo = [NSLocalizedDescriptionKey : error]
                    funcFailure(NSError(domain: "FlickrClient", code: 1, userInfo: userInfo))
                }
                
                // GUARD: Is the "photo" key in photosDictionary?
                guard let photosArray = photosDict[Constants.Flickr.ResponseKeys.photo] as? [[String: AnyObject]] else {
                    
                    displayError("Cannot find key '\(Constants.Flickr.ResponseKeys.photo)' in \(photosDict)")
                    return
                }
                
                if photosArray.count == 0 {
                    
                    displayError("No photos found.")
                    return
                }
                
                var imageUrlStrings = [String]()
                for photoDict in photosArray {
                    
                    // GUARD: Does photo have a key for 'url_m'?
                    guard let imageUrlString = photoDict[Constants.Flickr.ResponseKeys.mediumUrl] as? String else {
                        
                        displayError("Cannot find key '\(Constants.Flickr.ResponseKeys.mediumUrl)' in \(photoDict)")
                        return
                    }
                    
                    imageUrlStrings.append(imageUrlString)
                }
                
                funcSuccess(imageUrlStrings)
            },
            failure: { (error: Error) in
                
                funcFailure(error)
            })
    }

    // Use the flickr.photos.search method to retrieve a photos dictionary
    // for the specified URL parameters.
    func photosSearch(parameters: [String: AnyObject], success: @escaping (_ photosDict: [String: AnyObject]) -> Void, failure: @escaping (_ error: Error) -> Void) {
        
        // Create session and request.
        let session = URLSession.shared
        let request = URLRequest(url: getUrlFromParameters(parameters))
        
        // Create network request.
        let task = session.dataTask(with: request) { (data, response, error) in
            
            func displayError(_ error: String) {
                
                let userInfo = [NSLocalizedDescriptionKey : error]
                failure(NSError(domain: "FlickrClient", code: 1, userInfo: userInfo))
            }
            
            // GUARD: Was there an error?
            guard (error == nil) else {
                
                displayError("There was an error with your request: \(error)")
                return
            }
            
            // GUARD: Did we get a successful 2XX response?
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            // GUARD: Was there any data returned?
            guard let data = data else {
                
                displayError("No data was returned by the request!")
                return
            }
            
            // Parse the data.
            let parsedResult: [String:AnyObject]!
            do {
                
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            }
            catch {
                
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            // GUARD: Did Flickr return an error (stat != ok)?
            guard let stat = parsedResult[Constants.Flickr.ResponseKeys.status] as? String, stat == Constants.Flickr.ResponseValues.okStatus else {
                
                displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            // GUARD: Is "photos" key in our result?
            guard let photosDict = parsedResult[Constants.Flickr.ResponseKeys.photos] as? [String:AnyObject] else {
                
                displayError("Cannot find keys '\(Constants.Flickr.ResponseKeys.photos)' in \(parsedResult)")
                return
            }
            
            /* Debug code, keep.
            let pageKey = "page"
            let pagesKey = "pages"
            let perPageKey = "perpage"
            let totalKey = "total"
            if let pageValue = photosDict[pageKey] as? Int {
                print("page = \(pageValue)")
            }
            if let pagesValue = photosDict[pagesKey] as? Int {
                print("pages = \(pagesValue)")
            }
            if let perPageValue = photosDict[perPageKey] as? Int {
                print("perPage = \(perPageValue)")
            }
            if let totalValue = photosDict[totalKey] as? Int {
                print("total = \(totalValue)")
            }
            print("********** RAW DATA START **********")
            let dataString = String(data: data, encoding: String.Encoding.utf8) ?? "Data could not be printed"
            print("\(dataString)")
            print("********** RAW DATA END **********")*/
            
            success(photosDict)
        }
        
        // Start the task.
        task.resume()
    }

    // Create a Flickr URL from the specified parameters.
    private func getUrlFromParameters(_ parameters: [String: AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.Url.scheme
        components.host = Constants.Flickr.Url.host
        components.path = Constants.Flickr.Url.path
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
}
