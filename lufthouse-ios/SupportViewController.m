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

    NSURL *supportURL = [NSURL URLWithString:@"http://www.lufthouse.com/support"];
    NSURLRequest *supportRequest = [NSURLRequest requestWithURL:supportURL];
    [self.webView loadRequest:supportRequest];
}

@end
