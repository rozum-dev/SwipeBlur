
//

#import "UIImage+Additions.h"
#import <Accelerate/Accelerate.h>

@implementation UIImage (Additions)

- (UIImage*) scaleToSize:(CGSize)size {
    return [UIImage vImageScaledImage:self withSize:size];
}

- (UIImage*) imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    // Create a 1 by 1 pixel context
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);   // Fill it with your color
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

// Method: vImageScaledImage:(UIImage*) sourceImage withSize:(CGSize) destSize
// Returns even better scaling than drawing to a context with kCGInterpolationHigh.
// This employs the vImage routines in Accelerate.framework.
// For more information about vImage, see https://developer.apple.com/library/mac/#documentation/performance/Conceptual/vImage/Introduction/Introduction.html#//apple_ref/doc/uid/TP30001001-CH201-TPXREF101
// Large quantities of memory are manually allocated and (hopefully) freed here.  Test your application for leaks before and after using this method.
+ (UIImage*) vImageScaledImage:(UIImage*) sourceImage withSize:(CGSize) destSize {
    if (!destSize.width || !destSize.height || CGSizeEqualToSize(destSize, sourceImage.size))
        return sourceImage;
    
    UIImage *destImage = nil;
    if (sourceImage)
    {
        // First, convert the UIImage to an array of bytes, in the format expected by vImage.
        // Thanks: http://stackoverflow.com/a/1262893/1318452
        CGImageRef sourceRef = [sourceImage CGImage];
        NSUInteger sourceWidth = CGImageGetWidth(sourceRef);
        NSUInteger sourceHeight = CGImageGetHeight(sourceRef);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        unsigned char *sourceData = (unsigned char*) calloc(sourceHeight * sourceWidth * 4, sizeof(unsigned char));
        NSUInteger bytesPerPixel = 4;
        NSUInteger sourceBytesPerRow = bytesPerPixel * sourceWidth;
        NSUInteger bitsPerComponent = 8;
        CGContextRef context = CGBitmapContextCreate(sourceData, sourceWidth, sourceHeight,
                                                     bitsPerComponent, sourceBytesPerRow, colorSpace,
                                                     kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Big);
        assert(context);
        CGContextDrawImage(context, CGRectMake(0, 0, sourceWidth, sourceHeight), sourceRef);
        CGContextRelease(context);
        
        // We now have the source data.  Construct a pixel array
        NSUInteger destWidth = (NSUInteger)fmaxf(1.0f, destSize.width * sourceImage.scale + .5f);
        NSUInteger destHeight = (NSUInteger)fmaxf(1.0f, destSize.height * sourceImage.scale + .5f);
        NSUInteger destBytesPerRow = bytesPerPixel * destWidth;
        unsigned char *destData = (unsigned char*) calloc(destHeight * destWidth * 4, sizeof(unsigned char));
        
        // Now create vImage structures for the two pixel arrays.
        // Thanks: https://github.com/dhoerl/PhotoScrollerNetwork
        vImage_Buffer src = {
            .data = sourceData,
            .height = sourceHeight,
            .width = sourceWidth,
            .rowBytes = sourceBytesPerRow
        };
        
        vImage_Buffer dest = {
            .data = destData,
            .height = destHeight,
            .width = destWidth,
            .rowBytes = destBytesPerRow
        };
        
        // Carry out the scaling.
        vImage_Error err = vImageScale_ARGB8888 (&src,
                                                 &dest,
                                                 NULL,
                                                 kvImageHighQualityResampling);
        
        // The source bytes are no longer needed.
        free(sourceData);
        
        // Convert the destination bytes to a UIImage.
        CGContextRef destContext = CGBitmapContextCreate(destData, destWidth, destHeight,
                                                         bitsPerComponent, destBytesPerRow, colorSpace,
                                                         kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Big);
        assert(destContext);
        if (!destContext)
            return nil;
        CGImageRef destRef = CGBitmapContextCreateImage(destContext);
        assert(destRef);
        
        // Store the result.
        destImage = [UIImage imageWithCGImage:destRef scale:sourceImage.scale orientation:sourceImage.imageOrientation];
        
        // Free up the remaining memory.
        CGImageRelease(destRef);
        
        CGColorSpaceRelease(colorSpace);
        CGContextRelease(destContext);
        
        // The destination bytes are no longer needed.
        free(destData);
        
        if (err != kvImageNoError)
        {
            NSString *errorReason = [NSString stringWithFormat:@"vImageScale returned error code %zd", err];
            NSDictionary *errorInfo = @{@"sourceImage" : sourceImage,
                                        @"destSize" : [NSValue valueWithCGSize:destSize]};
            
            NSException *exception = [NSException exceptionWithName:@"HighQualityImageScalingFailureException" reason:errorReason userInfo:errorInfo];
            
            assert(false);
            @throw exception;
        }
    }
    return destImage;
}

// Change image resolution (auto-resize to fit)
- (UIImage*) scaleImagetoResolution:(float)resolution {
    CGRect bounds = (CGRect){{0, 0}, self.size};
    
    //if already at the minimum resolution, return the orginal image, otherwise scale
    if (bounds.size.width <= resolution && bounds.size.height <= resolution) {
        return self;
        
    } else {
        CGFloat ratio = bounds.size.width/bounds.size.height;
        
        if (ratio > 1) {
            bounds.size.width = resolution;
            bounds.size.height = bounds.size.width / ratio;
        } else {
            bounds.size.height = resolution;
            bounds.size.width = bounds.size.height * ratio;
        }
    }
    
    if (!bounds.size.width || !bounds.size.height)
        return nil;
    
    UIImage* scaledImage = [UIImage vImageScaledImage:self withSize:bounds.size];
    
    // We need to save the imageOrientation:
    UIImage* scaledImageWithOrientation = [[UIImage alloc] initWithCGImage:scaledImage.CGImage scale:self.scale orientation:self.imageOrientation];
    return scaledImageWithOrientation;
}

- (UIImage*)watermarkImageWithImage:(UIImage *)watermarkImage atRect:(CGRect)rect {
    // Create new offscreen context with desired size
    UIGraphicsBeginImageContext(self.size);
    
    // draw img at 0,0 in the context
    [self drawAtPoint:CGPointZero];
    [watermarkImage drawInRect:rect];
    
    // assign context to UIImage
    UIImage *outputImg = UIGraphicsGetImageFromCurrentImageContext();
    
    // end context
    UIGraphicsEndImageContext();
    
    return outputImg;
}

- (UIImage*)watermarkImageWithImage:(UIImage *)watermarkImage withEdgeInsets:(UIEdgeInsets)edges {
    // Create new offscreen context with desired size
    UIGraphicsBeginImageContext(self.size);
    
    // draw img at 0,0 in the context
    [self drawAtPoint:CGPointZero];
    [watermarkImage drawInRect:(CGRect){edges.left,edges.top,self.size.width-edges.right,self.size.height-edges.bottom}];
    
    // assign context to UIImage
    UIImage *outputImg = UIGraphicsGetImageFromCurrentImageContext();
    
    // end context
    UIGraphicsEndImageContext();
    
    return outputImg;
}

- (UIImage*) imageByCroppingWithoutScalingForSize:(CGSize)targetSize position: (NSInteger) iPosition {
    if (!targetSize.width || !targetSize.height || CGSizeEqualToSize(targetSize, self.size))
        return self;
    
    UIImage* sourceImage = self;
    UIImage* newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        scaleFactor = MAX(widthFactor,heightFactor);
        
        scaledWidth = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        switch (iPosition) {
            case 1: //top
                if (widthFactor > heightFactor) {
                    thumbnailPoint.y = 0;
                } else if (widthFactor < heightFactor) {
                    thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
                }
                break;
            default:
            case 2: //center
                if (widthFactor > heightFactor) {
                    thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
                } else if (widthFactor < heightFactor) {
                    thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
                }
                break;
            case 3: //bottom
                if (widthFactor > heightFactor) {
                    thumbnailPoint.y = (targetHeight - scaledHeight);
                } else if (widthFactor < heightFactor) {
                    thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
                }
                break;
        }
    }
    
    if (!targetSize.width || !targetSize.height)
        return nil;
    
    UIGraphicsBeginImageContextWithOptions(targetSize, NO, self.scale); // this will crop
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    
    [sourceImage drawAtPoint:thumbnailPoint];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if (newImage == nil)
        NSLog(@"could not scale image");
    assert(newImage);
    
    // pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage*) imageByScalingAndCroppingForSize:(CGSize)targetSize {
    return [self imageByScalingAndCroppingForSize:targetSize position:2];
}

- (UIImage*) imageByScalingAndCroppingForSize:(CGSize)targetSize position: (NSInteger) iPosition {
    if (!targetSize.width || !targetSize.height || CGSizeEqualToSize(targetSize, self.size))
        return self;
    
    CGSize imageSize = self.size;
    
    float s = MIN(imageSize.width/targetSize.width,imageSize.height/targetSize.height);
    CGSize croppedSize = (CGSize){targetSize.width*s,targetSize.height*s};
    
    UIImage *croppedImage = [self imageByCroppingWithoutScalingForSize:croppedSize position:iPosition];
    
    UIImage *scaled = [UIImage vImageScaledImage:croppedImage withSize:targetSize];
    return scaled;
}

- (UIImage*) getImageFrom: (UIImage*)img  withRect: (CGRect) rect {
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // translated rectangle for drawing sub image
    CGRect drawRect = CGRectMake(-rect.origin.x, -rect.origin.y, img.size.width, img.size.height);
    
    // clip to the bounds of the image context
    // not strictly necessary as it will get clipped anyway?
    CGContextClipToRect(context, CGRectMake(0, 0, rect.size.width, rect.size.height));
    
    // draw image
    [img drawInRect:drawRect];
    
    // grab image
    UIImage* subImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return subImage;
}

- (UIImage*) imageCorrectedForCaptureOrientation
{
    // No-op if the orientation is already correct
    if (self.imageOrientation == UIImageOrientationUp) return self;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (self.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (self.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, self.size.width, self.size.height,
                                             CGImageGetBitsPerComponent(self.CGImage), 0,
                                             CGImageGetColorSpace(self.CGImage),
                                             CGImageGetBitmapInfo(self.CGImage));
    assert(ctx);
    CGContextConcatCTM(ctx, transform);
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.height,self.size.width), self.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.width,self.size.height), self.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    assert(ctx);
    if (!ctx)
        return nil;
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    assert(cgimg);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

- (UIImage*) imageByScalingNotCroppingForSize:(CGSize)frameSize {
    CGSize imageSize = self.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = frameSize.width;
    CGFloat targetHeight = frameSize.height;
    CGFloat scaleFactor = 0.0;
    CGSize scaledSize = frameSize;
    
    if (CGSizeEqualToSize(imageSize, frameSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        // opposite comparison to imageByScalingAndCroppingForSize in order to contain the image within the given bounds
        if (widthFactor > heightFactor) {
            scaleFactor = heightFactor; // scale to fit height
        } else {
            scaleFactor = widthFactor; // scale to fit width
        }
        scaledSize = CGSizeMake(MIN(width * scaleFactor, targetWidth), MIN(height * scaleFactor, targetHeight));
    }
    
    if (!scaledSize.width || !scaledSize.height)
        return nil;
    
    return [UIImage vImageScaledImage:self withSize:scaledSize];
}

- (UIImage*) imageByScalingAspectFillingForSize:(CGSize)frameSize {
    CGSize imageSize = self.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = frameSize.width;
    CGFloat targetHeight = frameSize.height;
    CGFloat scaleFactor = 0.0;
    CGSize scaledSize = frameSize;
    
    if (CGSizeEqualToSize(imageSize, frameSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        // opposite comparison to imageByScalingAndCroppingForSize in order to contain the image within the given bounds
        if (widthFactor < heightFactor)
            scaleFactor = heightFactor;
        else
            scaleFactor = widthFactor;
        scaledSize = CGSizeMake(width * scaleFactor, height * scaleFactor);
    }
    
    if (!scaledSize.width || !scaledSize.height)
        return nil;
    
    return [UIImage vImageScaledImage:self withSize:scaledSize];
}

-(UIImage *)imageBorderedWithColor:(UIColor *)color borderWidth:(CGFloat)width
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
    [self drawAtPoint:CGPointZero];
    [color setStroke];
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    path.lineWidth = width;
    [path stroke];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

@end
