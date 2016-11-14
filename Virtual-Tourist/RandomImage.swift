//
//  RandomImage.swift
//  Virtual-Tourist
//
//  Created by Jack Ngai on 10/31/16.
//  Copyright © 2016 Jack Ngai. All rights reserved.
//

import Foundation
import GameplayKit

class RandomImage:NSObject {
    
    func chooseRandomNumber(maxValue: Int) -> Int{
        return GKShuffledDistribution(lowestValue: 0, highestValue: maxValue).nextInt()
    }
    
    
    //let randomNumber = GKShuffledDistribution(lowestValue: 0, highestValue: 100)
    
    class func sharedInstance() -> RandomImage{
        struct Singleton{
            static var sharedInstance = RandomImage()
        }
        return Singleton.sharedInstance
    }
    
}
