//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Dylan Miller on 3/2/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import UIKit
import CoreData
import MapKit
import MBProgressHUD

class PhotoAlbumViewController: ViewControllerBase {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var removeSelectedPicturesButton: UIButton!
    
    var pin: Pin!
    var selectedCells = Set<IndexPath>()
    var insertedCells = Set<IndexPath>()
    var deletedCells = Set<IndexPath>()
    var updatedCells = Set<IndexPath>()

    var fetchedResultsController : NSFetchedResultsController<Photo>!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Add and zoom to annotation for the pin.
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude), longitude: CLLocationDegrees(pin.longitude))
        mapView.addAnnotation(annotation)
        mapView.showAnnotations([annotation], animated: true)
        
        // Create an NSFetchRequest to fetch the photos for this pin.
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Constants.CoreData.AttributeName.Photo.imageUrlString, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "\(Constants.CoreData.RelationshipName.Photo.pin) = %@", argumentArray: [pin])
        
        // Create and start the NSFetchedResultsController.
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.shared.context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            
            try fetchedResultsController.performFetch()
        }
        catch let error as NSError {
            
            displayError(title: "Error Performing Fetch", message: "\(error.localizedDescription)")
        }
        
        if let fetchedObjects = fetchedResultsController.fetchedObjects, fetchedObjects.count > 0 {
            
            updateButtons()
        }
        else { // nothing in CoreData for this pin
        
            loadNewCollection()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        // Save when user clicks OK button.
        if isMovingFromParentViewController {
            
            CoreDataStack.shared.save()
        }
    }
    
    @IBAction func onNewCollectionButton(_ sender: UIButton) {
    
        loadNewCollection()
    }
    
    @IBAction func onRemoveSelectedPicturesButton(_ sender: UIButton) {
        
        var photosToDelete = [Photo]()
        
        for indexPath in selectedCells {
            
            let photo = fetchedResultsController.object(at: indexPath)
            photosToDelete.append(photo)
        }
        
        let context = fetchedResultsController.managedObjectContext
        for photo in photosToDelete {
            
            context.delete(photo)
        }
        
        // Update the UI.
        selectedCells.removeAll()
        updateButtons()
    }
    
    // Load a new collection of photos.
    func loadNewCollection() {
        
        prepareForRequest() // show progress HUD
        
        selectedCells.removeAll()
        updateButtons()
        newCollectionButton.isEnabled = false
        
        let context = fetchedResultsController.managedObjectContext
        if let fetchedObjects = fetchedResultsController.fetchedObjects {
            
            for photo in fetchedObjects {
                
                context.delete(photo)
            }
        }
        
        FlickrClient.shared.getImageUrls(
            latitude: pin.latitude,
            longitude: pin.longitude,
            success: { (imageUrlStrings: [String]) in
                
                self.requestDidSucceed() // hide progress HUD
                
                DispatchQueue.main.async {
                    
                    // Create a Photo object for each image URL and add it to CoreData.
                    for imageUrlString in imageUrlStrings {
                        
                        // Creating a Photo adds it to CoreData.
                        let photo = Photo(imageUrlString: imageUrlString, insertInto: context)
                        photo.pin = self.pin
                    }

                    self.newCollectionButton.isEnabled = true
                }
            },
            failure: { (error: Error) in
                
                self.requestDidFail(title: "Error Searching Photos", message: "\(error.localizedDescription)") // hide progress HUD
                
                DispatchQueue.main.async {
                    
                    self.newCollectionButton.isEnabled = true
                }
            })
    }
    
    // Enable or disable the buttons based on whether any pictures are
    // selected.
    func updateButtons() {
        
        if selectedCells.count > 0 {
            
            newCollectionButton.isHidden = true
            removeSelectedPicturesButton.isHidden = false
        }
        else {
            
            newCollectionButton.isHidden = false
            removeSelectedPicturesButton.isHidden = true
        }
    }
}

extension PhotoAlbumViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return fetchedResultsController.sections![section].numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.CellReuseId.photoAlbum, for: indexPath) as! PhotoAlbumCollectionViewCell

        cell.photoImageView.alpha = self.selectedCells.contains(indexPath) ? Constants.ImageAlpha.selected : Constants.ImageAlpha.unselected
        
        let photo = fetchedResultsController.object(at: indexPath)
        
        // Hide progress HUD for cell which is reused while still
        // loading previous image.
        MBProgressHUD.hide(for: cell, animated: true)

        // Set the image if it has not already been set.
        if photo.imageData == nil {

            cell.photoImageView.image = nil
            if let imageUrlString = photo.imageUrlString, let imageUrl = URL(string: imageUrlString) {
                    
                MBProgressHUD.showAdded(to: cell, animated: true) // show progress HUD
                
                HttpClient.shared.getImageDataFromUrl(
                    url: imageUrl,
                    success: { (imageData: Data) in
                        
                        DispatchQueue.main.async {
                            
                            if let cell = collectionView.cellForItem(at: indexPath) {
                                
                                MBProgressHUD.hide(for: cell, animated: true) // hide progress HUD
                            }

                            photo.imageData = imageData as NSData
                            
                            // It is not necessary to set cell.photoImageView.image
                            // here, because NSFetchedResultsControllerDelegate
                            // takes care of it.
                        }
                    },
                    failure: { (error: Error) in
                        
                        DispatchQueue.main.async {
                            
                            if let cell = collectionView.cellForItem(at: indexPath) {
                                
                                MBProgressHUD.hide(for: cell, animated: true) // hide progress HUD
                            }
                            
                            self.displayError(title: "Error Getting Photo", message: "\(error.localizedDescription)")
                        }
                    })
            }
        }
        else {
        
            cell.photoImageView.image = UIImage(data: photo.imageData as! Data)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let cell = collectionView.cellForItem(at: indexPath) as? PhotoAlbumCollectionViewCell {
            
            if selectedCells.contains(indexPath) { // deselecting
                
                selectedCells.remove(indexPath)
                cell.photoImageView.alpha = Constants.ImageAlpha.unselected
            }
            else { // selecting
                
                selectedCells.insert(indexPath)
                cell.photoImageView.alpha = Constants.ImageAlpha.selected
            }
            
            updateButtons()
        }
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var size = 100
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            
            let numberOfItemsPerRow = 3
            let totalSpace = flowLayout.sectionInset.left + flowLayout.sectionInset.right + flowLayout.minimumInteritemSpacing * CGFloat(numberOfItemsPerRow - 1)
            size = Int((collectionView.bounds.width - totalSpace) / CGFloat(numberOfItemsPerRow))
        }
        return CGSize(width: size, height: size)
    }
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    // The fetched results controller is about to start processing of
    // one or more changes due to an add, remove, move, or update.
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        insertedCells.removeAll()
        deletedCells.removeAll()
        updatedCells.removeAll()
    }
    
    // A fetched object has been changed due to an add, remove, move,
    // or update.
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                
                insertedCells.insert(newIndexPath)
            }
        case .delete:
            if let indexPath = indexPath {
                
                deletedCells.insert(indexPath)
            }
        case .update:
            if let indexPath = indexPath {
                
                updatedCells.insert(indexPath)
            }
        case .move:
            break // N/A
        }
    }
    
    // The fetched results controller has completed processing of one or
    // more changes due to an add, remove, move, or update.
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        // Animate insert, delete, and reload operations as a group.
        collectionView.performBatchUpdates({

            for indexPath in self.insertedCells {
                
                self.collectionView.insertItems(at: [indexPath])
            }
            
            for indexPath in self.deletedCells {
                
                self.collectionView.deleteItems(at: [indexPath])
            }
            
            for indexPath in self.updatedCells {
                
                self.collectionView.reloadItems(at: [indexPath])
            }
        }, completion: nil)
    }
}
