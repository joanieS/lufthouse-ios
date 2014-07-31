//
//  MemoriesViewController.m
//  lufthouse-ios
//
//  Created by Adam Gleichsner on 7/29/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import "MemoriesViewController.h"

@interface MemoriesViewController ()

//Audio player for playing mp3 files at exhibits
@property (nonatomic, strong) AVAudioPlayer     *audioPlayer;
@property (nonatomic) int currentMemoryIndex;
//Keep track of whether or not we should start or stop
@property (nonatomic) BOOL isTiming;

//Timer for countdown display and variable to allow countdown
@property (nonatomic, strong) NSTimer *countdownTimer;
@property (nonatomic) int remainingTicks;

@end

@implementation MemoriesViewController

#pragma mark - UI Setup and generation
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Setup the timer and the playlist
    self.currentMemoryIndex = 0;
    [self.timerDisplay setFont:[UIFont fontWithName:@"OpenSans" size:22]];
    
    //BEGIN THE PROCEDURE
    [self reminisce];
}


/*  createRealTitle
 *  Helper method to pull the title from the url and replace underscores in the slug with spaces
 */
- (NSString *) createRealTitle: (NSString *) rawTitle
{
    //Find where the last forward slash is
    NSRange startOfRange = [rawTitle rangeOfString:@"/" options:NSBackwardsSearch];
    
    //Truncate the url from after the last slash up to before the file extension
    return [[rawTitle substringWithRange:NSMakeRange(startOfRange.location + 1, [rawTitle length] - startOfRange.location - 5)] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    
}

#pragma mark - Audio (Memory) Playback
/*  reminisce
 *  In case you missed the theme, this controller is playing back audio files of people talking about their memories, so
 *  listening them is essentially "reminiscing"
 */
- (void)reminisce
{
    //Write the title to the main line
    self.currentTagLine.text = [self createRealTitle:self.memories[self.currentMemoryIndex]];
    
    //If we're on the last memory
    if (self.currentMemoryIndex + 1 >= [self.memories count]) {
        //Hide the next stuff
        self.nextTagLine.hidden = YES;
        self.nextButton.hidden = YES;
    } else {
        //Print out the next title
        self.nextTagLine.text = [self createRealTitle:self.memories[self.currentMemoryIndex + 1]];
    }
    
    //Setup the audio player
    [self.audioPlayer stop];
    self.audioPlayer.currentTime = 0;
    [self.audioPlayer prepareToPlay];
    self.audioPlayer.volume = 1.0;
    
    NSError *error;
    if (self.currentMemoryIndex < [self.memories count]) {
        self.audioPlayer = nil;
        self.audioPlayer = [[AVAudioPlayer alloc] initWithData:self.firstMemory error:&error];
        self.audioPlayer.delegate = self;
        self.audioPlayer.numberOfLoops = 0; //Don't loop
        
        //If everything went fine, play the audio and start a visual countdown
        if (self.audioPlayer == nil)
            NSLog(@"%@", [error description]);
        else
            [self doCountdown:self.audioPlayer.duration*100];
            [self.audioPlayer play];
    }
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    //When we finish a memory, load up the next one
    self.currentMemoryIndex++;
    //If we're not on the last memory
    if (self.currentMemoryIndex < [self.memories count]) {
        self.firstMemory = self.secondMemory;
        //If we have a next memory
        if (self.currentMemoryIndex + 1 < [self.memories count]) {
            self.secondMemory = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:self.memories[self.currentMemoryIndex + 1]]];
        } else {
            self.secondMemory = nil;
        }
        [self reminisce];
    }
}


#pragma mark - Playback Functions

- (IBAction)skipToNextMemory:(id)sender {
    //Queue up the next memory
    self.currentMemoryIndex++;
    self.firstMemory = self.secondMemory;
    //If we still have a next memory
    if (self.currentMemoryIndex + 1 < [self.memories count]) {
        self.secondMemory = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:self.memories[self.currentMemoryIndex + 1]]];
    } else {
        self.secondMemory = nil;
    }
    [self reminisce];
}

//Resume on pause - duh
- (IBAction)resumeButton:(id)sender {
    self.pauseButton.hidden = false;
    self.resumeButton.hidden = true;
    
    [self.audioPlayer play];
    [self doCountdown:self.remainingTicks];
}

//Pause the current memory - double duh
- (IBAction)pauseButton:(id)sender {
    self.pauseButton.hidden = true;
    self.resumeButton.hidden = false;
    
    [self.audioPlayer pause];
    [self doCountdown:self.remainingTicks];
}

#pragma mark - Timer Controls and Display

-(void)doCountdown:(int)remainingTicks
{
    //If we aren't timing, start
    if (!self.isTiming) {
        //In case we've already sent a file
        [self.timerDisplay setFont:[UIFont fontWithName:@"OpenSans" size:22]];
        //Setup for visual countdown
        self.remainingTicks = remainingTicks;
        [self updateLabel];
        self.isTiming = true;
        
        //Begin counting
        self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval: .01 target: self selector: @selector(handleTimerTick) userInfo: nil repeats: YES];
    } else {
        //Stop the clock!
        self.isTiming = false;
        [self.countdownTimer invalidate];
    }
}

-(void)handleTimerTick
{
    //If we're timing and haven't hit zero, decrement
    if (self.isTiming && self.remainingTicks > 0) {
        self.remainingTicks = self.remainingTicks - 1;
        [self updateLabel];
    } else {
        //Kill the timer and stop timing
        [self.countdownTimer invalidate];
        self.countdownTimer = nil;
        self.isTiming = false;
        
        [self updateLabel];
    }
}

-(void)updateLabel
{
    //Calculate total remaining minutes, seconds, and milliseconds
    int total = self.remainingTicks;
    
    int minutes = floor(total / 6000);
    total = total - minutes * 6000;
    
    int seconds = floor(total / 100);
    total = total - seconds * 100;
    
    int milliseconds = total;
    
    //Display content like a stopwatch
    self.timerDisplay.text = [NSString stringWithFormat:@"%02d:%02d:%02d", minutes, seconds, milliseconds];
}

@end
