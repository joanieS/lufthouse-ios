//
//  CustomerTableViewCell.h
//  lufthouse-ios
//
//  Created by Adam Gleichsner on 8/27/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomerTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *subtitle;

@end
