//
//  ViewController.swift
//  SwipeBlure
//
//  Created by Dmytro Rozumeyenko on 9/22/16.
//  Copyright © 2016 q. All rights reserved.
//

import UIKit

private let kLowerRatioResolution: CGFloat = 2.0

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var bannerItemImageView : UIImageView!
    @IBOutlet weak var bannerItemImageViewSecond : UIImageView!
    @IBOutlet weak var bannerItemView: UIView! {
        didSet {
            self.bannerItemImage = bannerItemImageView.image
        }
    }
    
    var bannerItemImageResidedForBlur : UIImage!
    var bannerItemImage : UIImage! {
        didSet {
            let height = bannerItemView.bounds.size.height / kLowerRatioResolution
            let width = height * bannerItemImage.size.width / bannerItemImage.size.height
            bannerItemImageResidedForBlur = bannerItemImage.scaleToSize(CGSizeMake(width,height))
        }
    }
        
    var blurredImages : [UIImage] = []
    var shouldBlurBannerImage = true
    var dispatchBlurToken: dispatch_once_t = dispatch_once_t.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dispatch_once(&self.dispatchBlurToken) {
            self.initBlurredImages()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.bannerItemView.addTranparencyMask()
    }
    
    func randomColor() -> UIColor {
        let r = arc4random() % 255
        let g = arc4random() % 255
        let b = arc4random() % 255
        return UIColor.init(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: 1.0)
    }
    
    //MARK: UITableViewDataSource
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return bannerItemView.bounds.size.height - 30.0
        }
        return 0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.clearColor()
        return view
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 25;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cellId")! as! Cell
        cell.backgroundColor = UIColor.clearColor()
        cell.colorview.backgroundColor = randomColor()
        cell.label.text = "Cell" + "\(indexPath.row)"
        return cell
    }

    //MARK: UITableViewDelegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let alpha: CGFloat = scrollView.contentOffset.y < 0 ? 1 : max (0, 1 - scrollView.contentOffset.y/(CGRectGetHeight(self.bannerItemView.frame)))
        self.bannerItemView.alpha = alpha
        self.blurBannerImage(scrollView.contentOffset.y)
    }
}

