//
//  DNWPictureViewController.m
//  Photix
//
//  Created by Dean Andreakis on 2/16/14.
//  Copyright (c) 2014 deanware. All rights reserved.
//

#import "DNWPictureViewController.h"
#import <Social/Social.h>
#import "DNWOtherApps.h"
#import "Constants.h"

#define reviewString @"itms-apps://itunes.apple.com/app/id827491007"


@interface DNWPictureViewController ()

-(IBAction)StartOverButtonPressed:(id)sender;
-(IBAction)ShareButtonPressed:(id)sender;
-(IBAction)ReviewButtonPressed:(id)sender;


@property (strong, nonatomic) IBOutlet UIImageView* pictureImageView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem* shareButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* pictureContraint;

@end

@implementation DNWPictureViewController

@synthesize pictureImageView, imageToSet, shareButton;

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
    [pictureImageView setImage:imageToSet];
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                    style:UIBarButtonItemStyleDone target:self action:@selector(StartOverButtonPressed:)];
    self.navigationItem.rightBarButtonItem = rightButton;
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:FALSE];
}

- (UIImage *)resizeImageToSize:(CGSize)targetSize Image:(UIImage*)sourceImage
{
    UIImage *newImage = nil;
    
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
        
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor < heightFactor)
        scaleFactor = widthFactor;
        else
        scaleFactor = heightFactor;
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // make image center aligned
        if (widthFactor < heightFactor)
        {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else if (widthFactor > heightFactor)
        {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    UIGraphicsBeginImageContext(targetSize);
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //if(newImage == nil)
    //NSLog(@"could not scale image");
    
    return newImage ;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)finishUIImageWriteToSavedPhotosAlbum:(UIImage *)image
                    didFinishSavingWithError:(NSError *)error
                                 contextInfo:(void *)contextInfo
{
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:NSLocalizedString(@"Oil Painting Complete!",nil)
                                          message:@"Oil Painting has been saved to the camera roll."
                                          preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Ok",nil)
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                   }];
    
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark button press callbacks

-(IBAction)StartOverButtonPressed:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(IBAction)ShareButtonPressed:(id)sender
{
    UIImage* newImage = [self resizeImageToSize:CGSizeMake(640, 640) Image:pictureImageView.image];
    
    if (newImage == nil) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Sorry",nil)
                                              message:@"Your picture could not be properly scaled. Please try again"
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"Ok",nil)
                                       style:UIAlertActionStyleCancel
                                       handler:^(UIAlertAction *action)
                                       {
                                       }];
        
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {

        UIActivityViewController * controller = [[UIActivityViewController alloc] initWithActivityItems:@[newImage]                                                                  applicationActivities:nil];
        //if iPhone
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            [self presentViewController:controller animated:YES completion:nil];
        }
        //if iPad
        else {
            // Change Rect to position Popover
            controller.modalPresentationStyle                   = UIModalPresentationPopover;
            controller.popoverPresentationController.barButtonItem = shareButton;
            [self presentViewController:controller animated:YES completion:nil];
        }
    }
}

#pragma mark review me!
-(IBAction)ReviewButtonPressed:(id)sender
{
    NSDictionary *dict = [[NSDictionary alloc] init];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewString] options:dict completionHandler:nil];
}

- (void) traitCollectionDidChange: (UITraitCollection *) previousTraitCollection {
    [super traitCollectionDidChange: previousTraitCollection];
}


@end
