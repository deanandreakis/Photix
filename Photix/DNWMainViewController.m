//
//  DNWMainViewController.m
//  Photix
//
//  Created by Dean Andreakis on 2/8/14.
//  Copyright (c) 2014 deanware. All rights reserved.
//

#import "DNWMainViewController.h"
#import "Constants.h"
#import "UIImage+normalizedImage.h"
#import "DNWPictureViewController.h"

@interface DNWMainViewController ()

@property (strong, nonatomic) UIImagePickerController* picker;

@end

@implementation DNWMainViewController

@synthesize picker;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    
    picker.allowsEditing = YES;
    
    //added to hide the nav bar on main screen to see full background
    [self.navigationController setNavigationBarHidden:TRUE];
}

-(void)viewWillAppear:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)TakePhotoButtonPressed:(id)sender
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    [self presentViewController:picker animated:YES completion:nil];
}

-(IBAction)ChooseExistingButtonPressed:(id)sender
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark
#pragma mark UIImagePickerController Delegate Methods
-(void)imagePickerController:(UIImagePickerController *)imagePicker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    //[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [imagePicker dismissViewControllerAnimated:YES completion:nil];
    DNWPictureViewController *pictureViewController = [[UIStoryboard storyboardWithName:kAppDelegate.storyboardName bundle:nil] instantiateViewControllerWithIdentifier:@"MyPicture"];
    UIImage *temp = [info objectForKey:UIImagePickerControllerEditedImage];
    kAppDelegate.imageToSet = [temp normalizedImage];
    pictureViewController.imageToSet = kAppDelegate.imageToSet;
    [self.navigationController pushViewController:pictureViewController animated:YES];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)imagePicker
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [imagePicker dismissViewControllerAnimated:YES completion:nil];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

@end
