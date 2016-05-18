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
@property (strong, nonatomic) NSMutableDictionary* filterNameDictionaryCI;//lists all the names of the CoreImage filters we use
@property (strong, nonatomic) NSMutableDictionary* filterNameDictionaryCITest;//lists all the names of the CoreImage filters we use
@property (strong, nonatomic) NSArray* guideArray;
@property (strong, nonatomic) NSMutableArray* retVal;
@end

@implementation DNWFilterImage

@synthesize filterDelegate, filterNameDictionary, guideArray, filterNameDictionaryCI, filterNameDictionaryCITest;

- (id) init {
    if (self = [super init]) {
        //NOTE: All strings representing the keys from the filterNameDictionary MUST be present in
        //the guideArray as the guideArray is used to define the order that the filters show up from left
        //to right in the DNWFilterViewController..
        filterNameDictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"GPUImageKuwaharaFilter", @"Oil Paint",
                                 //@"GPUImagePixellateFilter",@"Pixels",
                                 //@"GPUImagePolarPixellateFilter",@"PolarPix",
                                 @"GPUImagePolkaDotFilter",@"Dots",
                                 //@"GPUImageHalftoneFilter",@"HalfTone",
                                 //@"GPUImageCrosshatchFilter",@"Crossy",
                                 @"GPUImageSketchFilter",@"Sketch",
                                 @"GPUImageToonFilter",@"Cartoon",
                                 //@"GPUImageSmoothToonFilter",@"Smoothy",
                                 @"GPUImageEmbossFilter",@"Emboss",
                                 //@"GPUImagePosterizeFilter",@"Poster",
                                 @"GPUImageSwirlFilter",@"Swirly",
                                @"GPUImageBulgeDistortionFilter",@"Bulge",
                                @"GPUImagePinchDistortionFilter",@"Pinch",
                                @"GPUImageStretchDistortionFilter",@"Stretch",
                                //@"GPUImageSphereRefractionFilter",@"Sphere",
                                @"GPUImageGlassSphereFilter",@"Glass",
                                //@"GPUImageVignetteFilter",@"Vignette",
                                //@"GPUImageCGAColorspaceFilter",@"CGA",
                                //@"GPUImageSepiaFilter",@"Sepia",
                                //@"GPUImageiOSBlurFilter",@"Blur",
                                //@"GPUImageColorInvertFilter",@"Invert",
                                //@"GPUImageGrayscaleFilter",@"Gray",
                                //@"GPUImageFalseColorFilter",@"False",
                                //@"GPUImageSoftEleganceFilter",@"Soft",
                                //@"GPUImageHazeFilter",@"Haze",
                                nil];
        
        filterNameDictionaryCI = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                  @"CIAdditionCompositing",@"TEST1",
                                  @"CIAffineClamp",@"TEST2",
                                  @"CIAffineTile",@"TEST3",
                                  @"CIAffineTransform",@"TEST4",
                                  @"CIBarsSwipeTransition",@"TEST5",
                                  @"CIBlendWithAlphaMask",@"TEST6",
                                  @"CIBlendWithMask",@"TEST7",
                                  @"CIBloom",@"TEST8",
                                  @"CIBumpDistortion",@"TEST9",
                                  @"CIBumpDistortionLinear",@"TEST10",
                                  //@"CICheckerboardGenerator",@"TEST11",
                                  @"CICircleSplashDistortion",@"TEST12",
                                  @"CICircularScreen",@"TEST13",
                                  @"CIColorBlendMode",@"TEST14",
                                  @"CIColorBurnBlendMode",@"TEST15",
                                  @"CIColorClamp",@"TEST16",
                                  @"CIColorControls",@"TEST17",
                                  @"CIColorCrossPolynomial",@"TEST18",
                                  @"CIColorCube",@"TEST19",
                                  @"CIColorCubeWithColorSpace",@"TEST20",
                                  @"CIColorDodgeBlendMode",@"TEST21",
                                  @"CIColorInvert",@"TEST22",
                                  @"CIColorMap",@"TEST23",
                                  @"CIColorMatrix",@"TEST24",
                                  @"CIColorMonochrome",@"TEST25",
                                  @"CIColorPolynomial",@"TEST26",
                                  @"CIColorPosterize",@"TEST27",
                                  //@"CIConstantColorGenerator",@"TEST28",
                                  @"CIConvolution3X3",@"TEST29",
                                  @"CIConvolution5X5",@"TEST30",
                                  @"CIConvolution9Horizontal",@"TEST31",
                                  @"CIConvolution9Vertical",@"TEST32",
                                  @"CICopyMachineTransition",@"TEST33",
                                  @"CICrop",@"TEST34",
                                  @"CIDarkenBlendMode",@"TEST35",
                                  @"CIDifferenceBlendMode",@"TEST36",
                                  @"CIDisintegrateWithMaskTransition",@"TEST37",
                                  @"CIDissolveTransition",@"TEST38",
                                  @"CIDotScreen",@"TEST39",
                                  @"CIEightfoldReflectedTile",@"TEST40",
                                  @"CIExclusionBlendMode",@"TEST41",
                                  @"CIExposureAdjust",@"TEST42",
                                  @"CIFalseColor",@"TEST43",
                                  @"CIFlashTransition",@"TEST44",
                                  @"CIFourfoldReflectedTile",@"TEST45",
                                  @"CIFourfoldRotatedTile",@"TEST46",
                                  @"CIFourfoldTranslatedTile",@"TEST47",
                                  @"CIGammaAdjust",@"TEST48",
                                  @"CIGaussianBlur",@"TEST49",
                                  //@"CIGaussianGradient",@"TEST50",
                                  @"CIGlideReflectedTile",@"TEST51",
                                  @"CIGloom",@"TEST52",
                                  @"CIHardLightBlendMode",@"TEST53",
                                  @"CIHatchedScreen",@"TEST54",
                                  @"CIHighlightShadowAdjust",@"TEST55",
                                  @"CIHoleDistortion",@"TEST56",
                                  @"CIHueAdjust",@"TEST57",
                                  @"CIHueBlendMode",@"TEST58",
                                  @"CILanczosScaleTransform",@"TEST59",
                                  @"CILightenBlendMode",@"TEST60",
                                  @"CILightTunnel",@"TEST61",
                                  //@"CILinearGradient",@"TEST62",
                                  @"CILinearToSRGBToneCurve",@"TEST63",
                                  @"CILineScreen",@"TEST64",
                                  @"CILuminosityBlendMode",@"TEST65",
                                  @"CIMaskToAlpha",@"TEST66",
                                  @"CIMaximumComponent",@"TEST67",
                                  @"CIMaximumCompositing",@"TEST68",
                                  @"CIMinimumComponent",@"TEST69",
                                  @"CIMinimumCompositing",@"TEST70",
                                  @"CIModTransition",@"TEST71",
                                  @"CIMultiplyBlendMode",@"TEST72",
                                  @"CIMultiplyCompositing",@"TEST73",
                                  @"CIOverlayBlendMode",@"TEST74",
                                  @"CIPhotoEffectChrome",@"TEST75",
                                  @"CIPhotoEffectFade",@"TEST76",
                                  @"CIPhotoEffectInstant",@"TEST77",
                                  @"CIPhotoEffectMono",@"TEST78",
                                  @"CIPhotoEffectNoir",@"TEST79",
                                  @"CIPhotoEffectProcess",@"TEST80",
                                  @"CIPhotoEffectTonal",@"TEST81",
                                  @"CIPhotoEffectTransfer",@"TEST82",
                                  @"CIPinchDistortion",@"TEST83",
                                  @"CIPixellate",@"TEST84",
                                  //@"CIQRCodeGenerator",@"TEST85",
                                  //@"CIRadialGradient",@"TEST86",
                                  //@"CIRandomGenerator",@"TEST87",
                                  @"CISaturationBlendMode",@"TEST88",
                                  @"CIScreenBlendMode",@"TEST89",
                                  @"CISepiaTone",@"TEST90",
                                  @"CISharpenLuminance",@"TEST91",
                                  @"CISixfoldReflectedTile",@"TEST92",
                                  @"CISixfoldRotatedTile",@"TEST93",
                                  //@"CISmoothLinearGradient",@"TEST94",
                                  @"CISoftLightBlendMode",@"TEST95",
                                  @"CISourceAtopCompositing",@"TEST96",
                                  @"CISourceInCompositing",@"TEST97",
                                  @"CISourceOutCompositing",@"TEST98",
                                  @"CISourceOverCompositing",@"TEST99",
                                  @"CISRGBToneCurveToLinear",@"TEST100",
                                  //@"CIStarShineGenerator",@"TEST101",
                                  @"CIStraightenFilter",@"TEST102",
                                  //@"CIStripesGenerator",@"TEST103",
                                  @"CISwipeTransition",@"TEST104",
                                  @"CITemperatureAndTint",@"TEST105",
                                  @"CIToneCurve",@"TEST106",
                                  @"CITriangleKaleidoscope",@"TEST107",
                                  @"CITwelvefoldReflectedTile",@"TEST108",
                                  @"CITwirlDistortion",@"TEST109",
                                  @"CIUnsharpMask",@"TEST110",
                                  @"CIVibrance",@"TEST111",
                                  @"CIVignette",@"TEST112",
                                  @"CIVignetteEffect",@"TEST113",
                                  @"CIVortexDistortion",@"TEST114",
                                  @"CIWhitePointAdjust",@"TEST115",
                                  nil];
        
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
        
        guideArray = [[NSArray alloc] initWithObjects:@"Oil Paint",@"Blur",@"Pixels",@"PolarPix",@"Dots",@"HalfTone",@"Crossy",
                      @"Sketch",@"Cartoon",@"Smoothy",@"Emboss",@"Poster",@"Swirly",@"Bulge",@"Pinch",@"Stretch",
                      @"Sphere",@"Glass",@"Vignette",@"CGA",@"Sepia",@"Invert",@"Gray",@"False",@"Soft",@"Haze",nil];
        
        self.retVal = [NSMutableArray array];
    }
    return self;
}

-(void)filterImage:(UIImage*)imageToFilter
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        DNWFilteredImageModel* imageModel = [[DNWFilteredImageModel alloc] init];
        imageModel.imageName = @"Original";
        imageModel.filteredImage = imageToFilter;
        [self.retVal addObject:imageModel];
        
        [self processGPUImageFilters:imageToFilter];
        
        [self processCoreImageFilters:imageToFilter];
        
        /*[retVal sortUsingComparator:^(id o1, id o2) {
            DNWFilteredImageModel *item1 = o1;
            DNWFilteredImageModel *item2 = o2;
            NSInteger idx1 = [guideArray indexOfObject:item1.imageName];
            NSInteger idx2 = [guideArray indexOfObject:item2.imageName];
            return idx1 - idx2;
        }];*/
        
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
    
    /*for (NSString *name in [CIFilter filterNamesInCategory:kCICategoryBuiltIn])
    {
        CIFilter *filter = [CIFilter filterWithName:name];
        
        NSArray* ikeys = [filter inputKeys];
        NSLog(@"FILTER NAMES: %@", name);
        
        if([ikeys containsObject:@"inputImage"]){
            [filter setValue:beginImage forKey:kCIInputImageKey];
            
            CIImage *outputImage = [filter outputImage];
            
            CGImageRef cgimg =
            [context createCGImage:outputImage fromRect:[outputImage extent]];
            
            UIImage *newImage = [UIImage imageWithCGImage:cgimg scale:1.0 orientation:orientation];
            
            DNWFilteredImageModel* imageModel = [[DNWFilteredImageModel alloc] init];
            imageModel.imageName = name;
            imageModel.filteredImage = newImage;
            
            [self.retVal addObject:imageModel];
            
            CGImageRelease(cgimg);
        }
    }*/
    
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
            
            //NSArray* ikeys = [filter inputKeys];
            //NSLog(@"KEYS: %@", ikeys);
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
    
}


- (void)processGPUImageFilters:(UIImage*)imageToFilter
{
        UIImage* newImage = imageToFilter;
        
        UIImage *currentFilteredImage;
    
        /*GPUImageKuwaharaFilter *oilPaintingTransformFilter = [[GPUImageKuwaharaFilter alloc] init];
        oilPaintingTransformFilter.radius = 6.0;
    
        currentFilteredImage = [oilPaintingTransformFilter imageByFilteringImage:newImage];
    
        DNWFilteredImageModel* imageModel = [[DNWFilteredImageModel alloc] init];
        imageModel.imageName = @"Oil Paint";
        imageModel.filteredImage = currentFilteredImage;
    
        [self.retVal addObject:imageModel];*/
    
        for (id key in filterNameDictionary) {
            
            NSString* filterName = (NSString*)filterNameDictionary[key];
            Class filterClass = NSClassFromString(filterName);
            
            id oilPaintingTransformFilter = [[filterClass alloc] init];
            currentFilteredImage = [oilPaintingTransformFilter imageByFilteringImage:newImage];
            
            DNWFilteredImageModel* imageModel = [[DNWFilteredImageModel alloc] init];
            imageModel.imageName = (NSString*)key;
            imageModel.filteredImage = currentFilteredImage;
            
            [self.retVal addObject:imageModel];
        }
}

@end
