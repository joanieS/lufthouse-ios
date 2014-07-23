//
//  LufthouseTour.h
//  basic-museum-ios
//
//  Created by Adam Gleichsner on 6/17/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LufthouseTour : NSObject

@property (nonatomic, strong) NSString *tourName;
@property (nonatomic, strong) NSMutableArray *beaconIDs;
@property (nonatomic, strong) NSMutableArray *beaconContent;
@property (nonatomic, strong) NSMutableArray *beaconContentType;
@property (nonatomic, strong) NSMutableArray *beaconAudio;
@property (nonatomic, strong) NSMutableArray *installationID;

/* Create a tour with all relevant data */
-(LufthouseTour *)initTourWithName: (NSString *) tourName beaconIDArray: (NSMutableArray *) beaconIDs beaconContentArray: (NSMutableArray *) beaconContent beaconContentTypeArray:(NSMutableArray *) beaconContentType beaconAudioArray: (NSMutableArray *) beaconAudio installationIDArray: (NSMutableArray *) installationID;

/* Get aspects of the tour */
-(NSString *)getTourName;
-(NSString *)getBeaconIDAtIndex: (NSInteger) index;
-(NSString *)getBeaconContentAtIndex: (NSInteger) index;
-(NSString *)getBeaconContentTypeAtIndex: (NSInteger) index;
-(NSString *)getBeaconAudioAtIndex: (NSInteger) index;
-(NSString *)getInstallationIDAtIndex: (NSInteger) index;

/* Check if a beacon belongs to the tour and where it is in said tour */
-(NSInteger)findIndexOfID: (NSString *) targetID;

@end
