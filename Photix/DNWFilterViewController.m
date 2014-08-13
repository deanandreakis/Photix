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
#import "DNWFilterImage.h"

@interface DNWFilterViewController ()

-(IBAction)StartOverButtonPressed:(id)sender;
-(IBAction)DoneButtonPressed:(id)sender;

@property (strong, nonatomic) IBOutlet UIImageView* pictureImageView;
@property (strong, nonatomic) IBOutlet UIScrollView* filterScrollView;

@end

@implementation DNWFilterViewController

@synthesize pictureImageView, filterScrollView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [pictureImageView setImage:kAppDelegate.imageToSet];
    [self filterImage:kAppDelegate.imageToSet];
    // Do any additional setup after loading the view.
    // 1. Call method that returns array of UIImage objects that are the filtered thumbnails.
    // Pass an argument of the thumbnail of the original unfiltered image.
    // 2. Call a method that sets up the scrollview with all the filtered image thumbnails. Pass
    // in an argument of the array of UIImage objects.
    //3. Set the tag property on each UIImage object in the array so we can get the image back
    //out at the end.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark FilteringCompleteDelegate
-(void)filteringComplete:(NSArray*)filteredImages
{
    NSMutableArray* retVal = [NSMutableArray array];
    
    //TODO: update to parse thru DNWFilteredImageModel objects instead
    //of UIImage objects
    for (int x = 0; x<filteredImages.count; x++) {
        UIImageView* imageView = [[UIImageView alloc] initWithImage:nil];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [imageView setImage:[filteredImages objectAtIndex:x]];
        [retVal addObject:imageView];
    }
    //dispatch_async(dispatch_get_main_queue(), ^{
        [self setupScrollView:retVal];
    //});
}

- (void)filterImage:(UIImage*)imageToFilter
{
    DNWFilterImage* filterImageManager = [[DNWFilterImage alloc] init];
    filterImageManager.filterDelegate = self;
    [filterImageManager filterImage:imageToFilter];
}

//https://gist.github.com/nyoron/363423
- (void)setupScrollView:(NSArray*)imageArray
{
    CGSize pageSize = filterScrollView.frame.size; // scrollView is an IBOutlet for our UIScrollView
    NSUInteger page = 0;
    for(UIView *view in imageArray) {
        [filterScrollView addSubview:view];
        
        // This is the important line
        //view.frame = CGRectMake(pageSize.width * page++ + 10, 0, pageSize.width - 20, pageSize.height);
        view.frame = CGRectMake(pageSize.height * page++, 0, pageSize.height-10, pageSize.height-10);
        // We're making use of the scrollView's frame size (pageSize) so we need to;
        // +10 to left offset of image pos (1/2 the gap)
        // -20 for UIImageView's width (to leave 10 gap at left and right)
    }
    
    //filterScrollView.contentSize = CGSizeMake(pageSize.width * [imageArray count], pageSize.height);
    filterScrollView.contentSize = CGSizeMake(pageSize.height * [imageArray count], pageSize.height-10);
    
    
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
}

@end
