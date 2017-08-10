//
//  XYTabBarController.m
//  XYRrearrangeCell
//
//  Created by Ossey on 16/11/8.
//  Copyright © 2016年 Ossey. All rights reserved.
//

#import "XYTabBarController.h"
#import "XYTableViewController.h"
#import "XYCollectionViewController.h"
#import "XYCollectionViewControlleC.h"
#import "XYViewController.h"

@interface XYTabBarController ()

@end

@implementation XYTabBarController

+ (void)initialize
{
    if (self == [XYTabBarController class]) {
        
        UITabBarItem *tabBarItem = [UITabBarItem appearanceWhenContainedInInstancesOfClasses:@[self]];
        [tabBarItem setTitleTextAttributes:@{
                                             NSFontAttributeName:
                                                 [UIFont systemFontOfSize:18 weight:1],
                                             NSForegroundColorAttributeName: [UIColor brownColor]
                                             } forState:UIControlStateNormal];
        [tabBarItem setTitleTextAttributes:@{
                                             NSForegroundColorAttributeName:
                                                 [UIColor magentaColor]
                                             } forState:UIControlStateSelected];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    XYTableViewController *vc1 = [XYTableViewController new];
    UINavigationController *nav1 = [[UINavigationController alloc] initWithRootViewController:vc1];
    nav1.tabBarItem.title = @"完成";
    
    [self addChildViewController:nav1];
    
    XYCollectionViewController *vc2 = [XYCollectionViewController new];
    UINavigationController *nav2 = [[UINavigationController alloc] initWithRootViewController:vc2];
    nav2.tabBarItem.title = @"待完";
    [self addChildViewController:nav2];
    
    XYCollectionViewControlleC *vc3 = [XYCollectionViewControlleC new];
    UINavigationController *nav3 = [[UINavigationController alloc] initWithRootViewController:vc3];
    nav3.tabBarItem.title = @"计划";
    [self addChildViewController:nav3];
    
    XYViewController *vc4 = [XYViewController new];
    UINavigationController *nav4 = [[UINavigationController alloc] initWithRootViewController:vc4];
    nav4.tabBarItem.title = @"事件";
    [self addChildViewController:nav4];
    
    
}



@end
