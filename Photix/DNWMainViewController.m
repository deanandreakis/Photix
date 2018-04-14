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
	
    self.uiPicker = [[UIImagePickerController alloc] init];
    
    //FOR TESTING ONLY!!!
    //[[NSUserDefaults standardUserDefaults] setBool:YES forKey:USER_PURCHASED_TIP];
    //[[NSUserDefaults standardUserDefaults] synchronize];
    
    self.uiPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.uiPicker.allowsEditing = NO;
    self.uiPicker.delegate = self;
    self.uiPicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;

    
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
    [self showViewController:self.uiPicker sender:self];
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
    DNWFilterViewController *filterViewController = [[UIStoryboard storyboardWithName:kAppDelegate.storyboardName bundle:nil] instantiateViewControllerWithIdentifier:@"MyFilter"];
    UIImage *temp = [info objectForKey:UIImagePickerControllerOriginalImage];
    filterViewController.imageToSet = temp;
    [self showViewController:filterViewController sender:self];
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
            
            DNWFilterViewController *filterViewController = [[UIStoryboard storyboardWithName:kAppDelegate.storyboardName bundle:nil] instantiateViewControllerWithIdentifier:@"MyFilter"];
            
            filterViewController.imageToSet = result;
            
            [self showViewController:filterViewController sender:self];
            //[self.navigationController pushViewController:filterViewController animated:YES];
        }
    }];
}

@end
