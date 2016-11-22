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

    
    // Get image data from Flickr
    func getImageDataFromFlickr(urlString: String)->Data?{
        
        guard let url = URL(string: urlString),
            let imageData = try? Data(contentsOf: url) else {
                print("Unable to process url into photo object")
                return nil
        }
        return imageData
    
    }
 
    // Get photo urls from Flickr and save to Core Data
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
        let task = FlickrClient.sharedInstance().startTask(request: getRequest, completionHandlerForTask: { (data, error) in
            guard error == nil else {
                print("Received error getting images from Flickr")
                return
            }
            
            guard let data = data else {
                print("Unable to unwrap data")
                return
            }
            
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
            
            // MARK: Test Code
            print("Photos available for this pin: \(photosArray.count)")
            // End test code

            // Save each url into a photo object
            for index in 0...(photosArray.count-1){
                
                let photoDictionary = photosArray[index] as [String:AnyObject]
                
                guard let imageURLString = photoDictionary[FlickrConstants.ResponseKeys.MediumURL] as? String else {
                    print("Unable to locate image URL in photo dictionary")
                    return
                }
                
                // asynchronously run the following using the same thread as the context
                context.perform{
                    // Create a photo object using provided context in method parameter
                    let photo = Photo(context: context)
                    
                    // Save url to photo object
                    photo.url = imageURLString
                    
                    // Save index to photo object (for filtering later)
                    photo.index = index + 1
                    
                    // Set inAlbum variable to false
                    photo.inAlbum = false
                    
                    // Save photo to Selected Pin
                    selectedPin.addToPhotos(photo)
                }
                
            }
            
        })
        task.resume()
        
    }
    
    
}
