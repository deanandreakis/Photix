//
//  DNWFilterImage.h
//  Photix
//
//  Legacy compatibility header - functionality migrated to Swift
//  This file exists only for build compatibility and will be removed
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Legacy compatibility - all functionality moved to Swift FilterProcessor
@interface DNWFilterImage : NSObject

// Deprecated - use Swift FilterProcessor instead
+ (void)processImageInBackground:(UIImage *)image
                      filterName:(NSString *)filterName
                        delegate:(id)delegate __attribute__((deprecated("Use Swift FilterProcessor")));

@end