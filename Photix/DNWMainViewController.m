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

//@property (strong, nonatomic) UIImagePickerController* picker;
//@property (strong, nonatomic) GMImagePickerController* gmPicker;
@property (nonatomic, strong) PHImageRequestOptions *requestOptions;

@end

@implementation DNWMainViewController

//@synthesize picker;

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
    //self.gmPicker = [[GMImagePickerController alloc] init];
    //self.gmPicker.delegate = self;
    //self.gmPicker.allowsMultipleSelection = NO;
    
    self.requestOptions = [[PHImageRequestOptions alloc] init];
    self.requestOptions.resizeMode   = PHImageRequestOptionsResizeModeExact;
    self.requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    
    // this one is key
    self.requestOptions.synchronous = true;
    
    //picker = [[UIImagePickerController alloc] init];
    //picker.delegate = self;
    
    //picker.allowsEditing = NO;
    //picker.allowsEditing = YES;
    
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
    GMImagePickerController* gmPicker = [[GMImagePickerController alloc] init];
    gmPicker.delegate = self;
    gmPicker.allowsMultipleSelection = NO;
    gmPicker.title = @"";
    gmPicker.customDoneButtonTitle = @"Done";
    gmPicker.customCancelButtonTitle = @"Cancel";
    gmPicker.customNavigationBarPrompt = @"Take a new photo or select an existing one!";
    
    gmPicker.showCameraButton = YES;
    gmPicker.autoSelectCameraImages = YES;
    //[self presentViewController:gmPicker animated:YES completion:nil];
    //[self showViewController:gmPicker sender:nil];
    [self.navigationController pushViewController:gmPicker animated:YES];
    
    //picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    //picker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    //[self presentViewController:picker animated:YES completion:nil];
}

-(IBAction)ChooseExistingButtonPressed:(id)sender
{
    GMImagePickerController* gmPicker = [[GMImagePickerController alloc] init];
    gmPicker.delegate = self;
    gmPicker.allowsMultipleSelection = NO;
    gmPicker.title = @"";
    gmPicker.customDoneButtonTitle = @"Done";
    gmPicker.customCancelButtonTitle = @"Cancel";
    gmPicker.customNavigationBarPrompt = @"Take a new photo or select an existing one!";

    gmPicker.showCameraButton = NO;
    gmPicker.autoSelectCameraImages = NO;
    //[self presentViewController:gmPicker animated:YES completion:nil];
    //[self showViewController:gmPicker sender:nil];
    [self.navigationController pushViewController:gmPicker animated:YES];
    
    //picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    //[self presentViewController:picker animated:YES completion:nil];
}

#pragma mark
#pragma mark GMImagePickerController Delegate Methods
- (void)assetsPickerController:(GMImagePickerController *)thepicker didFinishPickingAssets:(NSArray *)assetArray
{
    //[thepicker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
    
    assetArray = [NSMutableArray arrayWithArray:assetArray];
    PHImageManager *manager = [PHImageManager defaultManager];
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:[assetArray count]];
    
    // assets contains PHAsset objects.
    __block UIImage *ima;
    
    for (PHAsset *asset in assetArray) {
        // Do something with the asset
        
        [manager requestImageForAsset:asset
                           targetSize:PHImageManagerMaximumSize
                          contentMode:PHImageContentModeDefault
                              options:self.requestOptions
                        resultHandler:^void(UIImage *image, NSDictionary *info) {
                            ima = image;
                            
                            [images addObject:ima];
                        }];
        
        
    }
    
    DNWFilterViewController *filterViewController = [[UIStoryboard storyboardWithName:kAppDelegate.storyboardName bundle:nil] instantiateViewControllerWithIdentifier:@"MyFilter"];
    
    filterViewController.imageToSet = images[0];
    
    [self.navigationController pushViewController:filterViewController animated:YES];
}

-(void)assetsPickerControllerDidCancel:(GMImagePickerController *)thepicker
{
    //[thepicker dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark
#pragma mark UIImagePickerController Delegate Methods
-(void)imagePickerController:(UIImagePickerController *)imagePicker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage __block *temp = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    imagePicker = nil;
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        temp = [temp normalizedImage];
        if(temp.size.height > 500.0 || temp.size.width > 500.0)
        {
            float scaleFactor = 2.0;
            if(temp.size.height > temp.size.width)
            {
                scaleFactor = temp.size.height / 500.0;
            } else {
                scaleFactor = temp.size.width / 500.0;
            }
            // scaling set to 2.0 makes the image 1/2 the size.
            temp = [UIImage imageWithCGImage:[temp CGImage]
                                       scale:(temp.scale * scaleFactor)
                                 orientation:(temp.imageOrientation)];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            DNWFilterViewController *filterViewController = [[UIStoryboard storyboardWithName:kAppDelegate.storyboardName bundle:nil] instantiateViewControllerWithIdentifier:@"MyFilter"];
            
            filterViewController.imageToSet = temp;
            
            [self.navigationController pushViewController:filterViewController animated:YES];
        });
        
    });
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)imagePicker
{
    [imagePicker dismissViewControllerAnimated:YES completion:nil];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
}

@end
