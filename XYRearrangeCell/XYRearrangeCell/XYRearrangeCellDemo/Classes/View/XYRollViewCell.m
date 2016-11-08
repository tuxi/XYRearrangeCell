//
//  XYRollViewCell.m
//  XYRrearrangeCell
//
//  Created by mofeini on 16/11/6.
//  Copyright © 2016年 com.test.demo. All rights reserved.
//

#import "XYRollViewCell.h"
#import "XYPlanItem.h"
#define xColorWithRGB(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
#define xRandomColor xColorWithRGB(arc4random_uniform(256), arc4random_uniform(256), arc4random_uniform(256))

@interface XYRollViewCell ()
@property (weak, nonatomic) IBOutlet UILabel *title_label;
@property (weak, nonatomic) IBOutlet UILabel *sub_title;

@end

@implementation XYRollViewCell

- (void)setItem:(XYPlanItem *)item {

    _item = item;
    self.title_label.text = item.title;
    self.sub_title.text = item.subTitle;
    self.title_label.textColor = xRandomColor;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
//    self.accessoryType = UITableViewCellAccessoryCheckmark;
    
}
@end
