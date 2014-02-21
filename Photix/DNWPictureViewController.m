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

#define ACTION_SHEET_TAG 22
#define reviewString @"itms-apps://itunes.apple.com/app/idXXXXXXXXX"//TODO put app ID in here when we know it


@interface DNWPictureViewController ()

-(IBAction)StartOverButtonPressed:(id)sender;
-(IBAction)FacebookButtonPressed:(id)sender;
-(IBAction)TwitterButtonPressed:(id)sender;
-(IBAction)EmailButtonPressed:(id)sender;
-(IBAction)ShareButtonPressed:(id)sender;
-(IBAction)InstagramButtonPressed:(id)sender;
-(IBAction)DropboxButtonPressed:(id)sender;

//TODO: add order prints (like walgreens api), tumblr, dropbox

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
}

- (void)viewWillAppear:(BOOL)animated
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self performSelector:@selector(processImage) withObject:nil afterDelay:1.0];
}

- (void)processImage
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        // Do the task in the background
        GPUImagePicture *stillImageSource;
        UIImage *currentFilteredImage;
        
        stillImageSource = [[GPUImagePicture alloc] initWithImage:imageToSet];
        
        GPUImageKuwaharaFilter *oilPaintingTransformFilter = [[GPUImageKuwaharaFilter alloc] init];
        oilPaintingTransformFilter.radius = 6.0;
        
        [stillImageSource addTarget:oilPaintingTransformFilter];
        [stillImageSource processImage];
        
        currentFilteredImage = [oilPaintingTransformFilter imageFromCurrentlyProcessedOutput];
        
        // Hide the HUD in the main tread
        dispatch_async(dispatch_get_main_queue(), ^{
            [pictureImageView setImage:currentFilteredImage];
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
    });
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
        [fbSheet setInitialText:@"Look at my Oil Painting! #PictOil"];
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
        [tweetSheet setInitialText:@"Look at my Oil Painting! #PictOil"];
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
    [mailViewController setMessageBody:@"I had fun using the PictOil app to make my photo lool like an oil painting!" isHTML:NO];
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
    controller.excludedActivityTypes = @[UIActivityTypeMail, UIActivityTypePostToFacebook, UIActivityTypePostToTwitter];
    [self presentViewController:controller
                       animated:YES
                     completion:^{
                     }];
}

-(IBAction)InstagramButtonPressed:(id)sender
{
    if ([MGInstagram isAppInstalled] && [MGInstagram isImageCorrectSize:pictureImageView.image])
    {
        [MGInstagram postImage:pictureImageView.image inView:self.view];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Sorry"
                                  message:@"Instagram is either not installed or the image is an incorrect size"
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

-(IBAction)DropboxButtonPressed:(id)sender
{
    //see https://www.dropbox.com/developers/core/start/ios
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

@end
