//
//  DNWMainViewController.h
//  Photix
//
//  Created by Dean Andreakis on 2/8/14.
//  Copyright (c) 2014 deanware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GMImagePickerController.h"

@interface DNWMainViewController : UIViewController <GMImagePickerControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{}

-(IBAction)TakePhotoButtonPressed:(id)sender;
-(IBAction)ChooseExistingButtonPressed:(id)sender;

@end
