//
//  DNWInstagram.h
//  Photix
//
//  Created by Dean Andreakis on 8/2/15.
//  Copyright (c) 2015 deanware. All rights reserved.
//

#import "MGInstagram.h"

@interface DNWInstagram : MGInstagram

+ (void) postImage:(UIImage*)image withBarItem:(UIBarButtonItem*)barItem inView:(UIView*)view;

@end
