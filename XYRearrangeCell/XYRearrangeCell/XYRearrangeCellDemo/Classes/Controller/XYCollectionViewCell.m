//
//  XYCollectionViewCell.m
//  XYRrearrangeCell
//
//  Created by mofeini on 16/11/7.
//  Copyright © 2016年 com.test.demo. All rights reserved.
//

#import "XYCollectionViewCell.h"
#import "XYPlanItem.h"

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
