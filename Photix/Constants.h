//
//  Constants.h
//  SleepMate
//
//  Created by Dean Andreakis on 5/18/13.
//
//

#ifndef SleepMate_Constants_h
#define SleepMate_Constants_h
#import "DNWAppDelegate.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


#define FLURRY_KEY @""

#define CRASHLYTICS_KEY @""

#define kAppDelegate ((DNWAppDelegate *)[[UIApplication sharedApplication] delegate])

#endif
