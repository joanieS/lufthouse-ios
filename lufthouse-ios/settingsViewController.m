//
//  settingsViewController.m
//  lufthouse-ios
//
//  Created by Adam Gleichsner on 7/29/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import "settingsViewController.h"

@interface settingsViewController ()

@end

@implementation settingsViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewDidLoad];
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:0/255.0f green:87/255.0f blue:141/255.0f alpha:1.0f]];
    [self.navigationController.navigationBar setTranslucent:NO];
    self.navigationController.navigationBar.hidden = NO;
}


@end
