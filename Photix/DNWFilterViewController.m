//
//  DNWFilterViewController.m
//  Photix
//
//  Created by Dean Andreakis on 8/9/14.
//  Copyright (c) 2014 deanware. All rights reserved.
//

#import "DNWFilterViewController.h"

@interface DNWFilterViewController ()

@property (strong, nonatomic) IBOutlet UIImageView* pictureImageView;
@property (strong, nonatomic) IBOutlet UIScrollView* filterScrollView;

@end

@implementation DNWFilterViewController

@synthesize pictureImageView, filterScrollView;

- (void)viewDidLoad {
    [super viewDidLoad];
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

//https://gist.github.com/nyoron/363423
- (void)setupScrollView:(NSArray*)imageArray
{
    CGSize pageSize = filterScrollView.frame.size; // scrollView is an IBOutlet for our UIScrollView
    NSUInteger page = 0;
    for(UIView *view in imageArray) {
        [filterScrollView addSubview:view];
        
        // This is the important line
        view.frame = CGRectMake(pageSize.width * page++ + 10, 0, pageSize.height, pageSize.height);
        // We're making use of the scrollView's frame size (pageSize) so we need to;
        // +10 to left offset of image pos (1/2 the gap)
        // -20 for UIImageView's width (to leave 10 gap at left and right)
    }
    
    filterScrollView.contentSize = CGSizeMake(pageSize.width * [imageArray count], pageSize.height);
    
}

@end
