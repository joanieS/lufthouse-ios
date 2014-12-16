//
//  CSTBeaconManager.m
//  lufthouse-ios
//
//  Created by Randy Beiter on 12/15/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import "CSTBeaconManager.h"

@interface CSTBeaconManager() <ESTBeaconManagerDelegate>

@property (nonatomic, strong) ESTBeaconManager  *beaconManager;
@property (nonatomic, strong) ESTBeaconRegion   *beaconRegion;

@end

@implementation CSTBeaconManager

+ (instancetype)sharedManager {
    static CSTBeaconManager *sharedManager = nil;
    
    if (sharedManager == nil) {
        static dispatch_once_t safe;
        dispatch_once(&safe, ^{
            sharedManager = [[CSTBeaconManager alloc] init];
        });
    }
    
    return sharedManager;
}

- (instancetype)init {
    if ((self = [super init]) != nil) {
        [self createBeaconManager];
//        [self startMonitoring];
    }

    return self;
}

- (void)createBeaconManager {
    CBCentralManager *bluetoothManager = [[CBCentralManager alloc] init];
    bluetoothManager = nil;
    
    self.beaconManager = [[ESTBeaconManager alloc] init];
    self.beaconManager.delegate = self;
    
    // Create a region to search for beacons
    self.beaconRegion = [[ESTBeaconRegion alloc] initWithProximityUUID:ESTIMOTE_PROXIMITY_UUID
                                                            identifier:@"RegionIdentifier"];
    
//    @try {
        [self.beaconManager startMonitoringForRegion:self.beaconRegion];
        [self.beaconManager startRangingBeaconsInRegion:self.beaconRegion];
// FIXME: re-institute error handling in manager's delegate
//    } @catch (NSException *exception) {
//        NSLog(@"%@", exception.reason);
//        [self createErrorPopupWithMessage:@"Uh-oh!"
//                              bodyMessage:@"It looks like your bluetooth is either off or not cooperating. Please make sure it's on and try again!"];
//    }
}

//- (void)startMonitoring {
//    @try {
//        [self.beaconManager startMonitoringForRegion:self.beaconRegion];
//        [self.beaconManager startRangingBeaconsInRegion:self.beaconRegion];
// FIXME: re-institute error handling in manager's delegate
//    }
//    @catch (NSException *exception) {
//        NSLog(@"Beacon Manager not initialized");
//    }
//}

#pragma mark - ESTBeaconManagerDelegate methods

- (void)beaconManager:(ESTBeaconManager *)manager
      didRangeBeacons:(NSArray *)beacons
             inRegion:(ESTBeaconRegion *)region {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CSTBeaconManagerDidRangeBeacons"
                                                        object:nil
                                                      userInfo:@{@"beacons": beacons}];
}

@end
