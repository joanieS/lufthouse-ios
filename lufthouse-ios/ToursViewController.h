//
//  ToursViewController.h
//  lufthouse-ios
//
//  Created by Adam Gleichsner on 7/10/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ToursViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>

//Passed in content from CustomerViewController
@property (nonatomic, strong) NSArray *tableContent;

//Visual items
@property (weak, nonatomic) IBOutlet UILabel *customerName;
@property (weak, nonatomic) IBOutlet UILabel *numberOfTours;
@property (weak, nonatomic) IBOutlet UITableView *toursTableView;

@end
