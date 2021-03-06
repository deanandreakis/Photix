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
#import "DNWFilteredImageModel.h"

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


#pragma mark FilteringCompleteDelegate
-(void)filteringComplete:(NSArray*)filteredImages //array of DNWFilteredImageModel objects
{
    [self setupScrollView:filteredImages];
}

- (void)filterImage:(UIImage*)imageToFilter
{
    DNWFilterImage* filterImageManager = [[DNWFilterImage alloc] init];
    filterImageManager.filterDelegate = self;
    [filterImageManager filterImage:imageToFilter];
}

//https://gist.github.com/nyoron/363423
- (void)setupScrollView:(NSArray*)imageArray//array of DNWFilteredImageModel objects
{
    CGSize pageSize = filterScrollView.frame.size; // scrollView is an IBOutlet for our UIScrollView
    NSUInteger page = 0;
    NSUInteger imageWidth = filterScrollView.frame.size.height * 0.8;//80;
    NSUInteger imageHeight = imageWidth;//80;
    
    [thumbArray removeAllObjects];
    
    for(DNWFilteredImageModel *model in imageArray) {
        
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
