//
//  SleepsterIAPHelper.m
//  SleepMate
//
//  Created by Dean Andreakis on 9/17/13.
//
//

#import "PhotixIAPHelper.h"
#import "Constants.h"

@implementation PhotixIAPHelper

+ (PhotixIAPHelper *)sharedInstance {
    static dispatch_once_t once;
    static PhotixIAPHelper * sharedInstance;
    dispatch_once(&once, ^{
        NSSet * productIdentifiers = [NSSet setWithObjects:
                                      STOREKIT_PRODUCT_ID_GENEROUS_99,
                                      STOREKIT_PRODUCT_ID_MASSIVE_199,
                                      STOREKIT_PRODUCT_ID_AMAZING_499,
                                      nil];
        sharedInstance = [[self alloc] initWithProductIdentifiers:productIdentifiers];
    });
    return sharedInstance;
}

@end
