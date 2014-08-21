//
//  SupportViewController.h
//  lufthouse-ios
//
//  Created by Adam Gleichsner on 8/1/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SupportViewController : UIViewController <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *waiting;
@end
