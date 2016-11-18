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
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deletionWarningLabel: UILabel!
    
    
    // MARK: Properties
    // Create a pins array of type Pin Object
    // Pin Object follows MKAnnotation protocol so they an be displayed on the map
    var pins: [Pin] = []
    
    // Get access to managed context
    let managedContext = CoreDataStack.sharedInstance().persistentContainer.viewContext
    
    // create a selectedPin variable to pass the selected pin coordinates to PhotoViewController
    var selectedPin:Pin!
    
    // A flag to determine if tapping deletes a pin or brings you to the photo view for that pin
    var editMode = false
    
    // MARK: Lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        // Populate pins array with pins from Core Data
        getData()
        
        // Display pins from pins array on the map
        mapView.addAnnotations(pins)
        
        // Add gesture recognizer so 1 second long press will place a pin
        tapToAddAnnotation()
    }
    
    // MARK: IBActions
    @IBAction func tappedEditButton(_ sender: UIBarButtonItem) {
        
        // if editMode is true, you are currently in edit mode,
        // so tapping edit button again will turn off edit mode
        // by hiding the deletionWarningLabel, changing the edit
        // button label to "Edit", and set editMode flag to false
        
        
        // if user tapped "done" editing
        if editMode{
            deletionWarningLabel.isHidden = true
            sender.title = "Edit"
            editMode = false
            
            //Save to Core Data as user completed the process of deleting pins
            print("Calling save context from tappedEditButton(sender:)")
            CoreDataStack.sharedInstance().saveContext()
            
        }
        // if user tapped "edit" to begin deleting pins
        else {
            deletionWarningLabel.isHidden = false
            sender.title = "Done"
            editMode = true
        }
        
    }
    
    // MARK: Methods
    
    // Add gesture recognizer so 1 second long press will call addAnnotation function
    func tapToAddAnnotation(){
        let longPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation))
        longPress.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPress)
    }
    
    // Pass the selectedPin to PhotoViewController
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

    // Fetch from Core Data a pin that matches the pin that the user selected based on coordinate
    // If pin found, set pin as selectedPin, otherwise create pin and save to Core Data
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("%% in mapView(:didSelect view:)")
        
        
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
        
        
        if editMode{
            // Run fetch
            do {
                let results = try managedContext.fetch(pinFetch)
                if results.count > 0 {
                    
                    // Delete the annotation on the map
                    mapView.removeAnnotation(results.first!)
                    
                    // Delete the pin
                    managedContext.delete(results.first!) 

                } else {
                    print("Unable to locate pin to delete")
                }
            } catch let error as NSError {
                print("Unable to fetch \(error), \(error.userInfo)")
            }
            
        } else {
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
                }
            } catch let error as NSError {
                print("Unable to fetch \(error), \(error.userInfo)")
            }
            
            performSegue(withIdentifier: "toPhotoView", sender: self)
        }
        

    }
    
    // Convert touch point on screen to coordinates on the map
    // Start getting URLs of photos from Flickr
    func addAnnotation(gestureRecognizer: UIGestureRecognizer){
        print("Received Long press")
        if gestureRecognizer.state == UIGestureRecognizerState.began{
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinates
            mapView.addAnnotation(annotation)
            
            // Place coordindates in a pin object
            let pin = Pin(context: managedContext)
            pin.latitude = annotation.coordinate.latitude
            pin.longitude = annotation.coordinate.longitude
            
            // Start getting photos from Flickr
            FlickrClient.sharedInstance().getPhotosURLFromFlickr(pin: pin, managed: managedContext)
            
            
            //Save pin to Core Data
            do {
                try managedContext.save()
            }
            catch let error as NSError {
                print("Unable to save after creating new pin, \(error), \(error.userInfo)")
            }
            
            
        }
    }
    
    // Populate pins array with pins from Core Data
    func getData() {

        do{
            pins = try managedContext.fetch(Pin.fetchRequest())
            
        } catch {
            print("Unable to fetch data")
        }
        
    }


}



