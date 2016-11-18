//
//  Pin+CoreDataClass.swift
//  Virtual-Tourist
//
//  Created by Jack Ngai on 10/29/16.
//  Copyright © 2016 Jack Ngai. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData
import MapKit

@objc(Pin)
// Learned how to persist pins from here: http://juliusdanek.de/blog/coding/2015/07/14/persistent-pins-tutorial/
public class Pin: NSManagedObject, MKAnnotation {

    public var coordinate: CLLocationCoordinate2D {
        
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        set(coordinate){
            self.coordinate = coordinate
        }
    }
    
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    init(annotationLatitude: Double, annotationLongitude: Double, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context)!
        
        super.init(entity: entity, insertInto: context)
        
        latitude = annotationLatitude
        longitude = annotationLongitude
    }
}
