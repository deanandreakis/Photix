//
//  DNWOtherApps.h
//  Photix
//
//  Created by Dean Andreakis on 2/21/14.
//  Copyright (c) 2014 deanware. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DNWOtherApps : NSObject <UIDocumentInteractionControllerDelegate>

extern NSString* const kOnlyPhotoFileName;

+ (void) setPhotoFileName:(NSString*)fileName;
+ (NSString*) photoFileName;
+ (void) postImage:(UIImage*)image inView:(UIView*)view;
+ (void) postImage:(UIImage*)image withCaption:(NSString*)caption inView:(UIView*)view;

@end
