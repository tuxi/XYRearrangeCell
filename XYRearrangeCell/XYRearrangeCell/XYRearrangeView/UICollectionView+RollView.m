//
//  UICollectionView+RollView.m
//  XYRrearrangeCell
//  
//  Created by mofeini on 16/11/8.
//  Copyright © 2016年 com.test.demo. All rights reserved.
//

#import "UICollectionView+RollView.h"
#import <objc/runtime.h>


char * const XYRollViewCScreenshotViewKey      = "XYRollViewCScreenshotViewKey";
char * const XYRollViewCOriginalIndexPathKey   = "XYRollViewcOriginalIndexPathKey";
char * const XYRollViewCRelocatedIndexPathKey  = "XYRollViewCRelocatedIndexPathKey";
char * const XYRollViewCAutoScrollTimerKey     = "XYRollViewCAutoScrollTimerKey";
char * const XYRollViewCFingerLocationKey      = "XYRollViewCFingerLocationKey";
char * const XYRollViewCAutoScrollDirectionKey = "XYRollViewCAutoScrollDirectionKey";
char * const XYRollViewCAutoRollCellSpeedKey   = "XYRollViewCAutoRollCellSpeedKey";


typedef NS_ENUM(NSInteger, XYRollViewScreenshotMeetsEdge) {
    XYRollViewScreenshotMeetsEdgeNone = 0,     // 选中cell的截图没有到达父控件边缘
    XYRollViewScreenshotMeetsEdgeTop,          // 选中cell的截图到达父控件顶部边缘
    XYRollViewScreenshotMeetsEdgeBottom,       // 选中cell的截图到达父控件底部边缘
    XYRollViewScreenshotMeetsEdgeLeft,         // 选中cell的截图到达父控件左侧边缘
    XYRollViewScreenshotMeetsEdgeRight,        // 选中cell的截图到达父控件右侧边缘
};

@interface UICollectionView ()

@property UIView *screenshotView; /** 对被选中的cell的截图 */
@property NSIndexPath *originalIndexPath; /** 被选中的cell的原始位置 */
@property NSIndexPath *relocatedIndexPath; /** 被选中的cell的新位置 */
@property CADisplayLink *autoScrollTimer; /** cell被拖动到边缘后开启，tableview自动向上或向下滚动 */
@property CGPoint fingerLocation; /** 记录手指所在的位置 */
@property XYRollViewScreenshotMeetsEdge autoScrollDirection; /** 自动滚动的方向 */

@end
@implementation UICollectionView (RollView)
- (void)setScreenshotView:(UIView *)screenshotView {
    
    objc_setAssociatedObject(self, XYRollViewCScreenshotViewKey, screenshotView, OBJC_ASSOCIATION_ASSIGN);
}
- (UIView *)screenshotView {
    return objc_getAssociatedObject(self, XYRollViewCScreenshotViewKey);
}

- (void)setOriginalIndexPath:(NSIndexPath *)originalIndexPath {
    objc_setAssociatedObject(self, XYRollViewCOriginalIndexPathKey, originalIndexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSIndexPath *)originalIndexPath {
    return objc_getAssociatedObject(self, XYRollViewCOriginalIndexPathKey);
}

- (void)setRelocatedIndexPath:(NSIndexPath *)relocatedIndexPath {
    objc_setAssociatedObject(self, XYRollViewCRelocatedIndexPathKey, relocatedIndexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSIndexPath *)relocatedIndexPath {
    return objc_getAssociatedObject(self, XYRollViewCRelocatedIndexPathKey);
}

- (void)setAutoScrollTimer:(CADisplayLink *)autoScrollTimer {
    objc_setAssociatedObject(self, XYRollViewCAutoScrollTimerKey, autoScrollTimer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (CADisplayLink *)autoScrollTimer {
    return objc_getAssociatedObject(self, XYRollViewCAutoScrollTimerKey);
}

- (void)setFingerLocation:(CGPoint)fingerLocation {
    objc_setAssociatedObject(self, XYRollViewCFingerLocationKey, NSStringFromCGPoint(fingerLocation), OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (CGPoint)fingerLocation {
    NSString *str = objc_getAssociatedObject(self, XYRollViewCFingerLocationKey);
    return CGPointFromString(str);
}

- (void)setAutoScrollDirection:(XYRollViewScreenshotMeetsEdge)autoScrollDirection {
    
    objc_setAssociatedObject(self, XYRollViewCAutoScrollDirectionKey, @(autoScrollDirection), OBJC_ASSOCIATION_ASSIGN);
}
- (XYRollViewScreenshotMeetsEdge)autoScrollDirection {
    
    return [objc_getAssociatedObject(self, XYRollViewCAutoScrollDirectionKey) integerValue];;
}

- (void)setAutoRollCellSpeed:(CGFloat)autoRollCellSpeed {
    objc_setAssociatedObject(self, XYRollViewCAutoRollCellSpeedKey, @(autoRollCellSpeed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (CGFloat)autoRollCellSpeed {
    return [objc_getAssociatedObject(self, XYRollViewCAutoRollCellSpeedKey) doubleValue];
}

- (void)setLongPressGesture {
    UILongPressGestureRecognizer *longPre = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressGestureRecognized:)];
    [self addGestureRecognizer:longPre];
}

// 编译器指令来屏蔽Xcode编译提醒/指定初始化器问题
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (nonnull instancetype)initWithOriginalDataBlock:(nullable XYRollOriginalDataBlock)originalDataBlock callBlckNewDataBlock:(nullable XYRollNewDataBlock)newDataBlock {

    [self setLongPressGesture];

    return self;
}

+ (nonnull instancetype)xy_collectionViewLayout:(nonnull UICollectionViewLayout *)layout originalDataBlock:(nullable XYRollOriginalDataBlock)originalDataBlock callBlckNewDataBlock:(nullable XYRollNewDataBlock)newDataBlock {

    return [[UICollectionView alloc] initWitCollectionViewLayout:layout originalDataBlock:originalDataBlock callBlckNewDataBlock:newDataBlock];
    
}

- (nonnull instancetype)initWitCollectionViewLayout:(nonnull UICollectionViewLayout *)layout originalDataBlock:(nullable XYRollOriginalDataBlock)originalDataBlock callBlckNewDataBlock:(nullable XYRollNewDataBlock)newDataBlock {

    if (self = [self initWithFrame:self.superview.bounds collectionViewLayout:layout]) {
        [self setLongPressGesture];
        
        self.originalDataBlock = originalDataBlock;
        self.newDataBlock = newDataBlock;
    }
    return self;
}


#pragma mark - 触发手势的事件
- (void)longPressGestureRecognized:(UILongPressGestureRecognizer *)longPress{
    UIGestureRecognizerState state = longPress.state;
    // 获取手指在rollView上的坐标
    self.fingerLocation = [longPress locationInView:self];
    // 手指按住位置对应的indexPath，可能为nil
    self.relocatedIndexPath = [self indexPathForItemAtPoint:self.fingerLocation];
    
    // 1.手势开始时
    if (state == UIGestureRecognizerStateBegan) {
        // 获取originalIndexPath，注意容错处理，因为可能为nil
        self.originalIndexPath = [self indexPathForItemAtPoint:self.fingerLocation];
        if (self.originalIndexPath) {
            //手势开始，对被选中cell截图，隐藏原cell
            [self cellSelectedAtIndexPath:self.originalIndexPath];
        }
        // 2.手势开始改变时
    } else if (state == UIGestureRecognizerStateChanged) {
        // 长按手势开始移动，判断手指按住位置是否进入其它indexPath范围，若进入则更新数据源并移动cell
        // 截图跟随手指移动
        CGPoint center = self.screenshotView.center;
        center.y = self.fingerLocation.y;
        center.x = self.fingerLocation.x;
        self.screenshotView.center = center;
        // 检测是否到达边缘，如果到达边缘就开始运行定时器,自动滚动
        if ([self checkIfscreenshotViewMeetsEdge]) {
            [self startAutoScrollTimer];
        } else {
            [self stopAutoScrollTimer];
        }
        //手指按住位置对应的indexPath，可能为nil
        self.relocatedIndexPath = [self indexPathForItemAtPoint:self.fingerLocation];
        if (self.relocatedIndexPath && ![self.relocatedIndexPath isEqual:self.originalIndexPath]) {
            [self cellRelocatedToNewIndexPath:self.relocatedIndexPath];
        }
    } else {
        // 3.其他情况，比如长按手势结束或被取消，移除截图，显示cell
        [self stopAutoScrollTimer];
        [self didEndDraging];
        
    }
    
    
    
}

#pragma mark - 定时器
// 创建定时器并运行
- (void)startAutoScrollTimer {
    if (!self.autoScrollTimer) {
        // 创建定时器，并运行自动滚动方法
        self.autoScrollTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(startAutoScroll)];
        [self.autoScrollTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}

// 停止定时器并销毁
- (void)stopAutoScrollTimer {
    if (self.autoScrollTimer) {
        [self.autoScrollTimer invalidate];
        self.autoScrollTimer = nil;
    }
}


#pragma mark - 更新数据
// 修改数据后回调给外界，外界更新数据
- (void)updateDataSource{
    //通过originalDataBlock获得原始的数据
    NSMutableArray *tempArray = [NSMutableArray array];
    if (self.originalDataBlock) {
        [tempArray addObjectsFromArray:self.originalDataBlock()];
    }
    //判断原始数据是否为嵌套数组
    if ([self xy_nestedArrayCheck:tempArray]) {//是嵌套数组
        if (self.originalIndexPath.section == self.relocatedIndexPath.section) {//在同一个section内
            [self xy_moveObjectInMutableArray:tempArray[self.originalIndexPath.section] fromIndex:self.originalIndexPath.row toIndex:self.relocatedIndexPath.row];
        }else {
            //不在同一个section内
            // 容错处理：当外界的数组实际类型不是NSMutableArray时，将其转换为NSMutableArray
            id originalObj = tempArray[self.originalIndexPath.section][self.originalIndexPath.item];
            [tempArray[self.relocatedIndexPath.section] insertObject:originalObj atIndex:self.relocatedIndexPath.item];
            [tempArray[self.originalIndexPath.section] removeObjectAtIndex:self.originalIndexPath.item];
        }
    }else{                                  //不是嵌套数组
        [self xy_moveObjectInMutableArray:tempArray fromIndex:self.originalIndexPath.row toIndex:self.relocatedIndexPath.row];
    }
    
    // 通过block将新数组回调给外界以更改数据源，
    if (self.newDataBlock) {
        self.newDataBlock(tempArray);
    }
}


// cell被长按手指选中，对其进行截图，原cell隐藏
- (void)cellSelectedAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [self cellForItemAtIndexPath:indexPath];
    UIView *screenshotView = [self xy_customScreenshotViewFromView:cell];
    [self addSubview:screenshotView];
    self.screenshotView = screenshotView;
    cell.hidden = YES;
    CGPoint center = self.screenshotView.center;
    center.y = self.fingerLocation.y;
    [UIView animateWithDuration:0.2 animations:^{
        self.screenshotView.transform = CGAffineTransformMakeScale(1.03, 1.03);
        self.screenshotView.alpha = 0.98;
        self.screenshotView.center = center;
    }];
}
/**
 *  截图被移动到新的indexPath范围，这时先更新数据源，重排数组，再将cell移至新位置
 *  @param indexPath 新的indexPath
 */
- (void)cellRelocatedToNewIndexPath:(NSIndexPath *)indexPath{
    //更新数据源并返回给外部
    [self updateDataSource];
    //交换移动cell位置
    [self moveItemAtIndexPath:self.originalIndexPath toIndexPath:indexPath];
    // 更新cell的原始indexPath为当前indexPath
    self.originalIndexPath = indexPath;
}

// 拖拽结束，显示cell，并移除截图
- (void)didEndDraging{
    UICollectionViewCell *cell = [self cellForItemAtIndexPath:self.originalIndexPath];
    cell.hidden = NO;
    cell.alpha = 0;
    [UIView animateWithDuration:0.2 animations:^{
        self.screenshotView.center = cell.center;
        self.screenshotView.alpha = 0;
        self.screenshotView.transform = CGAffineTransformIdentity;
        cell.alpha = 1;
    } completion:^(BOOL finished) {
        cell.hidden = NO;
        [self.screenshotView removeFromSuperview];
        self.screenshotView = nil;
        self.originalIndexPath = nil;
        self.relocatedIndexPath = nil;
    }];
}


// 检查截图是否到达边缘，并作出响应
- (BOOL)checkIfscreenshotViewMeetsEdge{
    
    NSLog(@"%ld", self.autoScrollDirection);
    
    CGFloat minY = CGRectGetMinY(self.screenshotView.frame);
    CGFloat maxY = CGRectGetMaxY(self.screenshotView.frame);
    CGFloat MinX = CGRectGetMinX(self.screenshotView.frame);
    CGFloat maxX = CGRectGetMaxX(self.screenshotView.frame);
    if (minY < self.contentOffset.y) {
        self.autoScrollDirection = XYRollViewScreenshotMeetsEdgeTop;
        return YES;
    }
    if (maxY > self.bounds.size.height + self.contentOffset.y) {
        self.autoScrollDirection = XYRollViewScreenshotMeetsEdgeBottom;
        return YES;
    }
    if (MinX < self.contentOffset.x) {
        self.autoScrollDirection = XYRollViewScreenshotMeetsEdgeLeft;
        return YES;
    }
    if (maxX > self.bounds.size.width + self.contentOffset.x) {
        self.autoScrollDirection = XYRollViewScreenshotMeetsEdgeRight;
        return YES;
    }
    self.autoScrollDirection = XYRollViewScreenshotMeetsEdgeNone;
    return NO;
}

// 开始自动滚动
- (void)startAutoScroll {
    
    // 设置自动滚动速度
    if (self.autoRollCellSpeed == 0.0) {
        self.autoRollCellSpeed = 5.0;
    } else if (self.autoRollCellSpeed > 15) {
        self.autoRollCellSpeed = 15;
    }
    CGFloat autoRollCellSpeed = self.autoRollCellSpeed; // 滚动速度，数值越大滚动越快
    
    if (self.autoScrollDirection == XYRollViewScreenshotMeetsEdgeTop) {//向上滚动
        //向上滚动最大范围限制
        if (self.contentOffset.y > 0) {
            
            self.contentOffset = CGPointMake(0, self.contentOffset.y - autoRollCellSpeed);
            self.screenshotView.center = CGPointMake(self.screenshotView.center.x, self.screenshotView.center.y - autoRollCellSpeed);
        }
        return;
    } else if (self.autoScrollDirection == XYRollViewScreenshotMeetsEdgeBottom) { // 向下滚动
        //向下滚动最大范围限制
        if (self.contentOffset.y + self.bounds.size.height < self.contentSize.height) {
            
            self.contentOffset = CGPointMake(0, self.contentOffset.y + autoRollCellSpeed);
            self.screenshotView.center = CGPointMake(self.screenshotView.center.x, self.screenshotView.center.y + autoRollCellSpeed);
        }
        return;
    } else if (self.autoScrollDirection == XYRollViewScreenshotMeetsEdgeLeft) {
        // 向左滚动滚动的最大范围限制
        if (self.contentOffset.x > 0) {
            self.contentOffset = CGPointMake(self.contentOffset.x - autoRollCellSpeed, 0);
            self.screenshotView.center = CGPointMake(self.screenshotView.center.x - autoRollCellSpeed, self.screenshotView.center.y);
        }
        return;
    } else if (self.autoScrollDirection == XYRollViewScreenshotMeetsEdgeRight) {
        
        // 向右滚动滚动的最大范围限制
        if (self.contentOffset.x + self.bounds.size.width < self.contentSize.width) {
            self.contentOffset = CGPointMake(self.contentOffset.x + autoRollCellSpeed, self.contentOffset.y);
            self.screenshotView.center = CGPointMake(self.screenshotView.center.x + autoRollCellSpeed, self.screenshotView.center.y);
        }
        return;
    }
    
#warning mark
    //  当把截图拖动到边缘自动滚动,手指不动手时，手动触发
    self.relocatedIndexPath = [self indexPathForItemAtPoint:self.screenshotView.center];
    if (self.relocatedIndexPath && ![self.relocatedIndexPath isEqual:self.originalIndexPath]) {
        [self cellRelocatedToNewIndexPath:self.relocatedIndexPath];
    }
}


@end
