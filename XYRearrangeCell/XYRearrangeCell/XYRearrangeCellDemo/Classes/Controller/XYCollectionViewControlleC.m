//
//  XYCollectionViewController.m
//  XYRrearrangeCell
//
//  Created by mofeini on 16/11/7.
//  Copyright © 2016年 com.test.demo. All rights reserved.
//

#import "XYCollectionViewControlleC.h"
#import "XYPlanItem.h"
#import "XYCollectionViewCell.h"
#import "UIScrollView+RollView.h"

@interface XYCollectionViewControlleC () <UICollectionViewDataSource>

@property (nonatomic, strong) NSMutableArray *plans;
@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, weak) UICollectionView *collectionView;
@end

@implementation XYCollectionViewControlleC
static NSString * const reuseIdentifier = @"Cell";

- (NSMutableArray *)plans {
    if (_plans == nil) {
        _plans = [NSMutableArray array];
    }
    return _plans;
}
- (UICollectionViewFlowLayout *)flowLayout {

    if (_flowLayout == nil) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        CGFloat itemW = [UIScreen mainScreen].bounds.size.width;
        CGFloat itemH = 100;
        flowLayout.itemSize = CGSizeMake(itemW, itemH);
        flowLayout.minimumLineSpacing = 0;
        flowLayout.minimumLineSpacing = 0;
        _flowLayout = flowLayout;
    }
    return _flowLayout;
}

- (UICollectionView *)collectionView {
    if (_collectionView == nil) {
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.flowLayout];
        collectionView.dataSource = self;
        collectionView.backgroundColor = xColorWithRGB(200, 200, 200);
        [collectionView registerNib:[UINib nibWithNibName:@"XYCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:reuseIdentifier];
        collectionView.rollingColor = [UIColor blueColor];
        [self.view addSubview:collectionView];
        _collectionView = collectionView;
        
        [self makeCollectionViewConstr];
    }
    return _collectionView;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray *array = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle]
                                                       pathForResource:@"planGroup.plist"
                                                       ofType:nil]];

    for (NSArray *group in array) {
        NSMutableArray *arrayM = [NSMutableArray array];
        for (NSDictionary *dict in group) {
            XYPlanItem *item = [XYPlanItem planItemWithDict:dict];
            [arrayM addObject:item];
            
        }
        [self.plans addObject:arrayM];
    }
    
    
    self.navigationItem.title = @"CollectionView";

    [self.collectionView xy_rollViewFormOriginalDataSourceBlock:^NSArray *{
        return self.plans;
    } newDataSourceBlock:^(NSArray *newData) {
        [self.plans removeAllObjects];
        [self.plans addObjectsFromArray:newData];
    }];
    
    self.collectionView.autoRollCellSpeed = 20;

}

- (void)makeCollectionViewConstr {
    
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = NSDictionaryOfVariableBindings(_collectionView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_collectionView]|" options:0 metrics:0 views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_collectionView]|" options:0 metrics:0 views:views]];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.plans.count;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSArray *array = self.plans[section];
    return array.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XYCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    cell.planItem = self.plans[indexPath.section][indexPath.row];
    cell.backgroundColor = xRandomColor;
    return cell;
}

#pragma mark <UICollectionViewDelegate>


@end
