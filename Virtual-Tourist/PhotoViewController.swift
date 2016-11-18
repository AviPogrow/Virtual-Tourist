//
//  PhotoViewController.swift
//  Virtual-Tourist
//
//  Created by Jack Ngai on 10/22/16.
//  Copyright © 2016 Jack Ngai. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    // MARK: Outlets
    @IBOutlet weak var miniMap: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var getNewCollectionOrDeleteButton: UIButton!

    
    // MARK: Properties
    
    // Show Photos Step 1 & 2: Tap a pin, send pin to PhotoViewController (this is done through prepare for segue in MapViewController).
    var selectedPin:Pin!
    
    // This holds all photos for a specific pin
    var photos: [Photo] = []
    
    // This holds photos that will be displayed in UICollectionView
    var selectedPhotos: [Photo] = []
    
    // This holds photos that the user selected to be deleted from the album
    var photosToBeDeleted: [Photo] = []
    
    // Get access to context
    var managedContext = CoreDataStack.sharedInstance().persistentContainer.viewContext
    
    // Flag to confirm this view is active, set to true in ViewDidLoad, set to false in ViewWillDisappear
    // Used by loadImageorURL method to stop loading images from Flickr if view is no longer active
    var viewActive = false
    

    // MARK: View Lifecycle methods
    override func viewDidLoad() {
        
        // Setup Mini Map
        super.viewDidLoad()
        let regionRadius: CLLocationDistance = 1000
        let region = MKCoordinateRegionMakeWithDistance(selectedPin.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        miniMap.setRegion(region, animated: true)
        miniMap.addAnnotation(selectedPin)
        
        viewActive = true
        
        // Show Photos Step 3: Place all photos in selectedPin to a photos array
        photos = Array(selectedPin!.photos!) as! [Photo]
        
        // MARK: Test Code
        var downloaded = 0
        var notDownloaded = 0
        for photo in photos{
            if photo.image == nil{
                notDownloaded += 1
            } else {
                downloaded += 1
            }
        }
        print("downloaded: \(downloaded), not downloaded: \(notDownloaded)")

        var photosMarked = 0
        for photo in photos{
            if photo.inAlbum{
                photosMarked += 1
            }
        }
        print("Photos marked 'inAlbum': \(photosMarked)")
        // End Test Code
        
    
        // Show Photos Step 4: Check each photo see if they are "inAlbum", add them to selectedPhotos array
        selectedPhotos = checkInAlbumFlag(photos: photos)
        
        // Show Photos Step 5: if no photos were marked "inAlbum", randomly select 21 photos
        if selectedPhotos.isEmpty {
            selectedPhotos = randomlySelectPhotos(photos: photos)
        }
        
        // Show Photos Step 7a: (Step 6 in randomlySelectPhotos method) Save photos to managedContext
        selectedPin.photos = Set(photos) as NSSet
        
        // Show Photos Step 7b: Save to Core Data
        CoreDataStack.sharedInstance().saveContext()
        
        photoCollectionView.dataSource = self
        photoCollectionView.delegate = self
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        viewActive = false
        
        // Save to Core Data
        DispatchQueue.global(qos: .background).async {
            self.selectedPin.photos = Set(self.photos) as NSSet
            CoreDataStack.sharedInstance().saveContext()
        }

        
    }
    

    
    // MARK: Actions
    
    @IBAction func getNewCollectionOrDelete(_ sender: UIButton) {
        
        if photosToBeDeleted.isEmpty{
            // getNewCollection Step 1: Remove all "inAlbum" flags in photos array
            for photo in photos{
                photo.inAlbum = false
            }
            
            // getNewCollection Step 2: Empty selectedPhotos array
            selectedPhotos = []
            
            // getNewCollection Step 3: repopulate selectedPhotos array using randomlySelectPhoto()
            // "inAlbum" flag will be added to each photo by same method
            selectedPhotos = randomlySelectPhotos(photos: photos)
            
            // getNewCollection Step 4: Move collection view back to the top
            photoCollectionView.setContentOffset(CGPoint(x: 0.0, y: 0.0), animated: false)
            
            // getNewCollection Step 5: reload Data
            photoCollectionView.reloadData()
            
            
        }
        else {
            // Delete Selected Photos Step 4: (Step 3 in collectionView(:didSelectAt:)) When user taps "Delete Selected Photos", 
            // update selectedPhotos to filter out all photos in photoToBeDeleted array
            selectedPhotos = selectedPhotos.filter{!photosToBeDeleted.contains($0)}
            
            // MARK: Test Code
            let photosFetchRequestBeforeDeletion = NSFetchRequest<Photo>(entityName: "Photo")
            photosFetchRequestBeforeDeletion.predicate = NSPredicate(format: "%K = %@", #keyPath(Photo.pins), self.selectedPin)
            print("Photos in context:\(try! managedContext.count(for: photosFetchRequestBeforeDeletion))")
            // End Test Code
            
            
            // Delete Selected Photos Step 5: Delete photos in photos array and delete from context
            photos = photos.filter{!photosToBeDeleted.contains($0)}
            selectedPin.removeFromPhotos(Set(photosToBeDeleted) as NSSet)
            
            // MARK: Test Code
            let photosFetchRequestAfterDeletion = NSFetchRequest<Photo>(entityName: "Photo")
            photosFetchRequestAfterDeletion.predicate = NSPredicate(format: "%K = %@", #keyPath(Photo.pins), self.selectedPin)
            print("Photos in context:\(try! managedContext.count(for: photosFetchRequestAfterDeletion))")
            // End Test Code
            
            showAlert(message: "\(photosToBeDeleted.count) photos deleted from this album.")

            // Delete Selected Photos Step 6: Clear photosToBeDeleted array
            photosToBeDeleted = []
            
            // Delete Selected Photos Step 7: Change button title back to "Get New Photo Collection"
            getNewCollectionOrDeleteButton.setTitle("Get New Photo Collection", for: .normal)
            
            // Delete Selected Photos Step 8: Reload Photo Collection View
            photoCollectionView.reloadData()
            
        }
    }
    

    // MARK: Methods
    
    func showAlert(message: String) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default){
            _ in
            self.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func randomlySelectPhotos(photos: [Photo]) -> [Photo] {
        var albumPhotos:[Photo] = []
        
        // if there are less than 21 photos, just return photos as we will need to show all available photos
        if photos.count <= 21 {
            return photos
        }
            // else randomly select 21 photos using GKShuffledDistribution so we won't select the same image twice
        else {
            for _ in 1...21{
                let randomIndex = RandomImage.sharedInstance().chooseRandomNumber(maxValue: photos.count - 1)
                albumPhotos.append(photos[randomIndex])
                
                // Show Photos Step 6: Mark each selected photo as "inAlbum"
                photos[randomIndex].inAlbum = true
                
                
            }
        }
        
        return albumPhotos
    }
    
    func checkInAlbumFlag(photos: [Photo]) -> [Photo] {
        var albumPhotos:[Photo] = []
        
        for photo in photos{
            if photo.inAlbum{
                albumPhotos.append(photo)
            }
        }
        
        return albumPhotos
    }
    
    // This method loads the image from Core Data or from the URL if the image is not available
    func loadImageOrURL(indexPath: IndexPath, cell: PhotoViewCell){
        
        // Clear out the image in the de-queued cell
        cell.photoImageView.image = nil
        
        if selectedPhotos[indexPath.row].image == nil {
            cell.loadingIndicator.sizeToFit()
            cell.loadingIndicator.startAnimating()
            
            DispatchQueue.global(qos: .userInitiated).async {
                
                guard let imageData = FlickrClient.sharedInstance().getImageDataFromFlickr(urlString: self.selectedPhotos[indexPath.row].url!) else {
                        print("Unable to process url into photo object")
                        return
                }
 
                // Loop through photos array to find matching photo object in selectedPhotos array
                // Save the image to photos array which will eventually be saved to Core Data
                // TODO: Look into using predicates to filter out photo that have matching index instead of looping through
                for photo in self.photos{
                    if photo.index == self.selectedPhotos[indexPath.row].index{
                        photo.image = imageData as NSData
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                // Run this after waiting 1/10 of a second
                // Check if photo view is still active
                // Call itself if it is to display downloaded images
                if self.viewActive{
                    self.loadImageOrURL(indexPath: indexPath, cell: cell)
                } else {
                    print("View is not active")
                }
            })
    
        }
        else {
            let photo = UIImage(data: selectedPhotos[indexPath.row].image as! Data)
            cell.loadingIndicator.stopAnimating()
            cell.photoImageView.image = photo
        }
    
    }
    
    // MARK: UICollectionViewDataSource
    
    override func viewDidLayoutSubviews() {
        print("%%in viewDidLayoutSubviews()")
        super.viewDidLayoutSubviews()
        
        // Layout the collection view so that cells take up 1/3 of the width,
        // with no space in-between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let width = floor(self.photoCollectionView.frame.size.width/3)
        layout.itemSize = CGSize(width: width, height: width)
        photoCollectionView.collectionViewLayout = layout
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return selectedPhotos.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoViewCell
        
        loadImageOrURL(indexPath: indexPath, cell: cell)
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        print("%% in collectionView(:didSelectItemAt)")
        
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoViewCell
        
        
        // If user taps on the same cell, remove it from photosToBeDeleted array
        // and replace the image with alpha value 0.5 with original
        if photosToBeDeleted.contains(selectedPhotos[indexPath.row]){
            let tempArray = [selectedPhotos[indexPath.row]]
            photosToBeDeleted = photosToBeDeleted.filter{!tempArray.contains($0)}
            let imageData = selectedPhotos[indexPath.row].image as! Data
            cell.photoImageView.image = UIImage(data: imageData)
            
            // If photosToBeDelete is empty after removing the photo in this cell,
            // change title back to "Get New Photo Collection"
            if photosToBeDeleted.isEmpty{
                getNewCollectionOrDeleteButton.setTitle("Get New Photo Collection", for: .normal)
            }
        }
            
        else {
            // Delete Selected Photos Step 1: User taps image, the bottom button title changes from
            // "Get New Photo Collection" to "Delete Selected Photos"
            getNewCollectionOrDeleteButton.setTitle("Delete Selected Photos", for: .normal)
            
            // Delete Selected Photos Step 2: Change selected photo's alpha value to 0.5 to show the photo was selected
            cell.photoImageView.image = cell.photoImageView.image?.alpha(value: 0.5)
            
            // Delete Selected Photos Step 3: Store selected photo object in photosToBeDeleted array
            // Step 4 in getNewCollectionOrDelete method
            photosToBeDeleted.append(selectedPhotos[indexPath.row])
            
            // MARK: Test Code
            print("selected index: \(indexPath.row)")
            // End test code
            
        }
        
    }
    
    
}

extension UIImage{
    
    
    // Change alpha value of an image
    // Code from here: http://stackoverflow.com/questions/28517866/how-to-set-the-alpha-of-a-uiimage-in-swift-programmatically
    func alpha(value:CGFloat)->UIImage
    {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
        
    }
}
