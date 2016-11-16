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
    
    /*
     // old code
    var lowIndex = 1
    var highIndex = 21
    var photosCount = 0

    // Declare a fetch results controller
    var fetchResultsController: NSFetchedResultsController<Photo>!
 
    */
    

    // MARK: View Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        let regionRadius: CLLocationDistance = 1000
        let region = MKCoordinateRegionMakeWithDistance(selectedPin.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        miniMap.setRegion(region, animated: true)
        
        // Step 3: Place all photos in selectedPin to a photos array
        photos = Array(selectedPin!.photos!) as! [Photo]
    
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
        
        print("test")
        
        photoCollectionView.dataSource = self
        photoCollectionView.delegate = self
        
        /* old code
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        photosCount = try! managedContext.count(for: fetchRequest)
        print("Total photos count: \(photosCount)")
        
        // Set highIndex to count in case the # of photos available is lower than highIndex
        // TODO: Is this necessary? If it is out side of bounds, it will return 0 hits,
        highIndex = highIndex > photosCount ? photosCount : highIndex
        
        
        // Look for photos that match a specific pin by using inverse relationship
        //fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(Photo.pins), self.selectedPin)
        
        fetchRequest.predicate = NSPredicate(format: "(%K == %@) AND (%K BETWEEN {\(lowIndex), \(highIndex)})", #keyPath(Photo.pins), self.selectedPin, #keyPath(Photo.index))
        print("Total retrieve with NSPredicate: \(try! managedContext.count(for: fetchRequest))")
        
        //fetchRequest.predicate = NSPredicate(format: "%K BETWEEN {\(lowIndex), \(highIndex)}", #keyPath(Photo.index))
        
        // %K >= %@, #keyPath(Photo.index),
        
        
        //         pinFetch.predicate = NSPredicate(format: "(%K BETWEEN {\(lowerBoundLatitude), \(upperBoundLatitude) }) AND (%K BETWEEN {\(lowerBoundLongitude), \(upperBoundLongitude) })", #keyPath(Pin.latitude), #keyPath(Pin.longitude))
        
        // TODO: Need to add sort descriptor to NSFetchResultsController or it will crash with:
        // An instance of NSFetchedResultsController requires a fetch request with sort descriptors
        let sort = NSSortDescriptor(key: #keyPath(Photo.url), ascending: true)
        
        fetchRequest.sortDescriptors = [sort]
        
        // Should this be lazy var instead of let?
        fetchResultsController = NSFetchedResultsController<Photo>(fetchRequest: fetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: nil, cacheName: nil)
        //let frc = NSFetchedResultsController<Photo>(fetchRequest: fetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        //fetchResultsController = frc
        
        
        loadPhotosURL()
        

        
        
        // Fetch the data
        do {
            try fetchResultsController.performFetch()
        } catch let error as NSError {
            print("Unable to fetch \(error), \(error.userInfo)")
        }
        
        fetchResultsController.delegate = self
 
        */
        
        
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
                let randomIndex = RandomImage.sharedInstance().chooseRandomNumber(maxValue: photos.count)
                albumPhotos.append(photos[randomIndex])
                
                // Step 6: Mark each selected photo as "inAlbum"
                photos[randomIndex].inAlbum = true
                
                
            }
        }
        
        // TODO: Marked selected photos as "inAlbum", save to Core Data
        
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
    @IBAction func reloadPhotos(_ sender: UIBarButtonItem) {
        
        /*
         
         // old code
        
        //FlickrClient.sharedInstance().getPhotosURLFromFlickr(pin: selectedPin, managed: managedContext)
        
        // No need to remove images if we are going to the next batch up
        /*
        for photo in photos{
            photo.image = nil
        }
        */
        
        
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let sort = NSSortDescriptor(key: #keyPath(Photo.url), ascending: true)
        fetchRequest.sortDescriptors = [sort]
        
        if highIndex < photosCount - 20 {
            lowIndex = highIndex
            highIndex = highIndex + 20
        } else {
            lowIndex = highIndex
            highIndex = photosCount
        }
        
        fetchRequest.predicate = NSPredicate(format: "(%K == %@) AND (%K BETWEEN {\(lowIndex), \(highIndex)})", #keyPath(Photo.pins), self.selectedPin, #keyPath(Photo.index))
        print("Total retrieve with NSPredicate: \(try! managedContext.count(for: fetchRequest))")
        // Fetch the data
        do {
            try fetchResultsController.performFetch()
        } catch let error as NSError {
            print("Unable to fetch \(error), \(error.userInfo)")
        }

        
        photoCollectionView.reloadData()
        
        */
    }
    
    
    // MARK: Methods
    
    // FetchURLs from CoreData
    
    
    
    // This method checks if the image at the specified indexPath has been populated
    // If not, use try? Data(contentsOf:) to get the image
    
    // This method loads the image from Core Data or from the URL if the image is not available
    
    func loadImageOrURL(indexPath: IndexPath, cell: PhotoViewCell){
        
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
                
                // TODO: Need to save image to photos array so it will be stored in Core Data
                
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
        
        
        
        
        
        /*
        
        //old code
        
        print("%%in CheckImage, index \(indexPath.row)")
        
        // TODO: Need to prevent it from crashing if no images
        
        // Clear out the image in the dequeued cell so user will know
        // a new image is being loaded
        cell.photoImageView.image = nil
        
        if photos[indexPath.row].image == nil {
            
            
            //cell.photoImageView.image = UIImage(named: "Blank")
            cell.loadingIndicator.sizeToFit()
            cell.loadingIndicator.startAnimating()
            
            DispatchQueue.global(qos: .userInitiated).async {
                
                //use fetch results controller
                let photoObject = self.fetchResultsController.object(at: indexPath)
                
                guard let url = URL(string: photoObject.url!),
                    let imageData = try? Data(contentsOf: url) else {
                    print("unable to process url in photo object obtained from fetch results controller")
                    return
                }
                
                
                /* //using photos array
                guard let url = URL(string: self.photos[indexPath.row].url!),
                    let imageData = try? Data(contentsOf: url) else {
                        print("Unable to process URL")
                        return
                }
                */
                self.photos[indexPath.row].image = imageData as NSData
 
                
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                self.checkImage(indexPath: indexPath, cell: cell)
            })
            
        }
        else {
            let photo = UIImage(data: photos[indexPath.row].image as! Data)
            cell.loadingIndicator.stopAnimating()
            cell.photoImageView.image = photo
        }
 
        */
    }
    
    // load photos from Core Data or Flickr
    func loadPhotosURL() {
        
        /*
        
        // old code

        // Use selected pin to look up if there are photos saved for that pin
        // If not, get it from Flickr
        if selectedPin.photos?.count == 0 {
            
            // Populate photos
            FlickrClient.sharedInstance().getPhotosURLFromFlickr(pin: selectedPin, managed: managedContext)
            
                    // TODO: Switch this from converting from Set to Array to getting data from fetchresultscontroller
             // Populate collection view with photos from Core Data by converting the set into an array
            photos = Array(selectedPin!.photos!) as! [Photo]
        } else {
            // Populate collection view with photos from Core Data by converting the set into an array
            photos = Array(selectedPin!.photos!) as! [Photo]
            
        }
 
        */
        
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
        
        /*
         
         // old code
        print("%% in numberOfSections (in collectionView) sections: \(fetchResultsController.sections?.count)")
        
        return fetchResultsController.sections?.count ?? 0
 
        */
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        /*
        
        // old code
        let sectionInfo = self.fetchResultsController.sections![section]
        
                print("%%in collectionView(_:numberOfItemsInSection) objects: \(sectionInfo.numberOfObjects), name: \(sectionInfo.name)")
        //po sectionInfo.objects
        return sectionInfo.numberOfObjects
        //return photos.count
 
        */
        
        return selectedPhotos.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoViewCell
        
        loadImageOrURL(indexPath: indexPath, cell: cell)
        
        return cell
        
        
        
        /*
         
         // old code
        print("%% in collectionView CellForItemAt IndexPath: IndexPath.row: \(indexPath.row)")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoViewCell
    
        checkImage(indexPath: indexPath, cell: cell)
        
        return cell
 
        */
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // TODO: Delete item
    }
    
    
}
