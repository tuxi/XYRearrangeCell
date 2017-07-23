//
//  UIView+XYRollView.m
//  XYRrearrangeCell
//  
//  Created by mofeini on 16/11/7.
//  Copyright © 2016年 com.test.demo. All rights reserved.
//

#import "UIScrollView+RollView.h"
#import <objc/runtime.h>


char * const XYRollViewNewDataBlockKey = "XYRollViewNewDataBlockKey";
char * const XYRollViewOriginalDataBlockKey = "XYRollViewOriginalDataBlockKey";
char * const XYRollViewRollingColorKey = "XYRollViewRollingColorKey";
char * const XYRollViewRollIngShadowOpacityKey = "XYRollViewRollIngShadowOpacityKey";

char * const XYRollViewScreenshotViewKey = "XYRollViewScreenshotViewKey";
char * const XYRollViewOriginalIndexPathKey = "XYRollViewOriginalIndexPathKey";
char * const XYRollViewRelocatedIndexPathKey = "XYRollViewRelocatedIndexPathKey";
char * const XYRollViewAutoScrollTimerKey = "XYRollViewAutoScrollTimerKey";
char * const XYRollViewFingerLocationKey = "XYRollViewFingerLocationKey";
char * const XYRollViewAutoScrollDirectionKey = "XYRollViewAutoScrollDirectionKey";
char * const XYRollViewAutoRollCellSpeedKey   = "XYRollViewAutoRollCellSpeedKey";
char * const XYRollViewUpdateDataGroupKey = "XYRollViewUpdateDataGroupKey";

@interface UIScrollView ()

@property UIView *screenshotView; /** 对被选中的cell的截图 */
@property NSIndexPath *originalIndexPath; /** 被选中的cell的原始位置 */
@property NSIndexPath *relocatedIndexPath; /** 被选中的cell的新位置 */
@property CADisplayLink *autoScrollTimer; /** cell被拖动到边缘后开启，tableview自动向上或向下滚动 */
@property CGPoint fingerLocation; /** 记录手指所在的位置 */
@property XYRollViewScreenshotMeetsEdge autoScrollDirection; /** 自动滚动的方向 */
@property dispatch_group_t updateDataGroup;  /** 用于更新数据的gcd 组 */

@end


@implementation UIScrollView (XYRollView)

#pragma mark - 关联属性
- (void)setScreenshotView:(UIView *)screenshotView {
    
    objc_setAssociatedObject(self, XYRollViewScreenshotViewKey, screenshotView, OBJC_ASSOCIATION_ASSIGN);
}
- (UIView *)screenshotView {
    return objc_getAssociatedObject(self, XYRollViewScreenshotViewKey);
}

- (void)setOriginalIndexPath:(NSIndexPath *)originalIndexPath {
    objc_setAssociatedObject(self, XYRollViewOriginalIndexPathKey, originalIndexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSIndexPath *)originalIndexPath {
    return objc_getAssociatedObject(self, XYRollViewOriginalIndexPathKey);
}

- (void)setRelocatedIndexPath:(NSIndexPath *)relocatedIndexPath {
    objc_setAssociatedObject(self, XYRollViewRelocatedIndexPathKey, relocatedIndexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSIndexPath *)relocatedIndexPath {
    return objc_getAssociatedObject(self, XYRollViewRelocatedIndexPathKey);
}

- (void)setAutoScrollTimer:(CADisplayLink *)autoScrollTimer {
    objc_setAssociatedObject(self, XYRollViewAutoScrollTimerKey, autoScrollTimer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (CADisplayLink *)autoScrollTimer {
    return objc_getAssociatedObject(self, XYRollViewAutoScrollTimerKey);
}

- (void)setFingerLocation:(CGPoint)fingerLocation {
    objc_setAssociatedObject(self, XYRollViewFingerLocationKey, NSStringFromCGPoint(fingerLocation), OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (CGPoint)fingerLocation {
    NSString *str = objc_getAssociatedObject(self, XYRollViewFingerLocationKey);
    return CGPointFromString(str);
}

- (void)setAutoRollCellSpeed:(CGFloat)autoRollCellSpeed {
    objc_setAssociatedObject(self, XYRollViewAutoRollCellSpeedKey, @(autoRollCellSpeed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (CGFloat)autoRollCellSpeed {
    CGFloat autoRollCellSpeed = [objc_getAssociatedObject(self, XYRollViewAutoRollCellSpeedKey) doubleValue];
    if (autoRollCellSpeed == 0.0) {
        autoRollCellSpeed = 5.0;
        objc_setAssociatedObject(self, XYRollViewAutoRollCellSpeedKey, @(autoRollCellSpeed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return autoRollCellSpeed;
}

- (void)setAutoScrollDirection:(XYRollViewScreenshotMeetsEdge)autoScrollDirection {
    
    objc_setAssociatedObject(self, XYRollViewAutoScrollDirectionKey, @(autoScrollDirection), OBJC_ASSOCIATION_ASSIGN);
}
- (XYRollViewScreenshotMeetsEdge)autoScrollDirection {
    
    return [objc_getAssociatedObject(self, XYRollViewAutoScrollDirectionKey) integerValue];;
}

- (void)setUpdateDataGroup:(dispatch_group_t)updateDataGroup {
    
    objc_setAssociatedObject(self, XYRollViewUpdateDataGroupKey, updateDataGroup, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (dispatch_group_t)updateDataGroup {
    dispatch_group_t group = (dispatch_group_t)objc_getAssociatedObject(self, XYRollViewUpdateDataGroupKey);
    if (group == nil) {
        group = dispatch_group_create();
        objc_setAssociatedObject(self, XYRollViewUpdateDataGroupKey, group, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return group;
}


- (void)setNewDataBlock:(XYRollNewDataBlock)newDataBlock {
    objc_setAssociatedObject(self, XYRollViewNewDataBlockKey, newDataBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (XYRollNewDataBlock)newDataBlock {

    return objc_getAssociatedObject(self, XYRollViewNewDataBlockKey);
}

- (void)setOriginalDataBlock:(XYRollOriginalDataBlock)originalDataBlock {

    objc_setAssociatedObject(self, XYRollViewOriginalDataBlockKey, originalDataBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (XYRollOriginalDataBlock)originalDataBlock {

    return objc_getAssociatedObject(self, XYRollViewOriginalDataBlockKey);
}

- (void)setRollingColor:(UIColor *)rollingColor {
    objc_setAssociatedObject(self, XYRollViewRollingColorKey, rollingColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (UIColor *)rollingColor {
    UIColor *rollingColor = objc_getAssociatedObject(self, XYRollViewRollingColorKey);
    if (rollingColor == nil) {
        return [UIColor blackColor];
    }
    return rollingColor;
}

- (void)setRollIngShadowOpacity:(CGFloat)rollIngShadowOpacity {
    objc_setAssociatedObject(self, XYRollViewRollIngShadowOpacityKey, @(rollIngShadowOpacity), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (CGFloat)rollIngShadowOpacity {
    CGFloat rollIngShadowOpacity= [objc_getAssociatedObject(self, XYRollViewRollIngShadowOpacityKey) doubleValue];
    if (rollIngShadowOpacity == 0.0) {
        return 0.3;
    }
    return rollIngShadowOpacity;
}


////////////////////////////////////////////////////////////////////////
#pragma mark - initialize
////////////////////////////////////////////////////////////////////////


- (void)xy_rollViewWithOriginalDataBlock:(nullable XYRollOriginalDataBlock)originalDataBlock callBlckNewDataBlock:(nullable XYRollNewDataBlock)newDataBlock {
    
    self.originalDataBlock = originalDataBlock;
    self.newDataBlock = newDataBlock;
    [self setGestureRecognizer];
}


- (void)setGestureRecognizer {
    UILongPressGestureRecognizer *longPre = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressGestureRecognized:)];
    [self addGestureRecognizer:longPre];
    
    UISwipeGestureRecognizer *lefSwipe = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeGestureRecognized:)];
    lefSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [self addGestureRecognizer:lefSwipe];
    
    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeGestureRecognized:)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self addGestureRecognizer:rightSwipe];
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

#pragma mark - 触发手势的事件
- (void)longPressGestureRecognized:(UILongPressGestureRecognizer *)longPress {
    
    if (![self isKindOfClass:[UITableView class]] && ![UICollectionView class]) {
        return;
    }
    
    UIGestureRecognizerState state = longPress.state;
    // 获取手指在rollView上的坐标
    self.fingerLocation = [longPress locationInView:self];
    // 手指按住位置对应的indexPath，可能为nil
    UITableView *tableView = nil;
    UICollectionView *collectionView = nil;
    if ([self isKindOfClass:[UICollectionView class]]) {
        collectionView = (UICollectionView *)self;
    } else if ([self isKindOfClass:[UITableView class]]) {
        tableView = (UITableView *)self;
    }
    self.relocatedIndexPath = tableView ? [tableView indexPathForRowAtPoint:self.fingerLocation] : [collectionView indexPathForItemAtPoint:self.fingerLocation];
    
    // 1.手势开始时
    if (state == UIGestureRecognizerStateBegan) {
        // 获取originalIndexPath，注意容错处理，因为可能为nil
        self.originalIndexPath = tableView ? [tableView indexPathForRowAtPoint:self.fingerLocation] : [collectionView indexPathForItemAtPoint:self.fingerLocation];
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
        self.relocatedIndexPath = tableView ? [tableView indexPathForRowAtPoint:self.fingerLocation] : [collectionView indexPathForItemAtPoint:self.fingerLocation];
        if (self.relocatedIndexPath && ![self.relocatedIndexPath isEqual:self.originalIndexPath]) {
            [self cellRelocatedToNewIndexPath:self.relocatedIndexPath];
        }
    } else {
        // 3.其他情况，比如长按手势结束或被取消，移除截图，显示cell
        [self stopAutoScrollTimer];
        [self didEndDraging];
        
    }
    
    
    
}
// 轻扫手势
- (void)swipeGestureRecognized:(UISwipeGestureRecognizer *)swipe {
    if (![self isKindOfClass:[UITableView class]] && ![self isKindOfClass:[UICollectionView class]]) {
        return;
    }
    // 获取手指在rollView上的坐标
    self.fingerLocation = [swipe locationInView:self];
    // 手指按住位置对应的indexPath，可能为nil
    NSIndexPath *currentIndexPath = nil;
    if ([self isKindOfClass:[UITableView class]]) {
        UITableView *tableView = (UITableView *)self;
       currentIndexPath = [tableView indexPathForRowAtPoint:self.fingerLocation];
    }
    else if ([self isKindOfClass:[UICollectionView class]]) {
        UICollectionView *collectionView = (UICollectionView *)self;
       currentIndexPath = [collectionView indexPathForItemAtPoint:self.fingerLocation];
    }
    
    // 左滑动手势删除当前cell
    if (swipe.direction == UISwipeGestureRecognizerDirectionLeft) {
        if (currentIndexPath) {
            //手势开始，对被选中cell截图，隐藏原cell
            NSMutableArray *tempArray = [NSMutableArray array];
            if (self.originalDataBlock) {
                [tempArray addObjectsFromArray:self.originalDataBlock()];
            }
            // 删除数据后回调给外界，外界更新数据
            if ([self xy_nestedArrayCheck:tempArray]) {//是嵌套数组
                
                [tempArray[currentIndexPath.section] removeObjectAtIndex:currentIndexPath.row];
                
            } else { //不是嵌套数组
                [tempArray removeObjectAtIndex:currentIndexPath.row];
                
            }
            // 通过block将新数组回调给外界以更改数据源
            if (self.newDataBlock) {
                self.newDataBlock(tempArray);
                [UIView animateWithDuration:0.02 delay:0.1 options:0 animations:^{
                    [self cellSelectedAtIndexPath:currentIndexPath];
                } completion:^(BOOL finished) {
                    [self performSelector:@selector(reloadData)];
                    [self didEndDraging];
                }];
            }
        }
        
        // 右滑手势
    } else if (swipe.direction == UISwipeGestureRecognizerDirectionRight) {
#warning mark 待完成
        NSLog(@"++++");
    }
}



#pragma mark - 返回一个给定view的截图
- (__kindof UIView * __nonnull)xy_customScreenshotViewFromView:(UIView * __nullable)inputView {
    
    // 开启图形上下文
    UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, NO, 0);
    [inputView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // 通过图形上下文生成的图片，创建一个和图片尺寸相同大小的imageView，将其作为截图返回
    UIView *screenshotView = [[UIImageView alloc] initWithImage:image];
    screenshotView.center = inputView.center;
    screenshotView.layer.masksToBounds = NO;
    screenshotView.layer.cornerRadius = 0.0;
    screenshotView.layer.shadowOffset = CGSizeMake(-5.0, 0.0);
    screenshotView.layer.shadowRadius = 5.0;
    screenshotView.layer.shadowOpacity = self.rollIngShadowOpacity;
    screenshotView.layer.shadowColor = self.rollingColor.CGColor;
    return screenshotView;
}

#pragma mark - 对数组进行处理
/**
 *  将可变数组中的一个对象移动到该数组中的另外一个位置
 *  array     要变动的数组
 *  fromIndex 从这个index
 *  toIndex   移至这个index
 */
- (void)xy_moveObjectInMutableArray:(nonnull NSMutableArray *)array fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
    if (fromIndex < toIndex) {
        for (NSInteger i = fromIndex; i < toIndex; i++) {
            [array exchangeObjectAtIndex:i withObjectAtIndex:i + 1];
        }
    }else{
        for (NSInteger i = fromIndex; i > toIndex; i--) {
            [array exchangeObjectAtIndex:i withObjectAtIndex:i - 1];
        }
    }
}

/**
 *  检查数组是否为嵌套数组
 *  array 需要被检测的数组
 *  返回YES则表示是嵌套数组
 */
- (BOOL)xy_nestedArrayCheck:(nonnull NSArray *)array {
    for (id obj in array) {
        if ([obj isKindOfClass:[NSArray class]]) {
            return YES;
        }
    }
    return NO;
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

#pragma mark - 定时器
// 创建定时器并运行
- (void)startAutoScrollTimer{
    if (!self.autoScrollTimer) {
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
- (void)updateData {
    
    NSMutableArray *tempArray = [NSMutableArray array];
    if (self.originalDataBlock) {
        //通过originalDataBlock获得原始的数据
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

    UIView *cell = nil;
    if ([self isKindOfClass:[UITableView class]]) {
        cell = [(UITableView *)self cellForRowAtIndexPath:indexPath];
    }
    else if ([self isKindOfClass:[UICollectionView class]]) {
        cell = [(UICollectionView *)self cellForItemAtIndexPath:indexPath];
    }
    
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
    //    [UIView animateWithDuration:0.2 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionOverrideInheritedCurve animations:^{
    //        self.screenshotView.transform = CGAffineTransformMakeScale(1.03, 1.03);
    //        self.screenshotView.alpha = 0.98;
    //        self.screenshotView.center = center;
    //    } completion:nil];
}
/**
 *  截图被移动到新的indexPath范围，这时先更新数据源，重排数组，再将cell移至新位置
 *  @param indexPath 新的indexPath
 */
- (void)cellRelocatedToNewIndexPath:(NSIndexPath *)indexPath{
    //更新数据源并返回给外部
    [self updateData];
    //交换移动cell位置
    if ([self isKindOfClass:[UITableView class]]) {
        [(UITableView *)self moveRowAtIndexPath:self.originalIndexPath toIndexPath:indexPath];
    }
    else if ([self isKindOfClass:[UICollectionView class]]) {
        [(UICollectionView *)self moveItemAtIndexPath:self.originalIndexPath toIndexPath:indexPath];
    }
    //更新cell的原始indexPath为当前indexPath
    self.originalIndexPath = indexPath;
}

// 拖拽结束，显示cell，并移除截图

- (void)didEndDraging {
    
    UIView *cell = nil;
    if ([self isKindOfClass:[UITableView class]]) {
       UITableView *tableView = (UITableView *)self;
        cell = [tableView cellForRowAtIndexPath:self.originalIndexPath];
    }
    else if ([self isKindOfClass:[UICollectionView class]]) {
        UICollectionView *collectionView = (UICollectionView *)self;
        cell = [collectionView cellForItemAtIndexPath:self.originalIndexPath];
    }
    
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
    if ([self isKindOfClass:[UITableView class]]) {
        
        self.relocatedIndexPath = [(UITableView *)self indexPathForRowAtPoint:self.screenshotView.center];
    }
    else if ([self isKindOfClass:[UICollectionView class]]) {
        self.relocatedIndexPath = [(UICollectionView *)self indexPathForItemAtPoint:self.screenshotView.center];
    }
    
    if (self.relocatedIndexPath && ![self.relocatedIndexPath isEqual:self.originalIndexPath]) {
        [self cellRelocatedToNewIndexPath:self.relocatedIndexPath];
    }
}


@end
