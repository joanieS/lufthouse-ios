//
//  StoriesViewController.h
//  lufthouse-ios
//
//  Created by Adam Gleichsner on 7/16/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>



@interface StoriesViewController : UIViewController <AVAudioPlayerDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *postTextField;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@property (nonatomic, weak) NSString *custID;
@property (nonatomic, weak) NSString *tourID;
@property (nonatomic, weak) NSString *instID;

@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tap;
@property (weak, nonatomic) IBOutlet UILabel *timerDisplay;
@property (weak, nonatomic) IBOutlet UINavigationItem *navBar;

@end
