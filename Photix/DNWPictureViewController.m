//
//  DNWPictureViewController.m
//  Photix
//
//  Created by Dean Andreakis on 2/16/14.
//  Copyright (c) 2014 deanware. All rights reserved.
//

#import "DNWPictureViewController.h"
#import <Social/Social.h>
#import "DNWInstagram.h"
#import "DNWOtherApps.h"
#import "Constants.h"

#define reviewString @"itms-apps://itunes.apple.com/app/id827491007"


@interface DNWPictureViewController ()

-(IBAction)StartOverButtonPressed:(id)sender;
-(IBAction)FacebookButtonPressed:(id)sender;
-(IBAction)TwitterButtonPressed:(id)sender;
-(IBAction)EmailButtonPressed:(id)sender;
-(IBAction)ShareButtonPressed:(id)sender;
-(IBAction)InstagramButtonPressed:(id)sender;
-(IBAction)DropboxButtonPressed:(id)sender;//other apps to open into
-(IBAction)PostcardButtonPressed:(id)sender;
-(IBAction)ReviewButtonPressed:(id)sender;


@property (strong, nonatomic) IBOutlet UIImageView* pictureImageView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem* shareButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem* instagramButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem* moreButton;

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
    //[MBProgressHUD showHUDAddedTo:self.view animated:YES];
    //[self performSelector:@selector(processImage) withObject:nil afterDelay:0.5];
}

-(void)viewWillAppear:(BOOL)animated
{
    BOOL productPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:USER_PURCHASED_TIP];
    if (productPurchased) {
    }
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

-(IBAction)FacebookButtonPressed:(id)sender
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
    {
        SLComposeViewController *fbSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        [fbSheet setInitialText:@"Look at my Oil Painting! #OilPaint+"];
        //may need to resize image
        [fbSheet addImage:pictureImageView.image];
        [self presentViewController:fbSheet animated:YES completion:nil];
    }
    else
    {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Sorry",nil)
                                              message:@"You can't facebook right now, make sure \
                                              your device has an internet connection and you have \
                                              at least one Facebook account setup"
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
}

-(IBAction)TwitterButtonPressed:(id)sender
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [tweetSheet setInitialText:@"Look at my Oil Painting! #OilPaint+"];
        [tweetSheet addImage:pictureImageView.image];
        [self presentViewController:tweetSheet animated:YES completion:nil];
    }
    else
    {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Sorry",nil)
                                              message:@"You can't send a tweet right now, make sure \
                                              your device has an internet connection and you have \
                                              at least one Twitter account setup"
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
}

-(IBAction)EmailButtonPressed:(id)sender
{
    MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
    mailViewController.mailComposeDelegate = self;
    [mailViewController setSubject:@"Oil Painting!"];
    [mailViewController setMessageBody:@"I had fun using the OilPaint+ app to make my photo lool like an oil painting!" isHTML:NO];
    NSData *myData = UIImageJPEGRepresentation(pictureImageView.image, 1.0);
    [mailViewController addAttachmentData:myData mimeType:@"image/jpeg" fileName:@"PictOil.jpg"];
    [self presentViewController:mailViewController animated:YES completion:nil];
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

-(IBAction)InstagramButtonPressed:(id)sender
{
    if ([DNWInstagram isAppInstalled])// && [MGInstagram isImageCorrectSize:pictureImageView.image])
    {
        //[MGInstagram postImage:pictureImageView.image withBarButtonItem:self.instagramButton inView:self.view];
        [DNWInstagram postImage:pictureImageView.image withBarItem:self.instagramButton inView:self.view];
    }
    else
    {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Sorry",nil)
                                              message:@"Instagram is not installed"
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
}

-(IBAction)DropboxButtonPressed:(id)sender
{
    NSString *prefixString = @"MyPhotix";
    
    NSString *guid = [[NSUUID new] UUIDString];
    NSString *uniqueFileName = [NSString stringWithFormat:@"%@_%@.jpeg", prefixString, guid];
    
    //NSLog(@"uniqueFileName: '%@'", uniqueFileName);
    
    [DNWOtherApps setPhotoFileName:uniqueFileName];
    [DNWOtherApps postImage:pictureImageView.image withBarItem:self.moreButton inView:self.view];
}

#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(IBAction)PostcardButtonPressed:(id)sender
{
    
}

#pragma mark review me!
-(IBAction)ReviewButtonPressed:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewString]];
}

- (void) traitCollectionDidChange: (UITraitCollection *) previousTraitCollection {
    [super traitCollectionDidChange: previousTraitCollection];
    if ((self.traitCollection.verticalSizeClass != previousTraitCollection.verticalSizeClass)
        || self.traitCollection.horizontalSizeClass != previousTraitCollection.horizontalSizeClass) {
        // hide the ad banner view
        if(self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
           //||
           //(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad &&
            //UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation))) {
            //adBannerView.hidden = YES;
        } else {
            BOOL productPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:USER_PURCHASED_TIP];
            if (!productPurchased) {
                //adBannerView.hidden = NO;
            }
        }
    }
}


@end
