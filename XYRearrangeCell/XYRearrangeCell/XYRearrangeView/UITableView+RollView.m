//
//  UITableView+RollViewTableView.m
//  XYRrearrangeCell
//  
//  Created by mofeini on 16/11/8.
//  Copyright © 2016年 com.test.demo. All rights reserved.
//

#import "UITableView+RollView.h"
#import <objc/runtime.h>

char * const XYRollViewScreenshotViewKey = "XYRollViewScreenshotViewKey";
char * const XYRollViewOriginalIndexPathKey = "XYRollViewOriginalIndexPathKey";
char * const XYRollViewRelocatedIndexPathKey = "XYRollViewRelocatedIndexPathKey";
char * const XYRollViewAutoScrollTimerKey = "XYRollViewAutoScrollTimerKey";
char * const XYRollViewFingerLocationKey = "XYRollViewFingerLocationKey";
char * const XYRollViewAutoScrollDirectionKey = "XYRollViewAutoScrollDirectionKey";
char * const XYRollViewAutoRollCellSpeedKey   = "XYRollViewAutoRollCellSpeedKey";
char * const XYRollViewUpdateDataGroupKey = "XYRollViewUpdateDataGroupKey";

typedef NS_ENUM(NSInteger, XYRollTableViewScreenshotMeetsEdge) {
    XYRollTableViewScreenshotMeetsEdgeTop = 0,      // 选中cell的截图到达屏幕的顶部
    XYRollTableViewScreenshotMeetsEdgeBottom,       // 选中cell的截图到达屏幕的底部
};
@interface UITableView ()
@property UIView *screenshotView; /** 对被选中的cell的截图 */
@property NSIndexPath *originalIndexPath; /** 被选中的cell的原始位置 */
@property NSIndexPath *relocatedIndexPath; /** 被选中的cell的新位置 */
@property CADisplayLink *autoScrollTimer; /** cell被拖动到边缘后开启，tableview自动向上或向下滚动 */
@property CGPoint fingerLocation; /** 记录手指所在的位置 */
@property XYRollTableViewScreenshotMeetsEdge autoScrollDirection; /** 自动滚动的方向 */
@property dispatch_group_t updateDataGroup;  /** 用于更新数据的gcd 组 */

@end
@implementation UITableView (RollViewTableView)
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
        return 5.0;
    }
    return autoRollCellSpeed;
}

- (void)setAutoScrollDirection:(XYRollTableViewScreenshotMeetsEdge)autoScrollDirection {

    objc_setAssociatedObject(self, XYRollViewAutoScrollDirectionKey, @(autoScrollDirection), OBJC_ASSOCIATION_ASSIGN);
}
- (XYRollTableViewScreenshotMeetsEdge)autoScrollDirection {

    return [objc_getAssociatedObject(self, XYRollViewAutoScrollDirectionKey) integerValue];;
}

- (void)setUpdateDataGroup:(dispatch_group_t)updateDataGroup {

    objc_setAssociatedObject(self, XYRollViewUpdateDataGroupKey, updateDataGroup, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (dispatch_group_t)updateDataGroup {
    dispatch_group_t group = (dispatch_group_t)objc_getAssociatedObject(self, XYRollViewUpdateDataGroupKey);
    if (group == nil) {
        group = dispatch_group_create();
    }
    return group;
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




// 编译器指令来屏蔽Xcode编译提醒/指定初始化器问题
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)initWithOriginalDataBlock:(XYRollOriginalDataBlock)originalDataBlock callBlckNewDataBlock:(XYRollNewDataBlock)newDataBlock {
    
    if (self = [super initWithOriginalDataBlock:originalDataBlock callBlckNewDataBlock:newDataBlock]) {
        [self setGestureRecognizer];
    }
    return self;
}


#pragma mark - 触发手势的事件
// 长按手势
- (void)longPressGestureRecognized:(UILongPressGestureRecognizer *)longPress{
    UIGestureRecognizerState state = longPress.state;
    // 获取手指在rollView上的坐标
    self.fingerLocation = [longPress locationInView:self];
    // 手指按住位置对应的indexPath，可能为nil
    self.relocatedIndexPath = [self indexPathForRowAtPoint:self.fingerLocation];
    
    // 1.手势开始时
    if (state == UIGestureRecognizerStateBegan) {
        // 获取originalIndexPath，注意容错处理，因为可能为nil
        self.originalIndexPath = [self indexPathForRowAtPoint:self.fingerLocation];
        if (self.originalIndexPath) {
            //手势开始，对被选中cell截图，隐藏原cell
            [self cellSelectedAtIndexPath:self.originalIndexPath];
        }
        // 2.手势开始改变时
    } else if (state == UIGestureRecognizerStateChanged) {
        //点击位置移动，判断手指按住位置是否进入其它indexPath范围，若进入则更新数据源并移动cell
        //截图跟随手指移动
        CGPoint center = self.screenshotView.center;
        center.y = self.fingerLocation.y;
        self.screenshotView.center = center;
        if ([self checkIfscreenshotViewMeetsEdge]) { // 检测是否到达边缘，如果到达边缘就开始运行定时器
            [self startAutoScrollTimer];
        }else{
            [self stopAutoScrollTimer];
        }
        //手指按住位置对应的indexPath，可能为nil
        self.relocatedIndexPath = [self indexPathForRowAtPoint:self.fingerLocation];
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
    
    // 获取手指在rollView上的坐标
    self.fingerLocation = [swipe locationInView:self];
    // 手指按住位置对应的indexPath，可能为nil
    NSIndexPath *currentIndexPath = [self indexPathForRowAtPoint:self.fingerLocation];
    
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
                    [self reloadData];
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
    UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
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
    [self moveRowAtIndexPath:self.originalIndexPath toIndexPath:indexPath];
    //更新cell的原始indexPath为当前indexPath
    self.originalIndexPath = indexPath;
}

// 拖拽结束，显示cell，并移除截图
 
- (void)didEndDraging{
    UITableViewCell *cell = [self cellForRowAtIndexPath:self.originalIndexPath];
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
    CGFloat minY = CGRectGetMinY(self.screenshotView.frame);
    CGFloat maxY = CGRectGetMaxY(self.screenshotView.frame);
    if (minY < self.contentOffset.y) {
        self.autoScrollDirection = XYRollTableViewScreenshotMeetsEdgeTop;
        return YES;
    }
    if (maxY > self.bounds.size.height + self.contentOffset.y) {
        self.autoScrollDirection = XYRollTableViewScreenshotMeetsEdgeBottom;
        return YES;
    }
    return NO;
}


// 开始自动滚动
- (void)startAutoScroll{

    CGFloat autoRollCellSpeed = self.autoRollCellSpeed; // 滚动速度，数值越大滚动越快
    if (self.autoScrollDirection == XYRollTableViewScreenshotMeetsEdgeTop) {//向下滚动
        if (self.contentOffset.y > 0) {//向下滚动最大范围限制
            [self setContentOffset:CGPointMake(0, self.contentOffset.y - autoRollCellSpeed)];
            self.screenshotView.center = CGPointMake(self.screenshotView.center.x, self.screenshotView.center.y - autoRollCellSpeed);
        }
    }else {                                               //向上滚动
        if (self.contentOffset.y + self.bounds.size.height < self.contentSize.height) {//向下滚动最大范围限制
            [self setContentOffset:CGPointMake(0, self.contentOffset.y + autoRollCellSpeed)];
            self.screenshotView.center = CGPointMake(self.screenshotView.center.x, self.screenshotView.center.y + autoRollCellSpeed);
        }
    }
    
    
     // 手动触发
    self.relocatedIndexPath = [self indexPathForRowAtPoint:self.screenshotView.center];
    if (self.relocatedIndexPath && ![self.relocatedIndexPath isEqual:self.originalIndexPath]) {
        [self cellRelocatedToNewIndexPath:self.relocatedIndexPath];
    }
}

@end
