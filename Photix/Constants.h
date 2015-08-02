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

#define CRASHLYTICS_KEY @"2eaad7ad1fecfce6c414905676a8175bb2a1c253"

#define kAppDelegate ((DNWAppDelegate *)[[UIApplication sharedApplication] delegate])

#define STOREKIT_PRODUCT_ID_GENEROUS_99 @"tip99"
#define STOREKIT_PRODUCT_ID_MASSIVE_199 @"tip199"
#define STOREKIT_PRODUCT_ID_AMAZING_499 @"tip499"

#define USER_PURCHASED_TIP @"user_purchased_tip"

#endif
