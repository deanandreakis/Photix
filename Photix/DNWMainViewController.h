//
//  DNWMainViewController.h
//  Photix
//
//  Created by Dean Andreakis on 2/8/14.
//  Copyright (c) 2014 deanware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DNWMainViewController : UIViewController <UIImagePickerControllerDelegate,UINavigationControllerDelegate>
{}

-(IBAction)TakePhotoButtonPressed:(id)sender;
-(IBAction)ChooseExistingButtonPressed:(id)sender;
-(void)EditLastPhoto;
-(void)openModernInterface;

@end
