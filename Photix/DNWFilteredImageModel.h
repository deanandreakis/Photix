//
//  DNWFilteredImageModel.h
//  Photix
//
//  Legacy compatibility header - functionality migrated to Swift
//  This file exists only for build compatibility and will be removed
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DNWFilteredImageModel : NSObject

@property (strong, nonatomic) UIImage *filteredImage;
@property (strong, nonatomic) NSString *imageName;

@end