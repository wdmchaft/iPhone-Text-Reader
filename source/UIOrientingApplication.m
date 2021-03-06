/*
    UIOrientingApplication -- iPhone / iPod Touch UIKit Class
    ©2008 James Yopp; LGPL License
    
    Application re-orients the display automatically to match the physical orientation of the hardware.
    Display can be locked / unlocked to prevent this behavior, and can be manually oriented with lockUIToOrientation.
*/


#import "UIOrientingApplication.h"

@implementation UIOrientingApplication

/* Set of Default Orientations in degrees: {Faceup, Standing, UpsideDown, Left, Right, Indeterminate, Facedown}
    VALID values here are 0, 90, 180, and -90 degrees.  Anything else may not work as expected.
    A value of -1 means that no angle is associated (do not change anything for this orientation code) */
static const int defaultOrientations[7] = {-1, 0, -1, 90, -90, -1, -1};

- (id) init {
    initialized = false;
    id rVal = [super init];
    unsigned char i = 7;
    while (i--) 
        orientations[i] = defaultOrientations[i];
    orientationLocked = NO;
    reorientationDuration = 0.35f;
    orientationDegrees = -1;
    orientation = 0;
    oCode = 1;
    curStatus = ShowStatus_Light;
    [self setUIOrientation: 1];
    return rVal;
}

- (ShowStatus) getShowStatusBar {
    return curStatus;
}

- (void) setInitialized: (bool)b {
    initialized = b;
//  [self setUIOrientation: 1];
}

- (bool) isInitialized {
    return initialized;
}

- (void) showStatusBar:(ShowStatus)ss {

    curStatus = ss;
    switch (ss)
    {
        case ShowStatus_Off:
            [self setStatusBarMode:2 duration: 0.0f];
            break;
        case ShowStatus_Dark:
            [self setStatusBarMode:1 duration: 0.0f];
            break;
        default:
        case ShowStatus_Light:
            [self setStatusBarMode:0 duration: 0.0f];
            break;
    }
    
} // showStatus

- (void) lockUIOrientation {
    orientationLocked = YES;
}

- (void) lockUIToOrientation: (unsigned int)o_code {
    [self setUIOrientation: o_code];
    [self lockUIOrientation];
}

- (void) unlockUIOrientation {
    orientationLocked = NO;
    [self deviceOrientationChanged: nil];
}

- (void) deviceOrientationChanged: (GSEvent*)event {
    if (orientationLocked) return;
    [self setUIOrientation: [UIHardware deviceOrientation:YES]];
}

- (int) getOrientation {
    return orientation;
}

- (void) setUIOrientation: (unsigned int)o_code {
    if (o_code > 6) return;
    /* Degrees should technically be a float, but without integers here, rounding errors seem to screw up the UI over time.
        The compiler will automatically cast to a float when appropriate API calls are made. */
    int degrees = orientations[o_code];
    if (degrees == -1) return;
    if (degrees == orientationDegrees) return;
    
    orientation = degrees;
    oCode = o_code;
    
    /* Find the rect a fullscreen app would use under the new rotation... */
    bool landscape = (degrees == 90 || degrees == -90);
    struct CGSize size = [UIHardware mainScreenSize];

    float statusBar = (curStatus == ShowStatus_Off) ? 0.0f : [UIHardware statusBarHeight];
    
    statusBar = 0;
    
    if (landscape) 
        size.width -= statusBar;
    else 
        size.height -= statusBar;
    
    FullKeyBounds.origin.x = (degrees == 90) ? statusBar : 0;
    FullKeyBounds.origin.y = 0;
    FullKeyBounds.size = size;
    
    FullContentBounds.origin.x = FullContentBounds.origin.y = 0;
    FullContentBounds.size = (landscape) ? CGSizeMake(size.height, size.width) : size; 
    
    /* Now that our member variable is set, we try to apply these changes to the key view, if present.
        If this routine is called before there is a key view, it will still set the rects and move the statusbar. */
    UIWindow *key = [UIWindow keyWindow];
    if (key) 
    {
        [self setStatusBarMode:[self statusBarMode]
            orientation: (degrees == 180) ? 0 : degrees
            duration:reorientationDuration fenceID:0 animation:3];
    
        UIView *content = [key contentView];
        if (content) 
        {
            struct CGSize oldSize = [content bounds].size;

            [UIView beginAnimations: nil];
                [UIView setAnimationDuration: reorientationDuration];
        
                [content setBounds: FullContentBounds];
                [content resizeSubviewsWithOldSize: oldSize];
                [key setBounds: FullKeyBounds];
                [content setRotationBy: degrees - orientationDegrees];
            [UIView endAnimations];
            
        } 
        else 
            [key setBounds: FullKeyBounds];
    } 
    else 
        [self setStatusBarMode: [self statusBarMode] orientation: (degrees == 180) ? 0 : degrees duration:0.0f];
    
    orientationDegrees = degrees;
    [super setUIOrientation: o_code];
}

- (void) setAngleForOrientation: (unsigned int)o_code toDegrees: (int)degrees {
    /* To disable transitions to a particular state, set degrees to -1. */
    if (o_code > 6) return;
    orientations[o_code] = degrees;
}

- (unsigned int)getOrientCode {
    return oCode;
}

- (CGRect) windowBounds {
    return FullKeyBounds;
}

- (CGRect) contentBounds {
    return FullContentBounds;
}

- (bool) orientationLocked {
    return orientationLocked;
}

@end
