//
//  CSTBeaconManager.h
//  lufthouse-ios
//
//  Created by Randy Beiter on 12/15/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import <Foundation/Foundation.h>

/* Estimote managing */
#import "ESTBeacon.h"
#import "ESTBeaconManager.h"
#import "ESTBeaconRegion.h"

@interface CSTBeaconManager : NSObject

+ (instancetype)sharedManager;

@end
