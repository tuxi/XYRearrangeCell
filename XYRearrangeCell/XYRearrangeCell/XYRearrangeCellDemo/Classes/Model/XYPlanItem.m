//
//  XYPlanItem.m
//  XYRrearrangeCell
//
//  Created by Ossey on 16/11/6.
//  Copyright © 2016年 Ossey. All rights reserved.
//

#import "XYPlanItem.h"

@implementation XYPlanItem

+ (instancetype)planItemWithDict:(NSDictionary *)dict {
    
    return [[self alloc] initWithDict:dict];
}
- (instancetype)initWithDict:(NSDictionary *)dict {

    if (self = [super init]) {
        
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

@end
