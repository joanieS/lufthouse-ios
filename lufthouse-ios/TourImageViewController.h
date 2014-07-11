//
//  TourImageViewController.h
//  lufthouse-ios
//
//  Created by Adam Gleichsner on 7/10/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TourImageViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIImageView *tourLandingImage;
@property (nonatomic, strong) NSData *tourLandingImageData;

@end
