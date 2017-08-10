//
//  XYCollectionViewController.m
//  XYRrearrangeCell
//
//  Created by Ossey on 16/11/7.
//  Copyright © 2016年 Ossey. All rights reserved.
//

#import "XYCollectionViewController.h"
#import "XYPlanItem.h"
#import "XYCollectionViewCell.h"
#import "UIScrollView+RollView.h"

@interface XYCollectionViewController ()

@property (nonatomic, strong) NSMutableArray *plans;
@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, strong) NSArray *tempPlans; // 用户缓存plans的临时数组

@end


@implementation XYCollectionViewController
//- (NSMutableArray *)tempPlans {
//    if (_tempPlans == nil) {
//        _tempPlans = [NSMutableArray array];
//    }
//    return _tempPlans;
//}
- (NSMutableArray *)plans {
    if (_plans == nil) {
        _plans = [NSMutableArray array];
    }
    return _plans;
}
- (UICollectionViewFlowLayout *)flowLayout {

    if (_flowLayout == nil) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        CGFloat itemW = 105;//[UIScreen mainScreen].bounds.size.width;
        CGFloat itemH = 100;
        flowLayout.itemSize = CGSizeMake(itemW, itemH);
        flowLayout.minimumLineSpacing = 0;
        flowLayout.minimumLineSpacing = 0;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _flowLayout = flowLayout;
    }
    return _flowLayout;
}

- (instancetype)init {
    return [super initWithCollectionViewLayout:self.flowLayout];
}

static NSString * const reuseIdentifier = @"Cell";
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupPlans];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.collectionView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    self.navigationItem.title = @"CollectionView";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:0 target:self action:@selector(cancleBtnClick)];
    
    self.collectionView.backgroundColor = xColorWithRGB(200, 200, 200);
    [self.collectionView registerNib:[UINib nibWithNibName:@"XYCollectionViewCell"
                                                    bundle:nil] forCellWithReuseIdentifier:reuseIdentifier];
    self.collectionView.rollingColor = [UIColor blueColor];
    
    __weak typeof(self) weak_self = self;
    [self.collectionView xy_rollViewFormOriginalDataSourceBlock:^NSArray * _Nonnull{
        return weak_self.plans;
    } newDataSourceBlock:^(NSArray * _Nullable newData) {
        self.tempPlans = [weak_self.plans copy];
        [weak_self.plans removeAllObjects];
        [weak_self.plans addObjectsFromArray:newData];
    }];
    

    self.collectionView.autoRollCellSpeed = 20;

}


#pragma mark - event
- (void)cancleBtnClick {

    NSLog(@"plans--%@, tempPlans--%@", self.plans, self.tempPlans);
    
//    [self.plans removeAllObjects];
//    [self.plans addObjectsFromArray:self.tempPlans];
//    [self.collectionView reloadData];
}


#pragma mark <UICollectionViewDataSource>
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return self.plans.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XYCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    for (UIView *view in cell.subviews) {
        [view removeFromSuperview];
    }
    cell.backgroundColor = xRandomColor;
    return cell;
}


#pragma mark - 非嵌套数组的数据
- (void)setupPlans {
    NSArray *array = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle]
                                                       pathForResource:@"plans.plist"
                                                       ofType:nil]];
    
    for (id obj in array) {
        XYPlanItem *item = [XYPlanItem planItemWithDict:obj];
        [self.plans addObject:item];
    }
    
}
@end
