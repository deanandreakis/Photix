//
//  PhotoEditingViewController.h
//  OilPaintPlus
//
//  Created by Dean Andreakis on 8/19/14.
//  Copyright (c) 2014 deanware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreImage/CoreImage.h>

// Simple filtered image model for extension
@interface SimpleFilteredImageModel : NSObject
@property (strong, nonatomic) UIImage* filteredImage;
@property (strong, nonatomic) NSString* imageName;
@end

@interface PhotoEditingViewController : UIViewController <UIScrollViewDelegate>

@end
