//
//  CustomerTableViewCell.m
//  lufthouse-ios
//
//  Created by Adam Gleichsner on 8/27/14.
//  Copyright (c) 2014 Lufthouse. All rights reserved.
//

#import "CustomerTableViewCell.h"

@implementation CustomerTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
