//
//  AppDelegate.h
//  lufthouse-ios
//
//  Created by Adam Gleichsner on 7/10/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import <UIKit/UIKit.h>

//For AWS S3 authentication and use
#import "Constants.h"
#import <AWSiOSSDKv2/AWSCore.h>
#import <AWSiOSSDKv2/AWSCredentialsProvider.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
