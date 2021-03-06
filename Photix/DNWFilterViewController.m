//
//  DNWFilterViewController.m
//  Photix
//
//  Created by Dean Andreakis on 8/9/14.
//  Copyright (c) 2014 deanware. All rights reserved.
//

#import "DNWFilterViewController.h"
#import "Constants.h"
#import "DNWPictureViewController.h"
//#import "DNWFilterImage.h"
//#import "DNWFilteredImageModel.h"

@interface DNWFilterViewController ()

-(IBAction)StartOverButtonPressed:(id)sender;
-(IBAction)DoneButtonPressed:(id)sender;

@property (strong, nonatomic) IBOutlet UIImageView* pictureImageView;
@property (strong, nonatomic) IBOutlet UIScrollView* filterScrollView;
@property (strong, nonatomic) NSMutableArray* thumbArray;

@end

@implementation DNWFilterViewController

@synthesize pictureImageView, filterScrollView, thumbArray;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        filterScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //[pictureImageView setImage:kAppDelegate.imageToSet];
    //[self filterImage:kAppDelegate.imageToSet];
    //[pictureImageView setImage:self.imageToSet];
    //[self filterImage:self.imageToSet];
    thumbArray = [NSMutableArray array];
    // Do any additional setup after loading the view.
    // 1. Call method that returns array of UIImage objects that are the filtered thumbnails.
    // Pass an argument of the thumbnail of the original unfiltered image.
    // 2. Call a method that sets up the scrollview with all the filtered image thumbnails. Pass
    // in an argument of the array of UIImage objects.
    //3. Set the tag property on each UIImage object in the array so we can get the image back
    //out at the end.
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Next"
                                                                    style:UIBarButtonItemStyleDone target:self action:@selector(DoneButtonPressed:)];
    self.navigationItem.rightBarButtonItem = rightButton;
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [pictureImageView setImage:self.imageToSet];
    [self filterImage:self.imageToSet];
    
    [self.navigationController setNavigationBarHidden:FALSE];

}

-(void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:TRUE];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        //label.font = [UIFont fontWithName:@"SnellRoundhand-Black" size:12];
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
    
    filterScrollView.contentSize = CGSizeMake(imageWidth * [imageArray count], pageSize.height);
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView
{
    //[aScrollView setContentOffset: CGPointMake(aScrollView.contentOffset.x, oldY)];
    // or if you are sure you wanna it always on top:
    [aScrollView setContentOffset: CGPointMake(aScrollView.contentOffset.x, 0)];
}

-(IBAction)StartOverButtonPressed:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(IBAction)DoneButtonPressed:(id)sender
{
    DNWPictureViewController *pictureViewController = [[UIStoryboard storyboardWithName:kAppDelegate.storyboardName bundle:nil] instantiateViewControllerWithIdentifier:@"MyPicture"];
     //UIImage *temp = [info objectForKey:UIImagePickerControllerEditedImage];
     //kAppDelegate.imageToSet = [temp normalizedImage];
     pictureViewController.imageToSet = pictureImageView.image;
     [self.navigationController pushViewController:pictureViewController animated:YES];
     //[self showViewController:pictureViewController sender:self];
}

//Image selected
- (void) buttonClicked: (id) sender
{
    NSInteger tag = ((UIButton *)sender).tag;
    
    UIImageView* tempView = (UIImageView*)[thumbArray objectAtIndex:tag];
    
    pictureImageView.image = tempView.image;
    
    //self.imageToSet = tempView.image;
}

@end
