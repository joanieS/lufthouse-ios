//
//  MemoriesViewController.h
//  lufthouse-ios
//
//  Created by Adam Gleichsner on 7/29/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioServices.h>

@interface MemoriesViewController : UIViewController <AVAudioPlayerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *currentTagLine;
@property (weak, nonatomic) IBOutlet UILabel *nextTagLine;
@property (weak, nonatomic) IBOutlet UILabel *timerDisplay;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet UIButton *resumeButton;

@property (strong, nonatomic) NSData *firstMemory;
@property (strong, nonatomic) NSData *secondMemory;
@property (strong, nonatomic) NSArray *memories;

@end
