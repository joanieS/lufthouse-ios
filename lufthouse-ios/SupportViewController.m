//
//  SupportViewController.m
//  lufthouse-ios
//
//  Created by Adam Gleichsner on 8/1/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import "SupportViewController.h"

@interface SupportViewController ()

@end

@implementation SupportViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.webView.delegate = self;

    NSURL *supportURL = [NSURL URLWithString:@"http://www.lufthouse.com/support"];
    NSURLRequest *supportRequest = [NSURLRequest requestWithURL:supportURL];
    [self.webView loadRequest:supportRequest];
}


-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"%@", error);
}


/* webViewDidStartLoad
 * Provides loading animation
 */
- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self.waiting startAnimating];
    self.waiting.hidden = FALSE;
}

/* webViewDidFinishLoad
 * Stops loading animation
 */
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.waiting stopAnimating];
    self.waiting.hidden = TRUE;
}

@end
