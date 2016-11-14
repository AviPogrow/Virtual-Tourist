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
    var selectedPin:Pin!
    var photos: [Photo] = []
    
    var managedContext = CoreDataStack.sharedInstance().persistentContainer.viewContext
    
    // Declare a fetch results controller
    var fetchResultsController: NSFetchedResultsController<Photo>!
    

    
    
    // MARK: View Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        let regionRadius: CLLocationDistance = 1000
        let region = MKCoordinateRegionMakeWithDistance(selectedPin.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        miniMap.setRegion(region, animated: true)
        
        
        
        
        // TODO: Experimental - trying to use fetch request instead of copying the set from selectedPin!.photos! (and converting it to an array)
        var fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        var asyncFetchRequest: NSAsynchronousFetchRequest<Photo>!
        
        
        // TODO: Not sure if this is correct. Trying to look for pins by using inverse relationship
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(Photo.pins), self.selectedPin)
        
        // TODO: Need to add sort descriptor to NSFetchResultsController or it will crash with:
        // An instance of NSFetchedResultsController requires a fetch request with sort descriptors
        let sort = NSSortDescriptor(key: #keyPath(Photo.url), ascending: true)
        
        fetchRequest.sortDescriptors = [sort]
        
        // Should this be lazy var instead of let?
        fetchResultsController = NSFetchedResultsController<Photo>(fetchRequest: fetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: nil, cacheName: nil)
        //let frc = NSFetchedResultsController<Photo>(fetchRequest: fetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        //fetchResultsController = frc
        
        
        loadPhotosURL()
        
        photoCollectionView.dataSource = self
        photoCollectionView.delegate = self
        
        
        // Fetch the data
        do {
            try fetchResultsController.performFetch()
        } catch let error as NSError {
            print("Unable to fetch \(error), \(error.userInfo)")
        }
        
        fetchResultsController.delegate = self
        
        
    }
    
    // MARK: Actions
    @IBAction func reloadPhotos(_ sender: UIBarButtonItem) {
        photoCollectionView.reloadData()
    }
    
    
    // MARK: Methods
    
    // This method checks if the image at the specified indexPath has been populated
    // If not, populate the cell with a blank image,
    // then use session.dataTask to get the image from Flickr and save it to Core Data
    func checkImage(index: Int, cell: PhotoViewCell){
        print("in CheckImage")
        
        if photos[index].image == nil {
            
            
            //cell.photoImageView.image = UIImage(named: "Blank")
            cell.loadingIndicator.sizeToFit()
            cell.loadingIndicator.startAnimating()
            
            DispatchQueue.global(qos: .userInitiated).async {
                guard let url = URL(string: self.photos[index].url!),
                    let imageData = try? Data(contentsOf: url) else {
                        print("Unable to process URL")
                        return
                }
                
                self.photos[index].image = imageData as NSData
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                self.checkImage(index: index, cell: cell)
            })
            
        }
        else {
            let photo = UIImage(data: photos[index].image as! Data)
            cell.loadingIndicator.stopAnimating()
            cell.photoImageView.image = photo
        }
    }
    
    // load photos from Core Data or Flickr
    func loadPhotosURL() {
        
        // Use selected pin to look up if there are photos saved for that pin
        // If not, get it from Flickr
        if selectedPin.photos?.count == 0 {
            
            // Populate photos
            FlickrClient.sharedInstance().getPhotosURLFromFlickr(pin: selectedPin, managed: managedContext)
            
             // Populate collection view with photos from Core Data by converting the set into an array
            photos = Array(selectedPin!.photos!) as! [Photo]
        } else {
            // Populate collection view with photos from Core Data by converting the set into an array
            photos = Array(selectedPin!.photos!) as! [Photo]
            
        }
        
    }

    
    
    // MARK: UICollectionViewDataSource
    
    override func viewDidLayoutSubviews() {
        print("in viewDidLayoutSubviews()")
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
        return fetchResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("in collectionView(_:numberOfItemsInSection")
        let sectionInfo = self.fetchResultsController.sections![section]
        
        return sectionInfo.numberOfObjects
        //return photos.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoViewCell
    
    
        checkImage(index: indexPath.row, cell: cell)
    

        
        return cell
        
    }
    
    
    
}
