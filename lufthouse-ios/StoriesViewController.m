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
#import <AWSiOSSDKv2/DynamoDB.h>
#import <AWSiOSSDKv2/SQS.h>
#import <AWSiOSSDKv2/SNS.h>
#import <AWSiOSSDKv2/AmazonCore.h>

@interface StoriesViewController ()

@property (nonatomic, strong) AVAudioSession *audioSession;
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

@property (nonatomic, strong) NSData *audioData;
@property (nonatomic, strong) NSURL *audioURL;

@property (nonatomic, strong) NSMutableData *receivedData;

@property (nonatomic, strong) AWSS3TransferManagerUploadRequest *uploadRequest;

@property (nonatomic, strong) NSURL *testFileURL;

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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:true];
    
    self.testFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:S3KeyUploadName]];
    
    self.postTextField.delegate = self;
    
    NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    NSURL *soundURL = [[tmpDirURL URLByAppendingPathComponent:@"audio"] URLByAppendingPathExtension:@".caf"];
    self.audioURL = soundURL;
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
    
    __weak typeof(self) weakSelf = self;
    
    self.uploadRequest = [AWSS3TransferManagerUploadRequest new];
    self.uploadRequest.bucket = S3BucketName;
    self.uploadRequest.key = [NSString stringWithFormat:@"%@/%@/%@/%@.caf", self.custID, self.tourID, self.instID, [self.postTextField.text stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
    self.uploadRequest.body = self.audioURL;
//    self.uploadRequest.uploadProgress =  ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend){
//        dispatch_sync(dispatch_get_main_queue(), ^{
//            weakSelf.file1AlreadyUpload = totalBytesSent;
//            [weakSelf updateProgress];
//        });
//    };

    self.uploadStatusLabel.text = StatusLabelUploading;
    [self uploadFiles];
    
    
//    
//    NSMutableURLRequest *audioPostRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://lufthouse-cms.herokuapp.com/location/%@", nil]]];
//    [audioPostRequest setHTTPMethod:@"POST"];
//    [audioPostRequest setValue:@"audio-recording" forHTTPHeaderField:@"Content-Type"];
//    [audioPostRequest setHTTPBody:audioData];
//    
//    NSURLConnection *connection = [NSURLConnection connectionWithRequest:audioPostRequest delegate:self];
//    self.receivedData = [NSMutableData dataWithCapacity: 0];
//    if (!connection) {
//        // Release the receivedData object.
//        self.receivedData = nil;
//        
//        // Inform the user that the connection failed.
//    }
}

//- (IBAction)commentDidEnter:(id)sender {
//    [self.postTextField resignFirstResponder];
//}

#define ACCEPTABLE_CHARACTERS @" ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 "

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string  {
    NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:ACCEPTABLE_CHARACTERS] invertedSet];
    
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
    
    return [string isEqualToString:filtered];
}

-(BOOL) textFieldShouldReturn: (UITextField *) textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - AWS S3 Uploading

- (void) uploadFiles {
    AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
    
    __block int uploadCount = 0;
    [[transferManager upload:self.uploadRequest] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
        if (task.error != nil) {
            if( task.error.code != AWSS3TransferManagerErrorCancelled
               &&
               task.error.code != AWSS3TransferManagerErrorPaused
               )
            {
                self.uploadStatusLabel.text = StatusLabelFailed;
            }
        } else {
            self.uploadRequest = nil;
            self.uploadStatusLabel.text = StatusLabelCompleted;
        }
        return nil;
    }];
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
