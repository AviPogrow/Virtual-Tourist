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


// Create a class that subclasses UIViewController and follows the MKMapViewDelegate protocol
class MapViewController: UIViewController, MKMapViewDelegate {
    
    // Setup an outlet for mapView
    @IBOutlet weak var mapView: MKMapView!
    
    // Create a pins array of type Pin Object
    // Pin Object follows MKAnnotation protocol so they an be displayed on the map
    var pins: [Pin] = []
    
    // Get access to managed context
    let managedContext = CoreDataStack.sharedInstance().persistentContainer.viewContext
    
    // create a selectedPin variable to pass the selected pin coordinates to PhotoViewController
    var selectedPin:Pin!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Temporary, set default view to nyc area so we know there are pics
        /*
         let nycCoordinates = CLLocationCoordinate2D(latitude: 40.678, longitude: -73.944 )
         let regionRadius: CLLocationDistance = 10000
         let region = MKCoordinateRegionMakeWithDistance(nycCoordinates, regionRadius * 2.0, regionRadius * 2.0)
         mapView.setRegion(region, animated: true)
         */
        
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
            
            // Change the back button from "<Virtual Tourist" to "<Back"
            // Learned from: http://stackoverflow.com/questions/28471164/how-to-set-back-button-text-in-swift
            let backItem = UIBarButtonItem()
            backItem.title = "Back"
            navigationItem.backBarButtonItem = backItem
            
            // Setup the PhotoViewController, pass the coordinates from selectedPin
            let controller = segue.destination as! PhotoViewController
            controller.selectedPin = selectedPin
        }
        
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        // Fetch from Core Data a pin that matches the pin that the user selected based on coordinate
        // If pin found, set pin as selectedPin, otherwise create pin and save to Core Data
        
        // Create fetch request
        let pinFetch: NSFetchRequest<Pin> = Pin.fetchRequest()
        
        // Core Data stores a double that is rounded up slightly (ex: 40.640715152688358 stored as 40.64071515268836) so %K == %@
        // will fail every time. Using %K BETWEEN and setting a uppper/lower bound and retrieve results that are within bounds
        let precision = 0.000001
        let lowerBoundLatitude = (view.annotation?.coordinate.latitude)! - precision
        let upperBoundLatitude = (view.annotation?.coordinate.latitude)! + precision
        let lowerBoundLongitude = (view.annotation?.coordinate.longitude)! - precision
        let upperBoundLongitude = (view.annotation?.coordinate.longitude)! + precision
        
        pinFetch.predicate = NSPredicate(format: "(%K BETWEEN {\(lowerBoundLatitude), \(upperBoundLatitude) }) AND (%K BETWEEN {\(lowerBoundLongitude), \(upperBoundLongitude) })", #keyPath(Pin.latitude), #keyPath(Pin.longitude))
        
        // Run fetch
        do {
            let results = try managedContext.fetch(pinFetch)
            if results.count > 0 {
                // Found pin, set found pin to selectedPin
                selectedPin = results.first
            } else {
                // Pin not found in Core Data, create a new pin and saved the coordinates that user selected into new pin
                let pin = Pin(context: managedContext)
                pin.latitude = (view.annotation?.coordinate.latitude)!
                pin.longitude = (view.annotation?.coordinate.longitude)!
                selectedPin = pin
                try managedContext.save()
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

            let pin = Pin(context: managedContext)
            pin.latitude = annotation.coordinate.latitude
            pin.longitude = annotation.coordinate.longitude
            
            // Start getting photos from Flickr
            FlickrClient.sharedInstance().getPhotosURLFromFlickr(pin: pin, managed: managedContext)
            
            do {
            try managedContext.save()
            }
            catch let error as NSError {
                print("Unable to save \(error), \(error.userInfo)")
            }
            

        }
    }
    
    func getData() {

        do{
            pins = try managedContext.fetch(Pin.fetchRequest())
            
        } catch {
            print("Unable to fetch data")
        }
        
    }


}



