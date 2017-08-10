//
//  XYPlanItem.h
//  XYRrearrangeCell
//
//  Created by Ossey on 16/11/6.
//  Copyright © 2016年 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XYPlanItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subTitle;
@property (nonatomic, strong) UIColor *textColor;

+ (instancetype)planItemWithDict:(NSDictionary *)dict;
@end
