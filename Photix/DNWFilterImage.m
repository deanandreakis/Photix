//
//  DNWFilterImage.m
//  Photix
//
//  Created by Dean Andreakis on 8/10/14.
//  Copyright (c) 2014 deanware. All rights reserved.
//

#import "DNWFilterImage.h"
#import <GPUImage.h>
#import <QuartzCore/QuartzCore.h>

@interface DNWFilterImage ()

@property (strong, nonatomic) NSMutableDictionary* filterNameDictionary;//lists all the names of the GPUImage filters we use
    
@end

@implementation DNWFilterImage

@synthesize filterDelegate, filterNameDictionary;

- (id) init {
    if (self = [super init]) {
        filterNameDictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"GPUImageKuwaharaFilter", @"Oil Paint",
                                 @"GPUImagePixellateFilter",@"Pixels",
                                 @"GPUImagePolarPixellateFilter",@"Polar Pixels",
                                 @"GPUImagePolkaDotFilter",@"Polka-Dots",
                                 @"GPUImageHalftoneFilter",@"Half Tone",
                                 @"GPUImageCrosshatchFilter",@"Cross Hatch",
                                 @"GPUImageSketchFilter",@"Sketch",nil];
    }
    return self;
}

-(void)filterImage:(UIImage*)imageToFilter
{
    [self processGPUImageFilters:imageToFilter];
}

- (void)processGPUImageFilters:(UIImage*)imageToFilter
{
    NSMutableArray* retVal = [NSMutableArray array];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    
        UIImage* newImage = imageToFilter;
        
        // Do the task in the background
        GPUImagePicture *stillImageSource;
        UIImage *currentFilteredImage;
        
        for (id key in filterNameDictionary) {
            
            stillImageSource = [[GPUImagePicture alloc] initWithImage:newImage];
            
            NSString* filterName = (NSString*)filterNameDictionary[key];
            Class filterClass = NSClassFromString(filterName);
            
            id oilPaintingTransformFilter = [[filterClass alloc] init];
            //oilPaintingTransformFilter.radius = 8.0;
            //oilPaintingTransformFilter.fractionalWidthOfAPixel = 0.05;
            
            [stillImageSource addTarget:oilPaintingTransformFilter];
            [stillImageSource processImage];
            
            currentFilteredImage = [oilPaintingTransformFilter imageFromCurrentlyProcessedOutput];
            
            [retVal addObject:currentFilteredImage];
            //NSLog(@"currentFilteredImage Image Size:%f,%f", currentFilteredImage.size.width, currentFilteredImage.size.height);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.filterDelegate filteringComplete:retVal];
        });
    
    });
    
    //NSLog(@"pictureImageView Image Size:%f,%f", pictureImageView.image.size.width, pictureImageView.image.size.height);
    //NSLog(@"imageToSet Image Size:%f,%f", imageToSet.size.width, imageToSet.size.height);
}

@end
