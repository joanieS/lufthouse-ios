//
//  StoriesViewController.m
//  lufthouse-ios
//
//  Created by Adam Gleichsner on 7/16/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import "StoriesViewController.h"
#import "Constants.h"

#import <AWSiOSSDKv2/AWSCore.h>
#import <AWSiOSSDKv2/S3.h>

@interface StoriesViewController ()

//Allows recording and audio playback
@property (nonatomic, strong) AVAudioSession *audioSession;
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

//Contains important data about the recording for later use
@property (nonatomic, strong) NSData *audioData;
@property (nonatomic, strong) NSString *audioPath;
@property (nonatomic)   int audioLength;

//S3 upload capability
@property (nonatomic, strong) AWSS3TransferManagerUploadRequest *uploadRequest;

//Timer for countdown display and variable to allow countdown
@property (nonatomic, strong) NSTimer *countdownTimer;
@property (nonatomic) int remainingTicks;

//Keep track of whether or not we should start or stop
@property (nonatomic) BOOL isTiming;

@end

@implementation StoriesViewController

#pragma mark - Setup View

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:true];
    
    //Establish text field manipulation
    self.postTextField.delegate = self;
    
    //Initialize an audio recorder for this controller
    [self initAudioRecorder];
    
    //Create a tap to allow keyboard dismissal
    self.tap = [[UITapGestureRecognizer alloc]
                initWithTarget:self
                action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:self.tap];
    
}

-(void) viewWillAppear:(BOOL)animated
{
    //Make a blue navigation bar
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:242/255.0f green:101/255.0f blue:34/255.0f alpha:1.0f]];
    [self.navigationController.navigationBar setTranslucent:NO];
    self.navigationController.navigationBar.hidden = NO;
    
    //Since we're at a beacon, restrict going back
    self.navBar.backBarButtonItem.enabled = NO;
    self.navBar.hidesBackButton = YES;
    
    [self.timerDisplay setFont:[UIFont fontWithName:@"OpenSans" size:22]];
    
    //We start off not timing
    self.isTiming = false;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - Audio Recording and Controls
- (void)initAudioRecorder
{
    //Create a file to write audio to
    self.audioPath = [[[NSString stringWithFormat:@"%@", NSTemporaryDirectory()] stringByAppendingPathComponent:@"audio"] stringByAppendingPathExtension:@"caf"];
    //Make a URL equivalent for the recorder
    NSURL *soundURL = [[NSURL alloc] initFileURLWithPath:self.audioPath];
    
    NSError *error = nil;
    
    //Should record audio as .wav
    NSDictionary *recordSettings = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                    [NSNumber numberWithFloat: 16000.0],AVSampleRateKey,
                                    [NSNumber numberWithInt: kAudioFormatLinearPCM], AVFormatIDKey,// kAudioFormatLinearPCM
                                    [NSNumber numberWithInt:8],AVLinearPCMBitDepthKey,
                                    [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
                                    [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                                    [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                    [NSNumber numberWithInt: AVAudioQualityHigh],AVEncoderAudioQualityKey,
                                    nil];
    
    //Create an audio session for teh recorder
    self.audioSession = [AVAudioSession sharedInstance];
    [self.audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    [self.audioSession setActive:YES error:&error];
    
    //Creates the recorder
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:soundURL settings:recordSettings error:&error];
    
    if (error)
    {
        NSLog(@"error: %@", [error localizedDescription]);
    } else {
        [self.audioRecorder prepareToRecord];
    }
}

- (IBAction)recordButtonActivate:(id)sender {
    //If we're recording, stop
    if ([self.audioRecorder isRecording]) {
        [self.audioRecorder stop];
        //Get the length of our audio and stop the timer
        self.audioLength = 6000 - self.remainingTicks;
        [self doCountdown: 6000];
        
        //Display our audio clip length
        self.remainingTicks = self.audioLength;
        [self updateLabel];
        
        //Enable/Disable appropriate controls
        self.playButton.enabled = YES;
        self.stopButton.hidden = YES;
        self.deleteButton.enabled = YES;
    } else { //If we want to record
        [self.audioRecorder record];
        //Set a 1 minute limit
        [self doCountdown: 6000];
        
        self.playButton.enabled = NO;
        self.deleteButton.enabled = NO;
        self.stopButton.hidden = NO;
        self.recordButton.hidden = YES;
    }
}

- (IBAction)stopButtonActivate:(id)sender {
    self.stopButton.hidden = YES;
    self.playButton.enabled = YES;
    self.recordButton.hidden = NO;
    self.deleteButton.enabled = YES;
    
    //If we're recording, stop
    if (self.audioRecorder.recording)
    {
        [self.audioRecorder stop];
        [self doCountdown:self.remainingTicks];
        
        //Grab the length of our audio and reset display
        self.audioLength = 6000 - self.remainingTicks;
        self.remainingTicks = self.audioLength;
        [self updateLabel];
        //If we're playing, stop
    } else if (self.audioPlayer.playing) {
        [self.audioPlayer stop];
        //Stop timer and update display
        [self doCountdown:self.remainingTicks];
        self.remainingTicks = self.audioLength;
        [self updateLabel];
    }
}

- (IBAction)playButtonActivate:(id)sender {
    //If we're not recording
    if (!self.audioRecorder.recording)
    {
        self.stopButton.hidden = NO;
        self.recordButton.hidden = YES;
        self.deleteButton.enabled = NO;
        self.playButton.enabled = NO;
        
        NSError *error;
        
        //Create a player using the generic file URL
        self.audioPlayer = [[AVAudioPlayer alloc]
                            initWithContentsOfURL:self.audioRecorder.url
                            error:&error];
        
        self.audioPlayer.delegate = self;
        
        if (error)
            NSLog(@"Error: %@",
                  [error localizedDescription]);
        else {
            //Play and countdown audio length
            [self.audioPlayer play];
            [self doCountdown:self.audioLength];
        }
    }
}

- (IBAction)deleteButtonActivate:(id)sender {
    self.playButton.enabled = NO;
    self.stopButton.hidden = YES;
    self.recordButton.hidden = NO;
    
    //Reset the label
    self.remainingTicks = 6000;
    [self updateLabel];
    //Reset the length
    self.audioLength = 0;
    //Wipe out the recorder
    [self initAudioRecorder];
}

- (IBAction)sendButtonActivate:(id)sender {
    
    NSError *error;
    NSString *oldPathName, *newPathName;
    
    // Create file manager to rename audio.caf
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    //If we have a title AND audio
    if ([self.postTextField.text length] > 0 && self.audioLength > 0) {
        
        //Rename file to slug with title text
        oldPathName = self.audioPath;
        newPathName = [[[NSString stringWithFormat:@"%@", NSTemporaryDirectory()] stringByAppendingPathComponent:self.postTextField.text] stringByAppendingPathExtension:@"caf"];
        if ([fileMgr fileExistsAtPath:oldPathName]) {
            [fileMgr moveItemAtPath: oldPathName toPath:newPathName error:&error];
        }
        
        //Create S3 request
        self.uploadRequest = [AWSS3TransferManagerUploadRequest new];
        self.uploadRequest.bucket = S3BucketName;
        //Puts file in folders separated by customer, tour, and beacon
        self.uploadRequest.key = [NSString stringWithFormat:@"%@/%@/%@/%@.caf", self.custID, self.tourID, self.instID, [self.postTextField.text stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
        self.uploadRequest.body = [[NSURL alloc] initFileURLWithPath:newPathName];
        
        //Set the timer display to a smaller font to display status messages
        [self.timerDisplay setFont:[UIFont fontWithName:@"OpenSans" size:16]];
        self.timerDisplay.text = StatusLabelUploading;
        [self uploadFiles];
    }
    
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
        //If we're recording and we hit zero, we need to stop
        if ([self.audioRecorder isRecording]) {
            [self recordButtonActivate:self];
        }
        //Kill the timer and stop timing
        [self.countdownTimer invalidate];
        self.countdownTimer = nil;
        self.isTiming = false;
        
        self.remainingTicks = self.audioLength;
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

#pragma mark - Keyboard Customization

#define ACCEPTABLE_CHARACTERS @" ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 "

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string  {
    //To make an acceptable slug, we can't have periods or special characters
    NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:ACCEPTABLE_CHARACTERS] invertedSet];
    //Replace every attempted special character with a space
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
    
    return [string isEqualToString:filtered];
}

//Close keyboard on hitting return
-(BOOL) textFieldShouldReturn: (UITextField *) textField {
    [textField resignFirstResponder];
    return YES;
}

//Close keyboard on outside tap
-(void)dismissKeyboard {
    [self.postTextField resignFirstResponder];
}

#pragma mark - AWS S3 Uploading

- (void) uploadFiles {
    //Create the transfer manager to begin
    AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
    
    //UPLOAD NAO
    [[transferManager upload:self.uploadRequest] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
        if (task.error != nil) { //If we did done messed up
            if( task.error.code != AWSS3TransferManagerErrorCancelled
               &&
               task.error.code != AWSS3TransferManagerErrorPaused
               )
            {
                self.timerDisplay.text = StatusLabelFailed;
                NSLog(@"%@", task.error);
            }
        } else { //SUCCESS!!!!!!!!
            self.uploadRequest = nil;
            self.timerDisplay.text = StatusLabelCompleted;
        }
        return nil;
    }];
}

@end
