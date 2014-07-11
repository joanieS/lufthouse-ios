//
//  ToursViewController.h
//  lufthouse-ios
//
//  Created by Adam Gleichsner on 7/10/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ToursViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSArray *tableContent;
@property (weak, nonatomic) IBOutlet UILabel *customerName;
@property (weak, nonatomic) IBOutlet UITableView *toursTableView;

@end
