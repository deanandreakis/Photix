//
//  DNWOtherApps.h
//  Photix
//
//  Created by Dean Andreakis on 2/21/14.
//  Copyright (c) 2014 deanware. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

@interface DNWOtherApps : NSObject <UIDocumentInteractionControllerDelegate>

extern NSString* const kOnlyPhotoFileName;

+ (void) setPhotoFileName:(NSString*)fileName;
+ (NSString*) photoFileName;
+ (void) postImage:(UIImage*)image withBarItem:(UIBarButtonItem*)barItem inView:(UIView*)view;
+ (void) postImage:(UIImage*)image withCaption:(NSString*)caption inView:(UIView*)view;

@end
