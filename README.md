# Swipe to blur

Curtain animation transition for UIViewController presenting in Swift

![Screenshot of Swipe to blur](https://github.com/rozum-dev/SwipeBlure/blob/master/out.gif "Swipe to blur Screenshot")

##Demo
Creates an interactive blur effect. Inspired by http://five.agency/how-to-create-an-interactive-blur-effect-in-ios8/ project.
To achieve interactive effect creates a series of blurred images  (20 by default, play with kNumberOfStages constant) with different blur radius and changes them on table view scroll events. To reduce timings original image is scaled by 1/2 (play with kLowerRatioResolution constant) before blurring.
Intermediate images are interpolated by placing next blurred image with alpha appropriate for current scroll position on top of previous blurred image.
A heavy operation of Images generation (initBlurredImages() method call) should be done before allowing UITableview interactions (currently initBlurredImages() is called synchronously on viewDidLoad()), time of it’s execution is printed to debug log.
Performs well even on old devices.

## Requirements
* Xcode 7 or higher
* Apple LLVM compiler
* Swift

