//
//  MapViewController.swift
//  Virtual-Tourist
//
//  Created by Jack Ngai on 10/22/16.
//  Copyright © 2016 Jack Ngai. All rights reserved.
//

import UIKit
import MapKit
import CoreData


// Currently, I can save to Core Data (don't know what I'm doing)
// TODO: Setup Core Data so that I know what I'm doing
// TODO: Setup UICollection to display all the photos

// Create a class that subclasses UIViewController and follows the MKMapViewDelegate protocol
class MapViewController: UIViewController, MKMapViewDelegate {
    
    // Setup an outlet for mapView
    @IBOutlet weak var mapView: MKMapView!
    
    // Create a pins array of type Pin Object
    // Pin Object follows MKAnnotation protocol so they an be displayed on the map
    var pins: [Pin] = []
    
    // Get access to managed context
    let managedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // create a selectedPin variable to pass the selected pin coordinates to PhotoViewController
    var selectedPin:Pin!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Temporary, set default view to nyc area so we know there are pics
        let nycCoordinates = CLLocationCoordinate2D(latitude: 40.678, longitude: -73.944 )
        let regionRadius: CLLocationDistance = 10000
        let region = MKCoordinateRegionMakeWithDistance(nycCoordinates, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(region, animated: true)
        
        // Set delegate to self
        mapView.delegate = self
        
        // Populate pins array with pins from Core Data
        getData()
        
        // Display pins from pins array on the map
        mapView.addAnnotations(pins)
        
        // Add gesture recognizer so 1 second long press will call addAnnotation function
        tapToAddAnnotation()
    }
    
    
    func tapToAddAnnotation(){
        let longPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation))
        longPress.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPress)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Do this only if segue identifier is toPhotoView
        if segue.identifier == "toPhotoView"{
            
            // Setup the PhotoViewController, pass the coordinates from selectedPin
            let controller = segue.destination as! PhotoViewController
            controller.selectedPin = selectedPin
            
            

            /*
            
            let photoFetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
            
            let predicate = NSPredicate(format: "pin == %@", selectedPin as CVarArg)
            
            photoFetchRequest.predicate = predicate
            do{
                //FlickrClient.sharedInstance().photos = try context.fetch(Photo.fetchRequest())
                //FlickrClient.sharedInstance().photos = try context.fetch(photoFetchRequest)
                
            } catch {
                print("Did not find photos matching pin")
            }
            
            // Check if photos array is empty, retrieve from flickr
            // else use what's available in Core Data
            
            if FlickrClient.sharedInstance().photos.isEmpty{
                
                let methodParameters: [String: String?] = [
                    FlickrConstants.ParameterKeys.Method:FlickrConstants.ParameterValues.SearchMethod,
                    FlickrConstants.ParameterKeys.APIKey:FlickrConstants.ParameterValues.APIKey,
                    FlickrConstants.ParameterKeys.BoundingBox:bboxString(latitude: selectedPin.coordinate.latitude, longitude: selectedPin.coordinate.longitude),
                    FlickrConstants.ParameterKeys.SafeSearch:FlickrConstants.ParameterValues.UseSafeSearch,
                    FlickrConstants.ParameterKeys.Extras:FlickrConstants.ParameterValues.MediumURL,
                    FlickrConstants.ParameterKeys.Format:FlickrConstants.ParameterValues.ResponseFormat,
                    FlickrConstants.ParameterKeys.NoJSONCallback:FlickrConstants.ParameterValues.DisableJSONCallback
                ]
                let getRequest = FlickrClient.sharedInstance().get(parameters: methodParameters as [String : AnyObject])
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
                    
                    // Save Flickr images to Core Data
                    
                    // Pull out the photos dictionary from data, pull out the photos array from the photos dictionary
                    guard let photosDictionary = data[FlickrConstants.ResponseKeys.Photos] as? [String:AnyObject],
                        let photosArray = photosDictionary[FlickrConstants.ResponseKeys.Photo] as? [[String:AnyObject]]
                        else {
                            print("Unable to find \(FlickrConstants.ResponseKeys.Photos) and \(FlickrConstants.ResponseKeys.Photo) in \(data)")
                            return
                    }
                    
                    // TODO: Take this out, take the first 20 images and display it
                    // in the collection view and save it to Core Data
            
                    // Took this out: If photosArray is greater than 20, randomly select 20 images
                    // Immediate goal is to just save first 20 images
                    
                    // if photosArray.count > 20{
                        
                        for _ in 0...19{
                            // Use random number to pick a photo
                            let photoDictionary = photosArray[RandomImage.sharedInstance().randomNumber.nextInt()] as [String:AnyObject]
                            
                            guard let imageURLString = photoDictionary[FlickrConstants.ResponseKeys.MediumURL] as? String else {
                                print("Unable to locate image URL in photo dictionary")
                                return
                            }
                            
                            // Decode the image URL to image
                            guard let imageURL = URL(string: imageURLString),
                                let imageData = try? Data(contentsOf: imageURL),
                                let image = UIImage(data: imageData) else {
                                    print("Unable to process URL from photo dictionary into image.")
                                    return
                            }
                            
                            
                            // Save image to Core Data
                            
                            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                            let photo = Photo(context: context)
                            photo.image = imageData as NSData
                            (UIApplication.shared.delegate as! AppDelegate).saveContext()
                            
                            // print image to get rid of warning
                            print(image)
                        }
                        
                    /* } else {
                        // Save the first available to the last image found to Core Data
                        for imageNumber in 0...photosArray.count{
                            let photoDictionary = photosArray[imageNumber] as [String:AnyObject]
                            
                            guard let imageURLString = photoDictionary[FlickrConstants.ResponseKeys.MediumURL] as? String else {
                                print("Unable to locate image URL in photo dictionary")
                                return
                            }
                            
                            // Decode the image URL to image
                            guard let imageURL = URL(string: imageURLString),
                                let imageData = try? Data(contentsOf: imageURL),
                                let image = UIImage(data: imageData) else {
                                    print("Unable to process URL from photo dictionary into image.")
                                    return
                            }
                            
                            
                            // Save image to Core Data
                            
                            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                            let photo = Photo(context: context)
                            photo.image = imageData as NSData
                            (UIApplication.shared.delegate as! AppDelegate).saveContext()
                            
                            // print image to get rid of warning
                            print(image)
                             } */
                    //}
                    
                    
                    /*
                     if photosArray.isEmpty {
                     print("photosArray is empty")
                     self.displayImageFromFlickrBySearch(methodParameters, pageParameter: 1)
                     return
                     } */
                    
                    
                })
            } else {
                let photo = FlickrClient.sharedInstance().photos.first
                
                let imageData = photo?.image as? Data
                let image = UIImage(data: imageData!)
                print(image!)
                
                
                
            }
            
            */
        }
        
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        // Fetch from Core Data a pin that matches the pin that the user selected based on coordinate
        // If pin found, set pin as selectedPin, otherwise create pin and save to Core Data
        
        
        // Get Context
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        // Create fetch request
        let pinFetch: NSFetchRequest<Pin> = Pin.fetchRequest()
        
        // Create the predicate
        //pinFetch.predicate = NSPredicate(format: "%K == %@", #keyPath(Pin.coordinate), view.annotation?.coordinate as! CVarArg)
        
        // Core Data stores a double that is rounded up slightly (ex: 40.640715152688358 stored as 40.64071515268836) so %K == %@
        // will fail every time. 
    

        
        
        /*
        var coreDataLatitude = #keyPath(Pin.latitude)
        coreDataLatitude.characters.removeLast()
        */
        
        //pinFetch.predicate = NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: "%K == %@", (view.annotation?.coordinate.latitude)!,#keyPath(Pin.latitude)), NSPredicate(format: "%K == %@", (view.annotation?.coordinate.longitude)!, #keyPath(Pin.longitude))])
        
        pinFetch.predicate = NSPredicate(format: "%K == %@", #keyPath(Pin.latitude), (view.annotation?.coordinate.latitude)!)
        
        // Run fetch
        do {
            let results = try context.fetch(pinFetch)
            if results.count > 0 {
                // Found pin, set found pin to selectedPin
                selectedPin = results.first
            } else {
                // Pin not found in Core Data, create a new pin and saved the coordinates that user selected into new pin
                let pin = Pin(context: context)
                pin.latitude = (view.annotation?.coordinate.latitude)!
                pin.longitude = (view.annotation?.coordinate.longitude)!
                selectedPin = pin
                try context.save()
            }
        } catch let error as NSError {
            print("Unable to fetch \(error), \(error.userInfo)")
        }
    
        performSegue(withIdentifier: "toPhotoView", sender: self)
    }
    
    func addAnnotation(gestureRecognizer: UIGestureRecognizer){
        print("Received Long press")
        if gestureRecognizer.state == UIGestureRecognizerState.began{
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinates
            mapView.addAnnotation(annotation)
            
            //Save pin to Core Data
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            let pin = Pin(context: context)
            pin.latitude = annotation.coordinate.latitude
            pin.longitude = annotation.coordinate.longitude
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            
            // TODO: Start getting photos from Flickr?
            
        }
    }
    
    func getData() {

        do{
            pins = try managedContext.fetch(Pin.fetchRequest())
            
        } catch {
            print("Unable to fetch data")
        }
        
    }
    
    
    /*
    fileprivate func bboxString(latitude: Double, longitude: Double) -> String {
        let minLat = max(-90.00,latitude - FlickrConstants.SearchBBoxHalfWidth)
        let maxLat = min(90.00, latitude + FlickrConstants.SearchBBoxHalfWidth)
        let minLon = max(-180.00, longitude - FlickrConstants.SearchBBoxHalfHeight)
        let maxLon = min(180.00, longitude + FlickrConstants.SearchBBoxHalfHeight)
        
        return "\(minLon),\(minLat),\(maxLon),\(maxLat)"
    }
 */
    



}



