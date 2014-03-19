//
//  PhotixTests.m
//  PhotixTests
//
//  Created by Dean Andreakis on 2/8/14.
//  Copyright (c) 2014 deanware. All rights reserved.
//

#import "PhotixTests.h"


@implementation PhotixTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

+ (BOOL)waitForCompletion:(NSTimeInterval)timeoutSecs
{
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeoutSecs];
    
    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
        if([timeoutDate timeIntervalSinceNow] < 0.0)
            break;
    } while (1);
    
    return YES;
}

+(BOOL) doesActionViewExist
{
    for (UIWindow* window in [UIApplication sharedApplication].windows) {
        NSArray* subviews = window.subviews;
        if ([subviews count] > 0) {
            BOOL action = [[subviews objectAtIndex:0] isKindOfClass:[UIActionSheet class]];
            if (action)
                return YES;
        }
    }
    return NO;
}

+(void) dismissAlertViews
{
    for (UIWindow* window in [UIApplication sharedApplication].windows) {
        NSArray* subviews = window.subviews;
        if ([subviews count] > 0)
            if ([[subviews objectAtIndex:0] isKindOfClass:[UIAlertView class]]){
                [[subviews objectAtIndex:0] dismissWithClickedButtonIndex:0 animated:NO];
            }
    }
}

@end
