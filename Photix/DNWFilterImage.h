//
//  DNWFilterImage.h
//  Photix
//
//  Created by Dean Andreakis on 8/10/14.
//  Copyright (c) 2014 deanware. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FilteringCompleteDelegate <NSObject>

-(void)filteringComplete:(NSArray*)filteredImages;//array of filtered images DNWFilteredImageModel

@end

@interface DNWFilterImage : NSObject

- (void)filterImage:(UIImage*)imageToFilter;
@property (nonatomic, strong) id <FilteringCompleteDelegate> filterDelegate;

@end
