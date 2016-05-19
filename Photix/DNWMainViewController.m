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
#import "DNWFilterViewController.h"

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
    picker.allowsEditing = NO;
    //added to hide the nav bar on main screen to see full background
    [self.navigationController setNavigationBarHidden:TRUE];
}

-(void)viewWillAppear:(BOOL)animated
{
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)exitSettings:(UIStoryboardSegue *)segue {
}

-(IBAction)TakePhotoButtonPressed:(id)sender
{
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    [self presentViewController:picker animated:YES completion:nil];
}

-(IBAction)ChooseExistingButtonPressed:(id)sender
{
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark
#pragma mark UIImagePickerController Delegate Methods
-(void)imagePickerController:(UIImagePickerController *)imagePicker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [imagePicker dismissViewControllerAnimated:YES completion:nil];
    DNWFilterViewController *filterViewController = [[UIStoryboard storyboardWithName:kAppDelegate.storyboardName bundle:nil] instantiateViewControllerWithIdentifier:@"MyFilter"];
    UIImage *temp = [info objectForKey:UIImagePickerControllerOriginalImage];
    kAppDelegate.imageToSet = [temp normalizedImage];
    [self.navigationController pushViewController:filterViewController animated:YES];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)imagePicker
{
    [imagePicker dismissViewControllerAnimated:YES completion:nil];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
}

@end
