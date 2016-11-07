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
    
    
    @IBOutlet weak var miniMap: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    var selectedPin:Pin!
    //var coordinates:CLLocationCoordinate2D!
    
    var photos: [Photo] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let regionRadius: CLLocationDistance = 1000
        let region = MKCoordinateRegionMakeWithDistance(selectedPin.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        miniMap.setRegion(region, animated: true)
        
        // TODO: Load photos from Core Data into photos variable
        // In Dog Walk app, you load the dog from Core Data here
        // Maybe compare the load with selectedPin? 
        // Although I will need to compare both lat/long
        
        
        getPhotos()
        
        photoCollectionView.dataSource = self
        photoCollectionView.delegate = self
    }
    
    
    func getPhotos() {
        
        
        // Use selected pin to look up if there are photos saved for that pin
        // If not, get it from Flickr
        
        // TODO: Need a new way to identify if photos are stored in Core Data
        // selectedPin doesn't have any photos because it only has coordinates
        //
        
        if selectedPin.photos?.count == 0 {
            // Populate collection view with photos from Flickr
            // Save photos to Core Data
            
            // Setup the parameters
            let methodParameters: [String: String?] = [
                FlickrConstants.ParameterKeys.Method:FlickrConstants.ParameterValues.SearchMethod,
                FlickrConstants.ParameterKeys.APIKey:FlickrConstants.ParameterValues.APIKey,
                FlickrConstants.ParameterKeys.BoundingBox:FlickrClient.sharedInstance().bboxString(latitude: selectedPin.coordinate.latitude, longitude: selectedPin.coordinate.longitude),
                FlickrConstants.ParameterKeys.SafeSearch:FlickrConstants.ParameterValues.UseSafeSearch,
                FlickrConstants.ParameterKeys.Extras:FlickrConstants.ParameterValues.MediumURL,
                FlickrConstants.ParameterKeys.Format:FlickrConstants.ParameterValues.ResponseFormat,
                FlickrConstants.ParameterKeys.NoJSONCallback:FlickrConstants.ParameterValues.DisableJSONCallback
            ]
            
            // Setup the request using parameters
            let getRequest = FlickrClient.sharedInstance().get(parameters: methodParameters as [String : AnyObject])
            
            // Start the task
            _ = FlickrClient.sharedInstance().startTask(request: getRequest, completionHandlerForTask: { (data, error) in
                guard error == nil else {
                    print("Received error getting images from Flickr")
                    return
                }
                
                guard let data = data else {
                    print("Unable to unwrap data")
                    return
                }
                
                // Confirmed Flickr portion works fine via this print statement
                print(data)
                
                // Pull out the photos dictionary from data, pull out the photos array from the photos dictionary
                guard let photosDictionary = data[FlickrConstants.ResponseKeys.Photos] as? [String:AnyObject],
                    let photosArray = photosDictionary[FlickrConstants.ResponseKeys.Photo] as? [[String:AnyObject]]
                    else {
                        print("Unable to find \(FlickrConstants.ResponseKeys.Photos) and \(FlickrConstants.ResponseKeys.Photo) in \(data)")
                        return
                }
                
                guard photosArray.count > 0 else {
                    print("photo array from Flickr is empty.")
                    return
                }
                
                // Save first 20 images to Core Data
                for index in 0...19{
                    // Use random number to pick a photo
                    let photoDictionary = photosArray[index] as [String:AnyObject]
                    
                    guard let imageURLString = photoDictionary[FlickrConstants.ResponseKeys.MediumURL] as? String else {
                        print("Unable to locate image URL in photo dictionary")
                        return
                    }
                    
                    // Decode the image URL to image
                    guard let imageURL = URL(string: imageURLString),
                        let imageData = try? Data(contentsOf: imageURL) else {
                            print("Unable to process URL from photo dictionary into image.")
                            return
                    }
                    
                    
                    // Get access to managed context
                    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                    
                    // Create a photo object
                    let photo = Photo(context: context)
                    
                    // Place image data into photo object (stored as binary data)
                    photo.image = imageData as NSData
                    
                    // Save to Core Data
                    (UIApplication.shared.delegate as! AppDelegate).saveContext()
                    
                    // Save to photos array used by UICollectionView
                    self.photos.append(photo)
                    
                }
                
            })

        } else {
            // Populate collection view with photos from Core Data 
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath)
        cell.backgroundColor = .black
        return cell
        
    }
    
}
