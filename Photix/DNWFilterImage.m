//
//  DNWFilterImage.m
//  Photix
//
//  Legacy compatibility implementation - functionality migrated to Swift
//  This file exists only for build compatibility and will be removed
//

#import "DNWFilterImage.h"

@implementation DNWFilterImage

+ (void)processImageInBackground:(UIImage *)image
                      filterName:(NSString *)filterName
                        delegate:(id)delegate {
    // Legacy method - functionality moved to Swift FilterProcessor
    // This implementation is empty and deprecated
    NSLog(@"Warning: DNWFilterImage is deprecated. Use Swift FilterProcessor instead.");
}

@end