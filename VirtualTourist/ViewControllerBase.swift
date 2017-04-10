//
//  ViewControllerBase.swift
//  VirtualTourist
//
//  Created by Dylan Miller on 3/21/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import UIKit
import MBProgressHUD

// Base class for view controllers.
class ViewControllerBase: UIViewController {

    override func viewDidLoad() {
        
        super.viewDidLoad()
    }
    
    // Display progress HUD before a request is made.
    func prepareForRequest() {
        
        MBProgressHUD.showAdded(to: view, animated: true)
    }
    
    // Hide progress HUD after a request is made.
    func requestDidSucceed() {
        
        DispatchQueue.main.async {
            
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }

    // Hide progress HUD after a request is made. Display an error for
    // failure.
    func requestDidFail(title: String, message: String, handler: ((UIAlertAction) -> Void)? = nil) {
        
        DispatchQueue.main.async {
            
            MBProgressHUD.hide(for: self.view, animated: true)
            
            self.displayError(title: title, message: message, handler: handler)
        }
    }

    // Display an error alert controller.
    func displayError(title: String, message: String, handler: ((UIAlertAction) -> Void)? = nil) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: handler))
        self.present(alert, animated: true)
    }
}
