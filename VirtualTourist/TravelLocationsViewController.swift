//
//  TravelLocationsViewController.swift
//  VirtualTourist
//
//  Created by Dylan Miller on 3/1/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class TravelLocationsViewController: ViewControllerBase {
    
    @IBOutlet weak var mapView: MKMapView!

    var selectedPin: Pin?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Set the center of the map and the zoom level to the saved value.
        if let mapRegion = MapRegion.current {
            
            mapView.region = mapRegion.region
        }
        
        // Fetch the pins.
        if let pins = fetchPins(latitude: nil, longitude: nil) {
            
            for pin in pins {
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude), longitude: CLLocationDegrees(pin.longitude))
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let photoAlbumViewController = segue.destination as? PhotoAlbumViewController {
            
            photoAlbumViewController.pin = selectedPin
        }
    }

    // Add an annotation to the map when the user does a long press.
    @IBAction func onLongPress(_ sender: UILongPressGestureRecognizer) {

        if sender.state == .began {
            
            let annotation = MKPointAnnotation()
            let mapPoint = sender.location(in: mapView)
            annotation.coordinate = mapView.convert(mapPoint, toCoordinateFrom: mapView)
            mapView.addAnnotation(annotation)

            // Creating a Pin adds it to CoreData.
            _ = Pin(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, insertInto: CoreDataStack.shared.context)
            
            // Save when user adds pin.
            CoreDataStack.shared.save()
        }
    }
    
    // Fetch the Pin objects from CoreData. If latitude and longitude
    // are specified, fetch only the matching Pin object.
    func fetchPins(latitude: Double?, longitude: Double?) -> [Pin]? {
        
        // Create an NSFetchRequest to fetch the pins.
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(
                key: Constants.CoreData.AttributeName.Pin.latitude, ascending: true),
            NSSortDescriptor(
                key: Constants.CoreData.AttributeName.Pin.longitude, ascending: false)]
        
        // Optionally add latitude and longitude predicates.
        if let latitude = latitude, let longitude = longitude {
            
            let latitudePredicate = NSPredicate(format: "\(Constants.CoreData.AttributeName.Pin.latitude) = %@", argumentArray: [latitude])
            let longitudePredicate = NSPredicate(format: "\(Constants.CoreData.AttributeName.Pin.longitude) = %@", argumentArray: [longitude])
            fetchRequest.predicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [latitudePredicate, longitudePredicate])
        }
        
        // Create and start an NSFetchedResultsController.
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.shared.context, sectionNameKeyPath: nil, cacheName: nil)
        do {
            
            try fetchedResultsController.performFetch()
        }
        catch let error as NSError {
            
            displayError(title: "Error Performing Fetch", message: "\(error.localizedDescription)")
        }
        
        return fetchedResultsController.fetchedObjects
    }
}

// MKMapViewDelegate
extension TravelLocationsViewController: MKMapViewDelegate {
    
    // Create/reuse an MKAnnotationView with an animated pin drop.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: Constants.AnnotationId.pin) as? MKPinAnnotationView
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.AnnotationId.pin)
            pinView!.animatesDrop = true
        }
        else {
            
            pinView!.annotation = annotation
        }        
        return pinView
    }
    
    // When an annotation is tapped, seque to the PhotoAlbumViewController.
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        // Deselect the annotation so that it can be selected again.
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        // Fetch the pin.
        if let latitude = view.annotation?.coordinate.latitude, let longitude = view.annotation?.coordinate.longitude {
            
            if let pins = fetchPins(latitude: latitude, longitude: longitude), pins.count > 0 {
                
                self.selectedPin = pins[0]
                performSegue(withIdentifier: Constants.SegueName.photoAlbum, sender: nil)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        MapRegion.current = MapRegion(mapView.region)
    }
}

