//
//  Helper.swift
//  PlanetTSViewer
//
//  Created by Felix on 14/06/15.
//  Copyright (c) 2015 wz. All rights reserved.
//

import UIKit

extension UIImage {
    func resize(targetSize: CGSize, pixelated: Bool) -> UIImage {
        let size = self.size
        
        let widthRatio  = targetSize.width  / self.size.width
        let heightRatio = targetSize.height / self.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSizeMake(size.width * heightRatio, size.height * heightRatio)
        } else {
            newSize = CGSizeMake(size.width * widthRatio,  size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRectMake(0, 0, newSize.width, newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        if pixelated {
            let context = UIGraphicsGetCurrentContext()
            CGContextSetInterpolationQuality(context, kCGInterpolationNone)
        }
        self.drawInRect(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
