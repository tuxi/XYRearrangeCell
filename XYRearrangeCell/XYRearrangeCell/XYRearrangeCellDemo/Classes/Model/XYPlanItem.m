//
//  XYPlanItem.m
//  XYRrearrangeCell
//
//  Created by mofeini on 16/11/6.
//  Copyright © 2016年 com.test.demo. All rights reserved.
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
