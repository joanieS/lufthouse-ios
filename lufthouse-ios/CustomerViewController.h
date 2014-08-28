//
//  ToursViewController.h
//  lufthouse-ios
//
//  Created by Adam Gleichsner on 7/10/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

//The only delegate that this controller isn't is a UN delegate
//*Dun dun chh*

@interface CustomerViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, NSURLConnectionDelegate>

//Table for display
@property (weak, nonatomic) IBOutlet UITableView *customerTableView;
@property (weak, nonatomic) IBOutlet UIImageView *fillerImage;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *waiting;
@property (weak, nonatomic) IBOutlet UILabel *noContent;

@end
