//
//  XYCollectionViewCell.m
//  XYRrearrangeCell
//
//  Created by mofeini on 16/11/7.
//  Copyright © 2016年 com.test.demo. All rights reserved.
//

#import "XYCollectionViewCell.h"
#import "XYPlanItem.h"
#define xColorWithRGB(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
#define xRandomColor xColorWithRGB(arc4random_uniform(256), arc4random_uniform(256), arc4random_uniform(256))

@interface XYCollectionViewCell ()
@property (weak, nonatomic) IBOutlet UILabel *subTitle;
@property (weak, nonatomic) IBOutlet UILabel *title;


@end
@implementation XYCollectionViewCell

- (void)setPlanItem:(XYPlanItem *)planItem {

    _planItem = planItem;
    
    self.subTitle.text = planItem.subTitle;
    self.title.text = planItem.title;
    self.title.textColor = [UIColor whiteColor];
}

@end
