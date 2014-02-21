//
//  DNWPictureViewController.h
//  Photix
//
//  Created by Dean Andreakis on 2/16/14.
//  Copyright (c) 2014 deanware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GPUImage.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface DNWPictureViewController : UIViewController <MFMailComposeViewControllerDelegate, UIActionSheetDelegate>

@property UIImage *imageToSet;

@end
