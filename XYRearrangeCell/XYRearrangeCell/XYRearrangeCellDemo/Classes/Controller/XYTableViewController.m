//
//  XYTableViewController.m
//  XYRrearrangeCell
//
//  Created by Ossey on 16/11/6.
//  Copyright © 2016年 Ossey. All rights reserved.
//

#import "XYTableViewController.h"
#import "XYPlanItem.h"
#import "UIScrollView+RollView.h"
#import "XYRollViewCell.h"

@interface XYTableViewController ()

//@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *plans;

@end

@implementation XYTableViewController
static NSString * const identifier = @"identifier";

- (NSMutableArray *)plans {
    if (_plans == nil) {
        _plans = [NSMutableArray array];
    }
    return _plans;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"TableView";
    [self.tableView registerNib:[UINib nibWithNibName:@"XYRollViewCell" bundle:nil] forCellReuseIdentifier:identifier];
    
    self.tableView.rollingColor = [UIColor purpleColor];
    
    [self.tableView xy_rollViewFormOriginalDataSourceBlock:^NSArray *{
        return self.plans; // 返回当前的数据给tableView内部处理
    } newDataSourceBlock:^(NSArray *newData) {
        // 回调处理完成的数据给外界
        [self.plans removeAllObjects];
        [self.plans addObjectsFromArray:newData];
        // 更改完成后，根据情况确定是否刷新一次tableView
//        [self.tableView reloadData];
    }];

    
//    self.tableView.rowHeight = 60;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rollingColor = [UIColor blackColor];
    self.tableView.backgroundColor = xColorWithRGB(240, 240, 240);
    
    
    [self setupPlans];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"恢复数据" style:0 target:self action:@selector(refreshData)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"切换分组数据" style:0 target:self action:@selector(changeGroupData)];
}



#pragma mark - UITableViewDelegate, UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // 检测是不是嵌套数组
    if ([self nestedArrayCheck:self.plans]) {
        return self.plans.count;
    }
    
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    // 检测是不是嵌套数组
    if ([self nestedArrayCheck:self.plans]) {
        NSArray *array = self.plans[section];
        return array.count;
    }

    return self.plans.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    XYRollViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
 
    XYPlanItem *item = nil;
    // 检测是不是嵌套数组
    if ([self nestedArrayCheck:self.plans]) {
        item = self.plans[indexPath.section][indexPath.row];
    } else {
        item = self.plans[indexPath.row];
    }
    
    cell.item = item;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    // 检测是不是嵌套数组
    if ([self nestedArrayCheck:self.plans]) {
        return 30;
    }
    return 0.1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

    // 检测是不是嵌套数组
    if ([self nestedArrayCheck:self.plans]) {
        return [NSString stringWithFormat:@"第%ld组", section + 1];
    }
        return nil;
}


#pragma mark - 非嵌套数组的数据
- (void)setupPlans {
    NSArray *array = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle]
                                                       pathForResource:@"plans.plist"
                                                       ofType:nil]];
    NSMutableArray *arrayM = [NSMutableArray array];
    for (id obj in array) {
        XYPlanItem *item = [XYPlanItem planItemWithDict:obj];
        [arrayM addObject:item];
    }
    [self.plans removeAllObjects];
    [self.plans addObjectsFromArray:arrayM];
    
}
#pragma mark - 嵌套数组的数据
- (void)setupPlansGroup {

    NSArray *array = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle]
                                                       pathForResource:@"planGroup.plist"
                                                       ofType:nil]];
    NSMutableArray *arrayGroup = [NSMutableArray array];
    for (NSArray *group in array) {
        NSMutableArray *arrayM = [NSMutableArray array];
        for (NSDictionary *dict in group) {
            XYPlanItem *item = [XYPlanItem planItemWithDict:dict];
            [arrayM addObject:item];
        }
        [arrayGroup addObject:arrayM];
    }

    [self.plans removeAllObjects];
    [self.plans addObjectsFromArray:arrayGroup];
}


// 刷新普通数据
- (void)refreshData {

    [self setupPlans];
    [self.tableView reloadData];
}

// 切换分组数据,并刷新分组数据
- (void)changeGroupData {

    [self setupPlansGroup];
    [self.tableView reloadData];
}

- (BOOL)nestedArrayCheck:(nonnull NSArray *)array {
    for (id obj in array) {
        if ([obj isKindOfClass:[NSArray class]]) {
            return YES;
        }
    }
    return NO;
}

@end
