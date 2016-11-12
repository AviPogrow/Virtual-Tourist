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

class PhotoViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    // MARK: Outlets
    @IBOutlet weak var miniMap: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    // MARK: Properties
    var selectedPin:Pin!
    var photos: [Photo] = []
    
    // TODO: Experimental - trying to use fetch request instead of copying the set from selectedPin!.photos! (and converting it to an array)
    var fetchRequest: NSFetchRequest<Photo>!
    var asyncFetchRequest: NSAsynchronousFetchRequest<Photo>!
    
    // MARK: View Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        let regionRadius: CLLocationDistance = 1000
        let region = MKCoordinateRegionMakeWithDistance(selectedPin.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        miniMap.setRegion(region, animated: true)
        
        loadPhotosURL()
        
        photoCollectionView.dataSource = self
        photoCollectionView.delegate = self
    }
    
    // MARK: Methods
    
    // load photos from Core Data or Flickr
    func loadPhotosURL() {
        
        // Use selected pin to look up if there are photos saved for that pin
        // If not, get it from Flickr
        if selectedPin.photos?.count == 0 {
            
            // Populate photos
            FlickrClient.sharedInstance().getPhotosURLFromFlickr(pin: selectedPin, managed: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext)
            
             // Populate collection view with photos from Core Data by converting the set into an array
            photos = Array(selectedPin!.photos!) as! [Photo]
        } else {
            // Populate collection view with photos from Core Data by converting the set into an array
            photos = Array(selectedPin!.photos!) as! [Photo]
            
        }
        
    }

    
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoViewCell
    
        
        // This method checks if the image at the specified indexPath has been populated
        // If not, populate the cell with a blank image, 
        // then use session.dataTask to get the image from Flickr and save it to Core Data
        func checkImage(){
            
            if photos[indexPath.row].image == nil {
                
                
                cell.photoImageView.image = UIImage(named: "Blank")
                cell.loadingIndicator.sizeToFit()
                cell.loadingIndicator.startAnimating()
                let url = URL(string: photos[indexPath.row].url!)!
                FlickrClient.sharedInstance().session.dataTask(with: url, completionHandler: { (data, response, error) in
                    guard error == nil else {
                        print("Received error at trying to download image using Photo.url. Error: \(error)")
                        return
                    }
                    
                    guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                        print("Status code: \((response as? HTTPURLResponse)?.statusCode))")
                        return
                    }
                    
                    guard let data = data else {
                        print("data field is nil when downloading image using Photo.url")
                        return
                    }
                    
                    self.photos[indexPath.row].image = data as NSData
                    cell.photoImageView.image = UIImage(data: data)
                    print("saved image to photoData")
                    
                    // TODO: Will this save the photo to Core Data or will I need to setup the context, setup the object, save the object to context...
                    (UIApplication.shared.delegate as! AppDelegate).saveContext()
                    
                    // Call itself to check if the image has loaded into photos array
                    checkImage()
                })
            }
            else {
                let photo = UIImage(data: photos[indexPath.row].image as! Data)
                cell.loadingIndicator.stopAnimating()
                cell.photoImageView.image = photo
            }
        }
        
        checkImage()
    

        
        return cell
        
    }
    
    
    
}
