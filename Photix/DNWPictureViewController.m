//
//  DNWPictureViewController.m
//  Photix
//
//  Created by Dean Andreakis on 2/16/14.
//  Copyright (c) 2014 deanware. All rights reserved.
//

#import "DNWPictureViewController.h"
#import <Social/Social.h>
#import "MGInstagram.h"
#import "MBProgressHUD.h"
#import "DNWOtherApps.h"
#import "Constants.h"
#import <QuartzCore/QuartzCore.h>

#define ACTION_SHEET_TAG 22
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

@end

@implementation DNWPictureViewController

@synthesize pictureImageView, imageToSet;

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
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self performSelector:@selector(processImage) withObject:nil afterDelay:0.5];
}

-(void)viewWillAppear:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)processImage
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        // Do the task in the background
        GPUImagePicture *stillImageSource;
        UIImage *currentFilteredImage;
        
        stillImageSource = [[GPUImagePicture alloc] initWithImage:imageToSet];
        
        GPUImageKuwaharaFilter *oilPaintingTransformFilter = [[GPUImageKuwaharaFilter alloc] init];
        oilPaintingTransformFilter.radius = 10.0;
        
        [stillImageSource addTarget:oilPaintingTransformFilter];
        [stillImageSource processImage];
        
        currentFilteredImage = [oilPaintingTransformFilter imageFromCurrentlyProcessedOutput];
        NSLog(@"currentFilteredImage Image Size:%f,%f", currentFilteredImage.size.width, currentFilteredImage.size.height);
        
        // Hide the HUD in the main tread
        dispatch_async(dispatch_get_main_queue(), ^{
            [pictureImageView setImage:currentFilteredImage];
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
    });
    
    NSLog(@"pictureImageView Image Size:%f,%f", pictureImageView.image.size.width, pictureImageView.image.size.height);
    NSLog(@"imageToSet Image Size:%f,%f", imageToSet.size.width, imageToSet.size.height);
}

- (UIImage *)resizeImageToSize:(CGSize)targetSize
{
    UIImage *sourceImage = pictureImageView.image;
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
    
    if(newImage == nil)
    NSLog(@"could not scale image");
    
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
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oil Painting Complete!"
                                                    message:@"Oil Painting has been saved to the camera roll."
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
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
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Sorry"
                                  message:@"You can't facebook right now, make sure \
                                  your device has an internet connection and you have \
                                  at least one Facebook account setup"
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
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
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Sorry"
                                  message:@"You can't send a tweet right now, make sure \
                                  your device has an internet connection and you have \
                                  at least one Twitter account setup"
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
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
    /*UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Select Sharing Option:"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:
                                  @"Save to Camera Roll",
                                  @"Rate This App",
                                  nil];
    
    actionSheet.tag = ACTION_SHEET_TAG;
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [actionSheet showInView:self.view];*/
    
    UIActivityViewController * controller = [[UIActivityViewController alloc] initWithActivityItems:@[pictureImageView.image]                                                                  applicationActivities:nil];
    //controller.excludedActivityTypes = @[UIActivityTypeMail, UIActivityTypePostToFacebook, UIActivityTypePostToTwitter];
    [self presentViewController:controller
                       animated:YES
                     completion:^{
                     }];
}

-(IBAction)InstagramButtonPressed:(id)sender
{
    if ([MGInstagram isAppInstalled])// && [MGInstagram isImageCorrectSize:pictureImageView.image])
    {
        [MGInstagram postImage:pictureImageView.image inView:self.view];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Sorry"
                                  message:@"Instagram is not installed"
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

-(IBAction)DropboxButtonPressed:(id)sender
{
    NSString *prefixString = @"MyPhotix";
    
    NSString *guid = [[NSUUID new] UUIDString];
    NSString *uniqueFileName = [NSString stringWithFormat:@"%@_%@.jpeg", prefixString, guid];
    
    //NSLog(@"uniqueFileName: '%@'", uniqueFileName);
    
    [DNWOtherApps setPhotoFileName:uniqueFileName];
    [DNWOtherApps postImage:pictureImageView.image inView:self.view];
}

#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (popup.tag) {
        case ACTION_SHEET_TAG: {
            switch (buttonIndex) {
                case 0://save to camera roll
                    UIImageWriteToSavedPhotosAlbum(pictureImageView.image, self,
                                                   @selector(finishUIImageWriteToSavedPhotosAlbum:
                                                             didFinishSavingWithError:contextInfo:), nil);
                    break;
                case 1://rate this app
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewString]];
                    break;
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

-(IBAction)PostcardButtonPressed:(id)sender
{
    UIImage* newImage = [self resizeImageToSize:CGSizeMake(1838, 1238)];
    
    NSArray* imageArray = [NSArray arrayWithObject:newImage];
    
    SYSincerelyController *controller = [[SYSincerelyController alloc] initWithImages:imageArray
                                                                              product:SYProductTypePostcard
                                                                       applicationKey:SINCERELY_KEY
                                                                             delegate:self];
    
    if (controller) {
        [controller setShouldSkipCrop:YES];
        [self presentViewController:controller animated:YES completion:NULL];
    }
}

#pragma mark SYSincerelyController delegate callbacks

- (void)sincerelyControllerDidFinish:(SYSincerelyController *)controller {
    /*
     * Here I know that the user made a purchase and I can do something with it
     */
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)sincerelyControllerDidCancel:(SYSincerelyController *)controller {
    /*
     * Here I know that the user hit the cancel button and they want to leave the Sincerely controller
     */
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)sincerelyControllerDidFailInitiationWithError:(NSError *)error {
    /*
     * Here I know that incorrect inputs were given to initWithImages:product:applicationKey:delegate;
     */
    
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@"Sorry"
                              message:[error localizedFailureReason]
                              delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
    [alertView show];
}

#pragma mark review me!
-(IBAction)ReviewButtonPressed:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewString]];
}

#pragma mark iAd delegate methods

-(void) bannerViewDidLoadAd:(ADBannerView *)banner
{
    [UIView beginAnimations:nil context:nil];
    
    [UIView setAnimationDuration:1];
    
    [banner setAlpha:1];
    
    [UIView commitAnimations];
}

-(void) bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    [UIView beginAnimations:nil context:nil];
    
    [UIView setAnimationDuration:1];
    
    [banner setAlpha:0];
    
    [UIView commitAnimations];
}





@end
