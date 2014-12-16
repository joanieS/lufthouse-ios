//
//  CSTMovingAverage.h
//  lufthouse-ios
//
//  Created by Randy Beiter on 12/15/14.
//  Copyright (c) 2014 Castable. All rights reserved.
//

// http://stackoverflow.com/a/16171711/841625

#import <Foundation/Foundation.h>

@interface CSTMovingAverage : NSObject {
    NSMutableArray *samples;
    int sampleCount;
    int averageSize;
}

- (id)initWithSize:(int)size;
- (void)addSample:(double)sample;
- (double)movingAverage;

@end
