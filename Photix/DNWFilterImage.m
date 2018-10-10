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
#import "UIImage+normalizedImage.h"
#import <PhotixFilter/PhotixFilter-Swift.h>


@interface DNWFilterImage ()

@property (strong, nonatomic) NSMutableDictionary* filterNameDictionaryCITest;//lists all the names of the CoreImage filters we use
@property (strong, nonatomic) NSMutableArray* retVal;
@end

@implementation DNWFilterImage

@synthesize filterDelegate, filterNameDictionaryCITest;

- (id) init {
    if (self = [super init]) {
        //NOTE: All strings representing the keys from the filterNameDictionary MUST be present in
        //the guideArray as the guideArray is used to define the order that the filters show up from left
        //to right in the DNWFilterViewController.
        filterNameDictionaryCITest = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                  @"CIColorMonochrome",@"Color Mono",
                                  @"CIGaussianBlur",@"Blur",
                                  @"CIPhotoEffectChrome",@"Chrome",
                                  @"CIPhotoEffectFade",@"Faded",
                                  @"CIPhotoEffectInstant",@"Instant",
                                  @"CIPhotoEffectMono",@"B&W Mono",
                                  @"CIPhotoEffectNoir",@"Noir",
                                  @"CIPhotoEffectProcess",@"Vintage Cool",
                                  @"CIPhotoEffectTonal",@"Tonal",
                                  @"CIPhotoEffectTransfer",@"Transfer",
                                  @"CISepiaTone",@"Sepia",
                                  @"CIColorPosterize",@"Posterize",
                                  @"CIColorInvert", @"Invert",
                                  @"CIFalseColor", @"False",
                                  @"CIGloom", @"Gloom",
                                  @"CIPixellate", @"8-bit Retro",
                                  @"CIVignetteEffect", @"Vignette",
                                  nil];
        
        self.retVal = [NSMutableArray array];
    }
    return self;
}

- (UIImage *)resizeImageToSize:(CGSize)targetSize Image:(UIImage*)sourceImage
{
    UIImage *newImage = nil;
    
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
        
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor < heightFactor)
            scaleFactor = widthFactor;
        else
            scaleFactor = heightFactor;
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // make image center aligned
        if (widthFactor < heightFactor)
        {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else if (widthFactor > heightFactor)
        {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    UIGraphicsBeginImageContext(targetSize);
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage ;
}

-(void)filterImage:(UIImage*)imageToFilter
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        DNWFilteredImageModel* imageModel = [[DNWFilteredImageModel alloc] init];
        imageModel.imageName = @"Original";
        imageModel.filteredImage = imageToFilter;
        [self.retVal addObject:imageModel];
        
        if(imageToFilter.size.width > 1000.0 || imageToFilter.size.height > 1000.0)
        {
            CGFloat width = imageToFilter.size.width;
            CGFloat height = imageToFilter.size.height;
            CGFloat scaleFactor = 0.0;
            
            CGFloat widthFactor = 1000.0 / width;
            CGFloat heightFactor = 1000.0 / height;
            
            if (widthFactor < heightFactor)
                scaleFactor = widthFactor;
            else
                scaleFactor = heightFactor;
            
            CGFloat scaledWidth  = width * scaleFactor;
            CGFloat scaledHeight = height * scaleFactor;
            
            UIImage* newImage = [self resizeImageToSize:CGSizeMake(scaledWidth, scaledHeight) Image:imageToFilter];
        
            [self processCoreImageFilters:newImage];
        } else{
            [self processCoreImageFilters:imageToFilter];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.filterDelegate filteringComplete:self.retVal];
        });
        
    });
}

- (void)processCoreImageFilters:(UIImage*)imageToFilter
{
    UIImageOrientation orientation = imageToFilter.imageOrientation;
    
    CIImage* beginImage = [CIImage imageWithCGImage:imageToFilter.CGImage];

    CIContext *context = [CIContext contextWithOptions:nil];
    
    // FOR KUWAHARA
    KuwaharaFilter* opFilter = [[KuwaharaFilter alloc] init];
    opFilter.inputImage = beginImage;
    
    CIImage *outputImage = opFilter.outputImage;
    
    CGImageRef cgimg =
    [context createCGImage:outputImage fromRect:[outputImage extent]];
    
    UIImage *newImage = [UIImage imageWithCGImage:cgimg scale:1.0 orientation:orientation];
    
    DNWFilteredImageModel* imageModel = [[DNWFilteredImageModel alloc] init];
    imageModel.imageName = @"Oil Paint";
    imageModel.filteredImage = newImage;
    
    [self.retVal addObject:imageModel];
    
    CGImageRelease(cgimg);
    // END KUWAHARA
    
    for (id key in filterNameDictionaryCITest) {
        
        NSString* filterName = (NSString*)filterNameDictionaryCITest[key];
        
        CIFilter *filter = [CIFilter filterWithName:filterName];
        
        [filter setValue:beginImage forKey:kCIInputImageKey];
        
        if([filterName isEqualToString:@"CIVignetteEffect"]) {
            CGFloat centerX = beginImage.extent.size.width/2.0;
            CGFloat centerY = beginImage.extent.size.height/2.0;
            CIVector* vector = [CIVector vectorWithX:centerX Y:centerY];
            [filter setValue:vector forKey:kCIInputCenterKey];
            [filter setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputIntensity"];
            
            if(centerX > centerY) {
                [filter setValue:[NSNumber numberWithFloat:(centerY - .2*centerY)] forKey:@"inputRadius"];
            } else {
                [filter setValue:[NSNumber numberWithFloat:(centerX - .2*centerX)] forKey:@"inputRadius"];
            }
        }
        
        CIImage *outputImage = [filter outputImage];
        
        CGImageRef cgimg =
        [context createCGImage:outputImage fromRect:[outputImage extent]];
        
        UIImage *newImage = [UIImage imageWithCGImage:cgimg scale:1.0 orientation:orientation];
        
        DNWFilteredImageModel* imageModel = [[DNWFilteredImageModel alloc] init];
        imageModel.imageName = (NSString*)key;
        imageModel.filteredImage = newImage;
        
        [self.retVal addObject:imageModel];
        
        CGImageRelease(cgimg);
    }
    context = nil;
}

@end
