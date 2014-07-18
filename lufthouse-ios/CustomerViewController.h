//
//  ToursViewController.h
//  lufthouse-ios
//
//  Created by Adam Gleichsner on 7/10/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface CustomerViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, NSURLConnectionDelegate>

@property (weak, nonatomic) IBOutlet UITableView *customerTableView;

@end
