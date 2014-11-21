//
//  DNWFilterImage.m
//  Photix
//
//  Created by Dean Andreakis on 8/10/14.
//  Copyright (c) 2014 deanware. All rights reserved.
//

#import "DNWFilterImage.h"
#import <QuartzCore/QuartzCore.h>
#import "DNWFilteredImageModel.h"
#import "GPUImage.h"

@interface DNWFilterImage ()

@property (strong, nonatomic) NSMutableDictionary* filterNameDictionary;//lists all the names of the GPUImage filters we use
@property (strong, nonatomic) NSArray* guideArray;
@end

@implementation DNWFilterImage

@synthesize filterDelegate, filterNameDictionary, guideArray;

- (id) init {
    if (self = [super init]) {
        //NOTE: All strings representing the keys from the filterNameDictionary MUST be present in
        //the guideArray as the guideArray is used to define the order that the filters show up from left
        //to right in the DNWFilterViewController..
        filterNameDictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"GPUImageKuwaharaFilter", @"Oil Paint",
                                 @"GPUImagePixellateFilter",@"Pixels",
                                 @"GPUImagePolarPixellateFilter",@"PolarPix",
                                 @"GPUImagePolkaDotFilter",@"Dots",
                                 @"GPUImageHalftoneFilter",@"HalfTone",
                                 @"GPUImageCrosshatchFilter",@"Crossy",
                                 @"GPUImageSketchFilter",@"Sketch",
                                 @"GPUImageToonFilter",@"Cartoon",
                                 @"GPUImageSmoothToonFilter",@"Smoothy",
                                 @"GPUImageEmbossFilter",@"Emboss",
                                 @"GPUImagePosterizeFilter",@"Poster",
                                 @"GPUImageSwirlFilter",@"Swirly",
                                @"GPUImageBulgeDistortionFilter",@"Bulge",
                                @"GPUImagePinchDistortionFilter",@"Pinch",
                                @"GPUImageStretchDistortionFilter",@"Stretch",
                                @"GPUImageSphereRefractionFilter",@"Sphere",
                                @"GPUImageGlassSphereFilter",@"Glass",
                                @"GPUImageVignetteFilter",@"Vignette",
                                @"GPUImageCGAColorspaceFilter",@"CGA",
                                @"GPUImageSepiaFilter",@"Sepia",
                                @"GPUImageiOSBlurFilter",@"Blur",
                                @"GPUImageColorInvertFilter",@"Invert",
                                @"GPUImageGrayscaleFilter",@"Gray",
                                @"GPUImageFalseColorFilter",@"False",
                                @"GPUImageSoftEleganceFilter",@"Soft",
                                @"GPUImageHazeFilter",@"Haze",nil];
        
        guideArray = [[NSArray alloc] initWithObjects:@"Oil Paint",@"Blur",@"Pixels",@"PolarPix",@"Dots",@"HalfTone",@"Crossy",
                      @"Sketch",@"Cartoon",@"Smoothy",@"Emboss",@"Poster",@"Swirly",@"Bulge",@"Pinch",@"Stretch",
                      @"Sphere",@"Glass",@"Vignette",@"CGA",@"Sepia",@"Invert",@"Gray",@"False",@"Soft",@"Haze",nil];
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
        //GPUImagePicture *stillImageSource;
        UIImage *currentFilteredImage;
        
        for (id key in filterNameDictionary) {
            
            //stillImageSource = [[GPUImagePicture alloc] initWithImage:newImage];
            
            NSString* filterName = (NSString*)filterNameDictionary[key];
            Class filterClass = NSClassFromString(filterName);
            
            id oilPaintingTransformFilter = [[filterClass alloc] init];
            //oilPaintingTransformFilter.radius = 8.0;
            //oilPaintingTransformFilter.fractionalWidthOfAPixel = 0.05;
            
            //[stillImageSource addTarget:oilPaintingTransformFilter];
            //[stillImageSource processImage];
            
            ///currentFilteredImage = [oilPaintingTransformFilter imageFromCurrentFramebuffer];
            currentFilteredImage = [oilPaintingTransformFilter imageByFilteringImage:newImage];
            
            DNWFilteredImageModel* imageModel = [[DNWFilteredImageModel alloc] init];
            imageModel.imageName = (NSString*)key;
            imageModel.filteredImage = currentFilteredImage;
            
            [retVal addObject:imageModel];
            //NSLog(@"currentFilteredImage Image Size:%f,%f", currentFilteredImage.size.width, currentFilteredImage.size.height);
        }
        
        [retVal sortUsingComparator:^(id o1, id o2) {
            DNWFilteredImageModel *item1 = o1;
            DNWFilteredImageModel *item2 = o2;
            NSInteger idx1 = [guideArray indexOfObject:item1.imageName];
            NSInteger idx2 = [guideArray indexOfObject:item2.imageName];
            return idx1 - idx2;
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.filterDelegate filteringComplete:retVal];
        });
    
    });
    
    //NSLog(@"pictureImageView Image Size:%f,%f", pictureImageView.image.size.width, pictureImageView.image.size.height);
    //NSLog(@"imageToSet Image Size:%f,%f", imageToSet.size.width, imageToSet.size.height);
}

@end
