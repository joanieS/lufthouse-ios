//
//  CSTMovingAverage.m
//  lufthouse-ios
//
//  Created by Randy Beiter on 12/15/14.
//  Copyright (c) 2014 Castable. All rights reserved.
//

#import "CSTMovingAverage.h"

@implementation CSTMovingAverage

- (id)initWithSize:(int)size {
    if (self = [super init]) {
        samples = [[NSMutableArray alloc] initWithCapacity:size];
        sampleCount = 0;
        averageSize = size;
    }
    return self;
}

- (void)addSample:(double)sample {
    int pos = fmodf(sampleCount++, (float)averageSize);
    [samples setObject:[NSNumber numberWithDouble:sample] atIndexedSubscript:pos];
}

- (double)movingAverage {
    return [[samples valueForKeyPath:@"@sum.doubleValue"] doubleValue]/(sampleCount > averageSize-1?averageSize:sampleCount);
}

@end
