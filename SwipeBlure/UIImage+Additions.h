
#import <UIKit/UIKit.h>

@interface UIImage (Additions)
- (UIImage*) scaleToSize:(CGSize)size;
- (UIImage*) imageWithColor:(UIColor *)color;
- (UIImage*) scaleImagetoResolution:(float)resolution;
- (UIImage*) watermarkImageWithImage:(UIImage *)watermarkImage atRect:(CGRect)rect;
- (UIImage*) watermarkImageWithImage:(UIImage *)watermarkImage withEdgeInsets:(UIEdgeInsets)edges;
- (UIImage*) imageByScalingAndCroppingForSize:(CGSize)targetSize;
- (UIImage*) imageByScalingAndCroppingForSize:(CGSize)targetSize position: (NSInteger) iPosition;
- (UIImage*) imageByScalingAspectFillingForSize:(CGSize)frameSize;
- (UIImage*) imageCorrectedForCaptureOrientation;
- (UIImage*) imageByScalingNotCroppingForSize:(CGSize)frameSize;
- (UIImage*) getImageFrom: (UIImage*)img  withRect: (CGRect) rect;
- (UIImage*)imageBorderedWithColor:(UIColor *)color borderWidth:(CGFloat)width;
@end