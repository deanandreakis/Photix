//
//  SimpleFilteredImageModel.h
//  OilPaintPlus
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SimpleFilteredImageModel : NSObject

@property (strong, nonatomic) UIImage* filteredImage;
@property (strong, nonatomic) NSString* imageName;

@end