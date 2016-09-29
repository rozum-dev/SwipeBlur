    //
//  OCLHoroDayViewController.swift
//  Oculus
//
//  Created by Dmytro Rozumeyenko on 1/11/16.
//  Copyright © 2016 Appload. All rights reserved.
//

import UIKit
    
let kNumberOfStages = 50

protocol ViewController_Blur {}

extension ViewController: ViewController_Blur {
    
    func initBlurredImages() {
        let stamp = NSDate()
        
        blurredImages.append(self.bannerItemImage)
        
        for i in 1...kNumberOfStages {
            let radius = CGFloat(i) + 1
            let blurredImage =  UIImage(byApplyingBlurToImage:self.bannerItemImageResidedForBlur, withRadius:radius, tintColor:nil, saturationDeltaFactor:1.0, maskImage:nil)
            
            blurredImages.append(blurredImage)
            
            if i == kNumberOfStages {
                blurredImages.append(blurredImage)
            }
        }
        
        print("generation of stages took \(-stamp.timeIntervalSinceNow) seconds")
    }

    func blurBannerImage(yOffset: CGFloat) {
        
        guard self.blurredImages.count > 0 else {
            return
        }
        
        let alpha: CGFloat = yOffset < 0 ? 1 : max (0, 1 - yOffset/(CGRectGetHeight(self.bannerItemView.frame)))
        self.bannerItemView.alpha = alpha
        
        if yOffset <= 0 {
            self.bannerItemImageView.image = bannerItemImage
        }
        
        if self.shouldBlurBannerImage {
            let r = Double(yOffset / bannerItemView.bounds.size.height)
            let blur = max(0, min(1, r)) * Double(kNumberOfStages)
            let blurIndex = Int(blur)
            let blurRemainder = blur - Double(blurIndex)
            
            self.bannerItemImageView.image = blurredImages[blurIndex]
            self.bannerItemImageViewSecond.image = blurredImages[blurIndex + 1]
            self.bannerItemImageViewSecond.alpha = CGFloat(blurRemainder)
        }
    }
    
}