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
#import <PhotosUI/PhotosUI.h>
#import "TargetConditionals.h"
#import "Photix-Swift.h"

@interface DNWMainViewController ()

@property (strong, nonatomic) UIImagePickerController* gmPicker;
@property (strong, nonatomic) UIImagePickerController* uiPicker;
//@property (nonatomic, strong) PHImageRequestOptions *requestOptions;

@end

@implementation DNWMainViewController

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
    
    // Add navigation bar button for new SwiftUI interface
    UIBarButtonItem *modernButton = [[UIBarButtonItem alloc] initWithTitle:@"Modern" style:UIBarButtonItemStylePlain target:self action:@selector(openModernInterface)];
    self.navigationItem.rightBarButtonItem = modernButton;
    
#if !TARGET_IPHONE_SIMULATOR
    self.uiPicker = [[UIImagePickerController alloc] init];
    
    //FOR TESTING ONLY!!!
    //[[NSUserDefaults standardUserDefaults] setBool:YES forKey:USER_PURCHASED_TIP];
    //[[NSUserDefaults standardUserDefaults] synchronize];

    self.uiPicker.sourceType = UIImagePickerControllerSourceTypeCamera;

    self.uiPicker.allowsEditing = NO;
    self.uiPicker.delegate = self;
    self.uiPicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
#endif
    
    self.gmPicker = [[UIImagePickerController alloc] init];
    self.gmPicker.delegate = self;
    self.gmPicker.title = @"Albums";
}

-(void)viewWillAppear:(BOOL)animated
{
    //added to hide the nav bar on main screen to see full background
    [self.navigationController setNavigationBarHidden:TRUE];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)exitSettings:(UIStoryboardSegue *)segue {
}

-(IBAction)TakePhotoButtonPressed:(id)sender
{
#if !TARGET_IPHONE_SIMULATOR
    [self showViewController:self.uiPicker sender:self];
#endif
}

-(IBAction)ChooseExistingButtonPressed:(id)sender
{
    [self showViewController:self.gmPicker sender:self];
}

#pragma mark
#pragma mark UIImagePickerController Delegate Methods
-(void)imagePickerController:(UIImagePickerController *)imagePicker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [imagePicker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    UIImage *temp = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    // Use modern SwiftUI interface by default
    // Set the preference for future launches
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"UseModernInterface"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Present SwiftUI filter selection
    [SwiftUIBridge presentFilterSelectionFromViewController:self withImage:temp];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)imagePicker
{
    [imagePicker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)EditLastPhoto
{
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    fetchOptions.fetchLimit = 1;
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];
    PHAsset *lastImageAsset = [fetchResult firstObject];
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.networkAccessAllowed = true;
    
    [[PHImageManager defaultManager]requestImageForAsset:lastImageAsset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *result, NSDictionary *info){
        if ([info objectForKey:PHImageErrorKey] == nil && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue] && result != nil) {
            
            // Option: Use modern SwiftUI interface or legacy interface
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"UseModernInterface"]) {
                // Present SwiftUI filter selection
                [SwiftUIBridge presentFilterSelectionFromViewController:self withImage:result];
            } else {
                // Use legacy Objective-C interface
                DNWFilterViewController *filterViewController = [[UIStoryboard storyboardWithName:kAppDelegate.storyboardName bundle:nil] instantiateViewControllerWithIdentifier:@"MyFilter"];
                filterViewController.imageToSet = result;
                [self showViewController:filterViewController sender:self];
            }
        }
    }];
}

#pragma mark - Modern Interface Methods

- (void)openModernInterface
{
    // Present the full SwiftUI interface
    [SwiftUIBridge presentPhotoCaptureFromViewController:self];
}

@end
