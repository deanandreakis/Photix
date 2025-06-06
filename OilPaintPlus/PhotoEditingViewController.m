//
//  PhotoEditingViewController.m
//  OilPaintPlus
//
//  Created by Dean Andreakis on 8/19/14.
//  Copyright (c) 2014 deanware. All rights reserved.
//

#import "PhotoEditingViewController.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>

// Simple implementation for the extension
@implementation SimpleFilteredImageModel
@synthesize imageName, filteredImage;
@end

@interface PhotoEditingViewController () <PHContentEditingController>
@property (strong) PHContentEditingInput *input;
@property (strong, nonatomic) IBOutlet UIImageView* bigImageView;
@property (strong, nonatomic) IBOutlet UIScrollView* filterScrollView;
@property (strong, nonatomic) NSMutableArray* thumbArray;
@property (nonatomic) NSInteger imageArrayCount;
@end

@implementation PhotoEditingViewController

@synthesize bigImageView, filterScrollView, thumbArray;

- (void)viewDidLoad {
    [super viewDidLoad];
    thumbArray = [NSMutableArray array];
    self.imageArrayCount = 0;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - PHContentEditingController

- (BOOL)canHandleAdjustmentData:(PHAdjustmentData *)adjustmentData {
    // Inspect the adjustmentData to determine whether your extension can work with past edits.
    // (Typically, you use its formatIdentifier and formatVersion properties to do this.)
    return YES;
}

- (void)startContentEditingWithInput:(PHContentEditingInput *)contentEditingInput placeholderImage:(UIImage *)placeholderImage {
    // Present content for editing, and keep the contentEditingInput for use when closing the edit session.
    // If you returned YES from canHandleAdjustmentData:, contentEditingInput has the original image and adjustment data.
    // If you returned NO, the contentEditingInput has past edits "baked in".
    self.input = contentEditingInput;
    bigImageView.image = placeholderImage;
    [self filterImage:placeholderImage];
}

- (void)finishContentEditingWithCompletionHandler:(void (^)(PHContentEditingOutput *))completionHandler {
    // Update UI to reflect that editing has finished and output is being rendered.
    
    // Render and provide output on a background queue.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Create editing output from the editing input.
        PHContentEditingOutput *output = [[PHContentEditingOutput alloc] initWithContentEditingInput:self.input];
        
        // Provide new adjustments and render output to given location.
        NSData *adjData = [NSKeyedArchiver archivedDataWithRootObject:self->bigImageView];
        output.adjustmentData = [[PHAdjustmentData alloc] initWithFormatIdentifier:@"AdjustementDataIdentifier" formatVersion:@"1.0" data:adjData];
        NSData *renderedJPEGData = UIImageJPEGRepresentation(self->bigImageView.image, 1.0);
        [renderedJPEGData writeToURL:output.renderedContentURL atomically:YES];
        
        // Call completion handler to commit edit to Photos.
        completionHandler(output);
        
        // Clean up temporary files, etc.
    });
}

- (BOOL)shouldShowCancelConfirmation {
    // Returns whether a confirmation to discard changes should be shown to the user on cancel.
    // (Typically, you should return YES if there are any unsaved changes.)
    return NO;
}

- (void)cancelContentEditing {
    // Clean up temporary files, etc.
    // May be called after finishContentEditingWithCompletionHandler: while you prepare output.
}


- (void)filterImage:(UIImage*)imageToFilter
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *filteredImages = [NSMutableArray array];
        
        // Add original image
        SimpleFilteredImageModel *originalModel = [[SimpleFilteredImageModel alloc] init];
        originalModel.imageName = @"Original";
        originalModel.filteredImage = imageToFilter;
        [filteredImages addObject:originalModel];
        
        // Apply Kuwahara (Oil Paint) filter
        UIImage *oilPaintImage = [self applyKuwaharaFilter:imageToFilter];
        if (oilPaintImage) {
            SimpleFilteredImageModel *oilPaintModel = [[SimpleFilteredImageModel alloc] init];
            oilPaintModel.imageName = @"Oil Paint";
            oilPaintModel.filteredImage = oilPaintImage;
            [filteredImages addObject:oilPaintModel];
        }
        
        // Update UI on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupScrollView:filteredImages];
        });
    });
}

- (UIImage *)applyKuwaharaFilter:(UIImage *)inputImage
{
    // Simple oil paint effect using Core Image filters
    CIImage *ciImage = [CIImage imageWithCGImage:inputImage.CGImage];
    if (!ciImage) return nil;
    
    // Apply a combination of blur and sharpen to simulate oil paint effect
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setValue:ciImage forKey:kCIInputImageKey];
    [blurFilter setValue:@(3.0) forKey:kCIInputRadiusKey];
    
    CIImage *blurred = blurFilter.outputImage;
    if (!blurred) return nil;
    
    // Apply color controls to enhance the painted look
    CIFilter *colorFilter = [CIFilter filterWithName:@"CIColorControls"];
    [colorFilter setValue:blurred forKey:kCIInputImageKey];
    [colorFilter setValue:@(1.2) forKey:kCIInputSaturationKey];
    [colorFilter setValue:@(0.1) forKey:kCIInputBrightnessKey];
    [colorFilter setValue:@(1.1) forKey:kCIInputContrastKey];
    
    CIImage *outputImage = colorFilter.outputImage;
    if (!outputImage) return nil;
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:ciImage.extent];
    
    if (!cgImage) return nil;
    
    UIImage *result = [UIImage imageWithCGImage:cgImage 
                                          scale:inputImage.scale 
                                    orientation:inputImage.imageOrientation];
    
    CGImageRelease(cgImage);
    return result;
}

//https://gist.github.com/nyoron/363423
- (void)setupScrollView:(NSArray*)imageArray//array of SimpleFilteredImageModel objects
{
    CGSize pageSize = filterScrollView.frame.size; // scrollView is an IBOutlet for our UIScrollView
    NSUInteger page = 0;
    NSUInteger imageWidth = filterScrollView.frame.size.height * 0.8;//80;
    NSUInteger imageHeight = imageWidth;//80;
    
    [thumbArray removeAllObjects];
    
    for(SimpleFilteredImageModel *model in imageArray) {
        
        UIImageView* imageView = [[UIImageView alloc] initWithImage:nil];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [imageView setImage:model.filteredImage];
        imageView.frame = CGRectMake(imageWidth * page + 5, 0, imageWidth - 10, imageHeight);
        [thumbArray addObject:imageView];
        [filterScrollView addSubview:imageView];
        
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(imageWidth * page + 5, pageSize.height-20, imageWidth-10, 15)];
        label.font = [UIFont fontWithName:@"GillSans" size:12];
        [label setTextColor:[UIColor blackColor]];
        [label setBackgroundColor:[UIColor clearColor]];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = model.imageName;
        [filterScrollView addSubview:label];
        
        UIButton* btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = imageView.frame;
        [btn addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        btn.tag = page;
        [filterScrollView addSubview:btn];
        
        page++;
    }
    
    self.imageArrayCount = [imageArray count];
    
    filterScrollView.contentSize = CGSizeMake(imageWidth * [imageArray count], pageSize.height);
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView
{
    //[aScrollView setContentOffset: CGPointMake(aScrollView.contentOffset.x, oldY)];
    // or if you are sure you wanna it always on top:
    //if(aScrollView.frame.size.width > aScrollView.frame.size.height) {
        [aScrollView setContentOffset: CGPointMake(aScrollView.contentOffset.x, 0)];
   // } else {
     //   [aScrollView setContentOffset: CGPointMake(0, aScrollView.contentOffset.y)];
    //}
}

//Image selected
- (void) buttonClicked: (id) sender
{
    NSInteger tag = ((UIButton *)sender).tag;
    
    UIImageView* tempView = (UIImageView*)[thumbArray objectAtIndex:tag];
    
    bigImageView.image = tempView.image;
}
/*
- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    if(newCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact &&
       newCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact)
    {
        //[filterScrollView setContentOffset: CGPointMake(0, filterScrollView.contentOffset.y)];
        //filterScrollView.contentSize = CGSizeMake(100, 381);
        filterScrollView.contentSize = CGSizeMake(filterScrollView.frame.size.width,(filterScrollView.frame.size.width * 0.8) * self.imageArrayCount);
        
    } else {
        //[filterScrollView setContentOffset: CGPointMake(filterScrollView.contentOffset.x, 0)];
        //filterScrollView.contentSize = CGSizeMake(filterScrollView.frame.size.width+1, filterScrollView.frame.size.height);
        filterScrollView.contentSize = CGSizeMake((filterScrollView.frame.size.height * 0.8) * self.imageArrayCount, filterScrollView.frame.size.height);
    }
    
}*/

@end
