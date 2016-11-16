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
    
    // MARK: Properties
    
    // Step 1 & 2: Tap a pin, send pin to PhotoViewController (this is done through prepare for segue in MapViewController).
    var selectedPin:Pin!
    
    var photos: [Photo] = []
    
    var selectedPhotos: [Photo] = []
 
    var managedContext = CoreDataStack.sharedInstance().persistentContainer.viewContext
    

    // MARK: View Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        let regionRadius: CLLocationDistance = 1000
        let region = MKCoordinateRegionMakeWithDistance(selectedPin.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        miniMap.setRegion(region, animated: true)
        miniMap.addAnnotation(selectedPin)
        
        // Step 3: Place all photos in selectedPin to a photos array
        photos = Array(selectedPin!.photos!) as! [Photo]
        
        // TODO: Test Code
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
        // End Test Code
        
    
        // Step 4: Check each photo see if they are "inAlbum", add them to selectedPhotos array
        selectedPhotos = checkInAlbumFlag(photos: photos)
        
        // Step 5: if no photos were marked "inAlbum", randomly select 21 photos
        if selectedPhotos.isEmpty {
            selectedPhotos = randomlySelectPhotos(photos: photos)
        }
        
        // Step 7a: Save photos to managedContext
        selectedPin.photos = Set(photos) as NSSet
        
        // Step 7b: Save to Core Data
        CoreDataStack.sharedInstance().saveContext()
        
        photoCollectionView.dataSource = self
        photoCollectionView.delegate = self
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Save to Core Data
        selectedPin.photos = Set(photos) as NSSet
        CoreDataStack.sharedInstance().saveContext()
        
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
                
                // Step 6: Mark each selected photo as "inAlbum"
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
    
    // MARK: Actions
    @IBAction func getNewCollection(_ sender: UIBarButtonItem) {
        
        // getNewCollection Step 1: Remove all "inAlbum" flags in photos array
        for photo in photos{
            photo.inAlbum = false
        }
        
        // getNewCollection Step 2: Empty selectedPhotos array
        selectedPhotos = []
        
        // getNewCollection Step 3: repopulate selectedPhotos array using randomlySelectPhoto()
        // "inAlbum" flag will be added to each photo by same method
        selectedPhotos = randomlySelectPhotos(photos: photos)
        
        // getNewCollection Step 5: reload Data
        photoCollectionView.reloadData()

    }
    
    
    // MARK: Methods
    
    // This method loads the image from Core Data or from the URL if the image is not available
    
    func loadImageOrURL(indexPath: IndexPath, cell: PhotoViewCell){
        
        cell.photoImageView.image = nil
        
        if selectedPhotos[indexPath.row].image == nil {
            cell.loadingIndicator.sizeToFit()
            cell.loadingIndicator.startAnimating()
            
            DispatchQueue.global(qos: .userInitiated).async {
                guard let url = URL(string: self.selectedPhotos[indexPath.row].url!),
                    let imageData = try? Data(contentsOf: url) else {
                        print("Unable to process url into photo object")
                        return
                }
                self.selectedPhotos[indexPath.row].image = imageData as NSData
                
                // Loop through photos array to find matching downloaded photo
                // Save it to photos array which will save it to Core Data
                for photo in self.photos{
                    if photo.index == self.selectedPhotos[indexPath.row].index{
                        photo.image = imageData as NSData
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                self.loadImageOrURL(indexPath: indexPath, cell: cell)
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
        
        
        
        
        
        
        
        // TODO: Delete item
        
        
        
    }
    
    
}
