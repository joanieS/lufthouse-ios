//
//  ViewController.h
//  basic-museum-ios
//
//  Created by Adam Gleichsner on 6/5/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import <UIKit/UIKit.h>
/* Audio playing capability */
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


@interface WebContentViewController : UIViewController<UIWebViewDelegate>

//Web view and loading image
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *waiting;

//Input segue data
@property (nonatomic, strong) NSURL *segueContentURL;
@property (nonatomic, strong) NSString *segueContentHTML;




@end
