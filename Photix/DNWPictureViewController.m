//
//  DNWPictureViewController.m
//  Photix
//
//  Created by Dean Andreakis on 2/16/14.
//  Copyright (c) 2014 deanware. All rights reserved.
//

#import "DNWPictureViewController.h"

@interface DNWPictureViewController ()

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
    
    GPUImagePicture *stillImageSource;
    UIImage *currentFilteredImage;
    
    stillImageSource = [[GPUImagePicture alloc] initWithImage:imageToSet];
    
    float heightToUse = 480.0;
    
    CGSize result = [[UIScreen mainScreen] bounds].size;
    if(result.height == 568)
    {
        heightToUse = 568.0;
    }
    
    // Left Eye
    GPUImageKuwaharaFilter *leftEyePinchTransformFilter = [[GPUImageKuwaharaFilter alloc] init];
    leftEyePinchTransformFilter.radius = 6.0;

    [stillImageSource addTarget:leftEyePinchTransformFilter];
    [stillImageSource processImage];
    
    currentFilteredImage = [leftEyePinchTransformFilter imageFromCurrentlyProcessedOutput];
    
    /*[stillImageSource addTarget:leftCheekPinchTransformFilter];
     [stillImageSource processImage];
     
     currentFilteredImage = [leftCheekPinchTransformFilter imageFromCurrentlyProcessedOutput];*/
    
    [pictureImageView setImage:currentFilteredImage];
}

- (void)viewWillAppear:(BOOL)animated
{
    //[pictureImageView setImage:imageToSet];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
