
#import "DNWImageTests.h"


@implementation DNWImageTests

-(void)setUp
{
    appDelegate = [[UIApplication sharedApplication]delegate];
    
    CGSize result = [[UIScreen mainScreen] bounds].size;
    NSString* storyboardName = nil;
    if(result.height == 568)
    {
        storyboardName = @"MainStoryboardiPhone5";
    }
    else
    {
        storyboardName = @"MainStoryboard";
    }
    
    _picController = [[UIStoryboard storyboardWithName:storyboardName bundle:nil] instantiateViewControllerWithIdentifier:@"MyPicture"];
}

-(void)tearDown
{
    
}

-(void)testProcessImage
{
    //NSString *imageFile = @"test1_2448_3264";
    //NSString *imageFile = @"test2_3264_2448";
    NSString *imageFile = @"test3_640_640";
    
    NSString *path = [[NSBundle mainBundle] pathForResource:imageFile ofType:@"jpg"];
    _picController.imageToSet = [UIImage imageWithContentsOfFile:path];
    
    for (int x=0; x<200; x++) {
        [_picController processImage];
        [PhotixTests waitForCompletion:5];
    }
    
    XCTAssert(YES, @"");//did not crash
}

@end
