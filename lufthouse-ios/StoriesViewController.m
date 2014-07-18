//
//  StoriesViewController.m
//  lufthouse-ios
//
//  Created by Adam Gleichsner on 7/16/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import "StoriesViewController.h"

@interface StoriesViewController ()

@property (nonatomic, strong) AVAudioSession *audioSession;
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

@property (nonatomic, strong) NSData *audioData;
@property (nonatomic, strong) NSString *audioDataPath;

@property (nonatomic, strong) NSMutableData *receivedData;

@end

@implementation StoriesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.postTextField.delegate = self;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *soundDir = paths[0];
    NSString *soundPath = [soundDir stringByAppendingPathComponent:@"sound.wav"];
    NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
    self.audioDataPath = soundPath;
    NSError *error = nil;
    NSDictionary *recordSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:kAudioFormatMPEG4AAC], AVFormatIDKey,
                                    [NSNumber numberWithInt:AVAudioQualityMin], AVEncoderAudioQualityKey,
                                    [NSNumber numberWithInt:16], AVEncoderBitRateKey,
                                    [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
                                    [NSNumber numberWithFloat:8000.0], AVSampleRateKey,
                                    [NSNumber numberWithInt:8], AVLinearPCMBitDepthKey,
                                    nil];
    
    self.audioSession = [AVAudioSession sharedInstance];
    [self.audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [self.audioSession setActive:YES error:nil];
    
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:soundURL settings:recordSettings error:&error];
    
    if (error)
    {
        NSLog(@"error: %@", [error localizedDescription]);
    } else {
        [self.audioRecorder prepareToRecord];
    }

}
- (IBAction)recordButtonActivate:(id)sender {
    if ([self.audioRecorder isRecording]) {
        [self.audioRecorder stop];
        self.playButton.enabled = YES;
        self.stopButton.enabled = NO;
    } else {
        [self.audioRecorder record];
        self.playButton.enabled = NO;
        self.stopButton.enabled = YES;
    }
}
- (IBAction)playButtonActivate:(id)sender {
    if (!self.audioRecorder.recording)
    {
        self.stopButton.enabled = YES;
        self.recordButton.enabled = NO;
        
        NSError *error;
        
        self.audioPlayer = [[AVAudioPlayer alloc]
                        initWithContentsOfURL:self.audioRecorder.url
                        error:&error];
        
        self.audioPlayer.delegate = self;
        
        if (error)
            NSLog(@"Error: %@",
                  [error localizedDescription]);
        else
            [self.audioPlayer play];
    }
}
- (IBAction)stopButtonActivate:(id)sender {
    self.stopButton.enabled = NO;
    self.playButton.enabled = YES;
    self.recordButton.enabled = YES;
    
    if (self.audioRecorder.recording)
    {
        [self.audioRecorder stop];
    } else if (self.audioPlayer.playing) {
        [self.audioPlayer stop];
    }
}

- (IBAction)sendButtonActivate:(id)sender {
    
    NSData *audioData = [[NSData alloc] initWithContentsOfFile:self.audioDataPath];
    
    NSMutableURLRequest *audioPostRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://lufthouse-cms.herokuapp.com/location/%@", nil]]];
    [audioPostRequest setHTTPMethod:@"POST"];
    [audioPostRequest setValue:@"audio-recording" forHTTPHeaderField:@"Content-Type"];
    [audioPostRequest setHTTPBody:audioData];
    
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:audioPostRequest delegate:self];
    self.receivedData = [NSMutableData dataWithCapacity: 0];
    if (!connection) {
        // Release the receivedData object.
        self.receivedData = nil;
        
        // Inform the user that the connection failed.
    }
}

//- (IBAction)commentDidEnter:(id)sender {
//    [self.postTextField resignFirstResponder];
//}

-(BOOL) textFieldShouldReturn: (UITextField *) textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
