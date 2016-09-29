//
//  UIView+Additions.swift

import Foundation

extension UIView {
    
    func addTranparencyMask() {
        let layer = CALayer()
        var mask: UIImage?
        mask = UIImage(named: "image_mask")
        layer.frame = CGRect(x: 0, y: 0, width: CGRectGetWidth(self.frame), height: CGRectGetHeight(self.frame))
        layer.contents = mask?.CGImage
        self.layer.mask = layer
    }

    func removeTranparencyMask() {
        self.layer.mask = nil
    }
    
}
