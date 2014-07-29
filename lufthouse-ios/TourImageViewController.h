//
//  TourImageViewController.h
//  lufthouse-ios
//
//  Created by Adam Gleichsner on 7/10/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioServices.h>

/* JSON Parsing */
#import <Foundation/NSJSONSerialization.h>

/* Estimote managing */
#import "ESTBeacon.h"
#import "ESTBeaconManager.h"
#import "ESTBeaconRegion.h"

/* Parsing and storing information */
#import "LufthouseTour.h"

#import "MWPhotoBrowser.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface TourImageViewController : UIViewController<ESTBeaconManagerDelegate , MWPhotoBrowserDelegate, CBCentralManagerDelegate>

//Display image for tour
@property (strong, nonatomic) IBOutlet UIImageView *tourLandingImage;
@property (nonatomic, strong) NSData *tourLandingImageData;

//Data for MWPhotoBrowser
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSMutableArray *thumbs;

//Info to further pass to StoriesViewController
@property (nonatomic, strong) NSString *customerID;
@property (nonatomic, strong) NSString *tourID;

@end
