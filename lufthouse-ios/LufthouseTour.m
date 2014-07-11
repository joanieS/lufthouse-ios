//
//  LufthouseTour.m
//  basic-museum-ios
//
//  Created by Adam Gleichsner on 6/17/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import "LufthouseTour.h"


/* LufthouseTour
 * Object to contain all the beacon IDs, content, content types, and audio associated 
 * with an individual tour. Tour also has a name (hint, it's not Bob).
 * Getter and setter methods are ignored for security, but getter methods to return 
 * content at an index do exist. Since a tour shouldn't be modified after its creation, 
 * we avoid array manipulation. Also includes finder methods to check if a beacon ID is 
 * in the tour.
 */
@implementation LufthouseTour

/* initTourWithName
 * Takes arrays for all values necessary for a tour and creates the object. Returns a 
 * pointer to itself once it's done.
 */
-(LufthouseTour *)initTourWithName: (NSString *) tourName beaconIDArray: (NSMutableArray *) beaconIDs beaconContentArray: (NSMutableArray *) beaconContent beaconContentTypeArray: (NSMutableArray *) beaconContentType beaconAudioArray: (NSMutableArray *) beaconAudio
{
    self.tourName = tourName;
    self.beaconIDs = beaconIDs;
    self.beaconContent = beaconContent;
    self.beaconContentType = beaconContentType;
    self.beaconAudio = beaconAudio;
    
    return self;
}

/* getTourName */
-(NSString *)getTourName
{
    return self.tourName;
}

/* getBeaconIDAtIndex */
-(NSString *)getBeaconIDAtIndex: (NSInteger) index
{
    return [self.beaconIDs objectAtIndex:index];
}

/* getBeaconContentAtIndex */
-(NSString *)getBeaconContentAtIndex: (NSInteger) index
{
    return [self.beaconContent objectAtIndex:index];
}

/* getBeaconContentTypeAtIndex */
-(NSString *)getBeaconContentTypeAtIndex: (NSInteger) index
{
    return [self.beaconContentType objectAtIndex:index];
}

/* getBeaconAudioAtIndex */
-(NSString *)getBeaconAudioAtIndex: (NSInteger) index
{
    return [self.beaconAudio objectAtIndex:index];
}

/* findIndexOfID 
 * Loops through beaconIDs and checks id at index against a search id
 */
-(NSInteger)findIndexOfID: (NSString *) targetID
{
    NSString *checkID;
    //For each beacon in the tour, get the id and check it
    for(NSInteger i = 0; i < [self.beaconIDs count]; i++){
        checkID = [self.beaconIDs objectAtIndex:i];
        if ([checkID isEqualToString:targetID]) {
            return i;
        }
    }
    //If id not found, return an impossible index
    return -1;
}




@end
