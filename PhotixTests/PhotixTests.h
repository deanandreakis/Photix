#import <XCTest/XCTest.h>


@interface PhotixTests : XCTestCase
+ (BOOL) waitForCompletion:(NSTimeInterval)timeoutSecs;
+ (BOOL) doesActionViewExist;
+ (void) dismissAlertViews;
@end
