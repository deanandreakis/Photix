//
//  DNWFilterViewController.h
//  Photix
//
//  Created by Dean Andreakis on 8/9/14.
//  Copyright (c) 2014 deanware. All rights reserved.
//

//TODO: Turn this into a simple UICollectionView...no need to have a large picture

#import <UIKit/UIKit.h>
//#import "DNWFilterImage.h"
@import PhotixFilter;

@interface DNWFilterViewController : UIViewController <UIScrollViewDelegate, FilteringCompleteDelegate>

@property (strong, nonatomic) UIImage *imageToSet;

@end
