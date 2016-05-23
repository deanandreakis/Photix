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

@property (strong, nonatomic) GMImagePickerController* gmPicker;
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
    self.gmPicker = [[GMImagePickerController alloc] init];
    self.gmPicker.delegate = self;
    self.gmPicker.allowsMultipleSelection = NO;
    self.gmPicker.title = @"OilPaintPlus";
    self.gmPicker.customDoneButtonTitle = @"Done";
    self.gmPicker.customCancelButtonTitle = @"Cancel";
    self.gmPicker.customNavigationBarPrompt = @"";
    self.gmPicker.showCameraButton = YES;
    self.gmPicker.autoSelectCameraImages = YES;
    
    self.requestOptions = [[PHImageRequestOptions alloc] init];
    self.requestOptions.resizeMode   = PHImageRequestOptionsResizeModeExact;
    self.requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    self.requestOptions.networkAccessAllowed = YES;
    
    // this one is key
    self.requestOptions.synchronous = true;
    
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
    [self.navigationController pushViewController:self.gmPicker animated:YES];
}

-(IBAction)ChooseExistingButtonPressed:(id)sender
{
    [self.navigationController pushViewController:self.gmPicker animated:YES];
}

#pragma mark
#pragma mark GMImagePickerController Delegate Methods
- (void)assetsPickerController:(GMImagePickerController *)thepicker didFinishPickingAssets:(NSArray *)assetArray
{
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
                            if(image != nil)
                            {
                                ima = image;
                                [images addObject:ima];
                            }
                        }];
        
        
    }
    
    DNWFilterViewController *filterViewController = [[UIStoryboard storyboardWithName:kAppDelegate.storyboardName bundle:nil] instantiateViewControllerWithIdentifier:@"MyFilter"];
    
    if(images.count > 0)
    {
        filterViewController.imageToSet = images[0];
    }
    
    [self.navigationController pushViewController:filterViewController animated:YES];
}

-(void)assetsPickerControllerDidCancel:(GMImagePickerController *)thepicker
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
}

@end
