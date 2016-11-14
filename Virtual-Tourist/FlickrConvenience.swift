//
//  FlickrConvenience.swift
//  Virtual-Tourist
//
//  Created by Jack Ngai on 11/9/16.
//  Copyright © 2016 Jack Ngai. All rights reserved.
//

import UIKit
import CoreData

extension FlickrClient {
    
    
    
    
    
    /*
     // Fill photos array with blank boxes with loading indicator enabled
     func fillPhotosArray(managed context: NSManagedObjectContext)->[Photo] {
     var photos:[Photo] = []
     for _ in 0...19{
     let image = UIImage(named: "Blank")!
     let imageData: NSData = UIImagePNGRepresentation(image)! as NSData
     let photo = Photo(context: context)
     photo.image = imageData
     photos.append(photo)
     }
     
     return photos
     }
     */
    
    
 
    // Get photos from Flickr and save to Core Data
    func getPhotosURLFromFlickr(pin selectedPin: Pin, managed context: NSManagedObjectContext) {
        
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
            
            // TODO: Remove when testing is done 
            //Confirmed Flickr portion works fine via this print statement
            //print(data)
            
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
            
            // TODO: Add code to switch to a random page if there's more than one page
            // TODO: Change this so it randomly picks 20 images if there's more than 20 images
            // TODO: Save the image URL to Core Data
            
            // Save first 20 images to Core Data
            for index in 0...19{
                // Use random number to pick a photo
                let photoDictionary = photosArray[index] as [String:AnyObject]
                
                guard let imageURLString = photoDictionary[FlickrConstants.ResponseKeys.MediumURL] as? String else {
                    print("Unable to locate image URL in photo dictionary")
                    return
                }
                
                // Create a photo object using provided context in method parameter
                let photo = Photo(context: context)
                
                // Save url to photo object
                photo.url = imageURLString
                
                // Save to photos array used by UICollectionView
                self.photos.append(photo)
                
                // Save photo to Selected Pin
                selectedPin.addToPhotos(photo)
                
                // Save photo object to Core Data
                do {
                    try context.save()
                } catch let error as NSError {
                    print("Unable to save \(error), \(error.userInfo)")
                }
                
                /*
                
                // TODO: Stop here. Break this up so you use NSURL (is it URL now?)'s dataTaskWithURL to get the 
                // associated image within the collection view delegate method cellForItemAt 
                // TODO: Image retrieval needs to happen on a background thread
                // Decode the image URL to image
                
                
                //self.session.dataTask(with: <#T##URL#>, completionHandler: <#T##(Data?, URLResponse?, Error?) -> Void#>)
                
                DispatchQueue.global(qos: .background).async {
                    guard let imageURL = URL(string: imageURLString),
                        let imageData = try? Data(contentsOf: imageURL) else {
                            print("Unable to process URL from photo dictionary into image.")
                            return
                    }
                    

                    
                    // Place image data into photo object (stored as binary data)
                    photo.image = imageData as NSData
                    
                 
                    

                    

                    
                }
                */

            }
            
        })
    }
    
    
}
