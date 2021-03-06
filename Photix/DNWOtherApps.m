//
//  DNWOtherApps.m
//  Photix
//
//  Created by Dean Andreakis on 2/21/14.
//  Copyright (c) 2014 deanware. All rights reserved.
//

#import "DNWOtherApps.h"

@interface DNWOtherApps () {
    UIDocumentInteractionController *documentInteractionController;
}

@property (nonatomic) NSString *photoFileName;

@end

@implementation DNWOtherApps

NSString* const kOnlyPhotoFileName = @"tempphoto.jpeg";

+ (instancetype) sharedInstance
{
    static DNWOtherApps* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DNWOtherApps alloc] init];
    });
    return sharedInstance;
}

- (id) init {
    if (self = [super init]) {
        self.photoFileName = kOnlyPhotoFileName;
    }
    return self;
}

+ (void) setPhotoFileName:(NSString*)fileName {
    [DNWOtherApps sharedInstance].photoFileName = fileName;
}
+ (NSString*) photoFileName {
    return [DNWOtherApps sharedInstance].photoFileName;
}

- (NSString*) photoFilePath {
    return [NSString stringWithFormat:@"%@/%@",[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"],self.photoFileName];
}

+ (void) postImage:(UIImage*)image withBarItem:(UIBarButtonItem*)barItem inView:(UIView*)view {
    [[DNWOtherApps sharedInstance] postImage:image withCaption:nil withBarItem:barItem inView:view];
}
+ (void) postImage:(UIImage*)image withCaption:(NSString*)caption inView:(UIView*)view {
    [[DNWOtherApps sharedInstance] postImage:image withCaption:caption withBarItem:nil inView:view];
}

- (void) postImage:(UIImage*)image withCaption:(NSString*)caption withBarItem:(UIBarButtonItem*)barItem inView:(UIView*)view
{
    if (!image)
        [NSException raise:NSInternalInconsistencyException format:@"Image cannot be nil!"];
    
    [UIImageJPEGRepresentation(image, 1.0) writeToFile:[self photoFilePath] atomically:YES];
    
    NSURL *fileURL = [NSURL fileURLWithPath:[self photoFilePath]];
    documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    documentInteractionController.UTI = @"com.instagram.photo";
    documentInteractionController.delegate = self;
    if (caption)
        documentInteractionController.annotation = [NSDictionary dictionaryWithObject:caption forKey:@"InstagramCaption"];
    CGRect rect;
    //if iPhone
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        rect = CGRectZero;
        [documentInteractionController presentOpenInMenuFromRect:rect inView:view animated:YES];
    }
    //if iPad
    else {
        [documentInteractionController presentOpenInMenuFromBarButtonItem:barItem animated:YES];
    }
    
}

@end
