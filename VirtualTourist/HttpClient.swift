//
//  HttpClient.swift
//  VirtualTourist
//
//  Created by Dylan Miller on 4/3/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import UIKit

// Contains HTTP client functionality.
class HttpClient {
    
    // Shared instance.
    static let shared = HttpClient()

    // Shared session.
    let session = URLSession.shared

    // Get the image data for the specified image URL.
    func getImageDataFromUrl(url: URL, success: @escaping (_ imageData: Data) -> Void, failure: @escaping (_ error: Error) -> Void) {
        
        // Create network request.
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { (data, response, error) in
            
            func displayError(_ error: String) {
                
                let userInfo = [NSLocalizedDescriptionKey : error]
                failure(NSError(domain: "ViewControllerBase", code: 1, userInfo: userInfo))
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
            
            // Return the image data.
            success(data)
        }
        
        // Start the task.
        task.resume()
    }
}
