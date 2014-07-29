//
//  NavigationController.m
//  basic-museum-ios
//
//  Created by Adam Gleichsner on 6/27/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import "NavigationController.h"

@interface NavigationController ()

@end

@implementation NavigationController


#pragma mark - Setup navigation bar
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    //Start navigation bar as Lufthouse-branded blue
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:0/255.0f green:87/255.0f blue:141/255.0f alpha:1.0f]];
    [self.navigationController.navigationBar setTranslucent:NO];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate
{
    return [self.visibleViewController shouldAutorotate];
}



@end
