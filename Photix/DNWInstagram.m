//
//  DNWInstagram.m
//  Photix
//
//  Created by Dean Andreakis on 8/2/15.
//  Copyright (c) 2015 deanware. All rights reserved.
//

#import "DNWInstagram.h"

@interface DNWInstagram() {
    UIDocumentInteractionController *documentInteractionController;
}

@end

@implementation DNWInstagram

+ (instancetype) sharedInstance
{
    static DNWInstagram* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DNWInstagram alloc] init];
    });
    return sharedInstance;
}

- (NSString*) photoFilePath {
    return [NSString stringWithFormat:@"%@/%@",[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"],kInstagramOnlyPhotoFileName];
}

+ (void) postImage:(UIImage*)image withBarItem:(UIBarButtonItem*)barItem inView:(UIView*)view {
    [[DNWInstagram sharedInstance] postImage:image withBarItem:barItem inView:view];
}

- (void) postImage:(UIImage*)image withBarItem:(UIBarButtonItem*)barItem inView:(UIView*)view
{
    if (!image)
        [NSException raise:NSInternalInconsistencyException format:@"Image cannot be nil!"];
    
    [UIImageJPEGRepresentation(image, 1.0) writeToFile:[self photoFilePath] atomically:YES];
    
    NSURL *fileURL = [NSURL fileURLWithPath:[self photoFilePath]];
    documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    documentInteractionController.UTI = @"com.instagram.exclusivegram";
    documentInteractionController.delegate = self;
    [documentInteractionController presentOpenInMenuFromBarButtonItem:barItem animated:YES];
}

@end
