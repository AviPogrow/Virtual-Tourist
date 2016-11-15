//
//  To Do.swift
//  Virtual-Tourist
//
//  Created by Jack Ngai on 11/9/16.
//  Copyright © 2016 Jack Ngai. All rights reserved.
//

/*
 

 
- (Done) Images display as they are downloaded. They are shown with placeholders in a collection view while they download, and displayed as soon as possible.
 
        Solution: Use UIImage instead of session.dataTask (which I probably didn't call start task, and why it wasn't working) in a background queue and used 
 
- (Done) When photos are loading from Flickr, the tap gesture doesn't seem to work. How to fix it?
 
        Solution: move the image download process to a background queue
 
- Change the photo download process to this:
        * - (Done) Download all photo URLs instead of randomly downloading 20
        * - (Done) Add an index to each photo object
        * - Use NSPredicate in PhotoViewController to only return 20 objects, based on index, so it will return 1 - 20, 21 - 40, 41 - 60...
 
        * Question: How to save the Photos view so viewDidLoad doesn't mess it up every time it is called?
            Currently we are retrieving photos from Core Data every time viewDidLoad is called, so photo albums changes every time view is called
 
- When there's no images at a particular location from Flickr, alert user instead of crashing out with "fatal error: Index out of range" in the console




- When a Photo Album View is opened for a pin that does not yet have any photos, it initiates a download from Flickr.?
 
- Once all images have been downloaded, the user can remove photos from the album by tapping the image in the collection view. Tapping the image removes it from the photo album, the booth in the collection view, and Core Data.
 
- The Photo Album view has a button that initiates the download of a new album, replacing the images in the photo album with a new set from Flickr.
 
 
 
 
 
 
 
 
 
 
 */
