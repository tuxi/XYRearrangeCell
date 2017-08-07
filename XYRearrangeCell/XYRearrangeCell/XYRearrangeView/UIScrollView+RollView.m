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

@interface UIView (XYScreenShotExtend)

/**
 对当前view进行截图
 @param shadowOpacity 阴影不透明度
 @param shadowColor 阴影的颜色
 @return 生成新的UIImageView对象
 */
- (UIImageView *)screenshotViewWithShadowOpacity:(CGFloat)shadowOpacity shadowColor:(UIColor *)shadowColor;

@end

@interface NSMutableArray (XYExchangeObjectExtend)
/**
 检查数组中的元素是否为数组类型
 */
- (BOOL)xy_isArrayInChildElement;
/**
 *  将可变数组中的一个对象移动到该数组中的另外一个位置
 *  @param fromIndex 从这个index
 *  @param toIndex   移至这个index
 */
- (void)exchangeObjectFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
@end

@interface UIScrollView ()

/** 对被选中的cell的截图 */
@property (nonatomic, strong) UIView *screenshotView;
/** 被选中的cell的原始位置 */
@property (nonatomic, strong) NSIndexPath *originalIndexPath;
/** 被选中的cell的新位置 */
@property (nonatomic, strong) NSIndexPath *relocatedIndexPath;
/** cell被拖动到边缘后开启，tableview自动向上或向下滚动 */
@property (nonatomic, strong) CADisplayLink *autoScrollTimer;
 /** 记录手指所在的位置 */
@property (nonatomic, assign) CGPoint fingerLocation;
/** 自动滚动的方向 */
@property (nonatomic, assign) XYRollViewScreenshotMeetsEdge autoScrollDirection;
/** 长按cell时触发的手势 */
@property (nonatomic, strong) UILongPressGestureRecognizer *longPress;
/** cell 在滚动交换时发送改变的临时数组 */
@property (nonatomic, strong) NSMutableArray *rollingTempArray;
/** 回调重新排列的数据给外界 作用:外界拿到新的数据后，更新数据源，刷新表格即可展示 */
@property (nonatomic, copy) __nullable XYRollNewDataBlock newDataBlock;
/** 返回外界的数据给当前类 作用:在移动cell数据发生改变时，拿到外界的数据重新排列数据 */
@property (nonatomic, copy) __nullable XYRollOriginalDataBlock originalDataBlock;
/** 交换cell中的回调，调用多次 */
@property (nonatomic, copy) __nullable XYRollingBlock rollingBlock;

@end


@implementation UIScrollView (XYRollView)

////////////////////////////////////////////////////////////////////////
#pragma mark - Public methods
////////////////////////////////////////////////////////////////////////


- (void)xy_rollViewFormOriginalDataSourceBlock:(nullable XYRollOriginalDataBlock)originalDataBlock
                            newDataSourceBlock:(nullable XYRollNewDataBlock)newDataBlock {
    
    [self xy_rollViewFormOriginalDataSourceBlock:originalDataBlock
                                    rollingBlock:nil newDataSourceBlock:newDataBlock];
}

- (void)xy_rollViewFormOriginalDataSourceBlock:(nullable XYRollOriginalDataBlock)originalDataBlock
                                  rollingBlock:(nullable XYRollingBlock)rollingBlock
                            newDataSourceBlock:(nullable XYRollNewDataBlock)newDataBlock {
    if (![self isKindOfClass:[UITableView class]] && ![self isKindOfClass:[UICollectionView class]]) {
        return;
    }
    
    self.originalDataBlock = originalDataBlock;
    self.newDataBlock = newDataBlock;
    self.rollingBlock = rollingBlock;
    [self longPress];

}

////////////////////////////////////////////////////////////////////////
#pragma mark - Events
////////////////////////////////////////////////////////////////////////

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
    
    if (state == UIGestureRecognizerStateBegan) {
        // 获取originalIndexPath，注意容错处理，因为可能为nil
        self.originalIndexPath = tableView ? [tableView indexPathForRowAtPoint:self.fingerLocation] : [collectionView indexPathForItemAtPoint:self.fingerLocation];
        if (self.originalIndexPath) {
            //手势开始，对被选中cell截图，隐藏原cell
            [self cellSelectedAtIndexPath:self.originalIndexPath];
        }
        
    } else if (state == UIGestureRecognizerStateChanged) {
        // 长按手势开始移动，判断手指按住位置是否进入其它indexPath范围，若进入则更新数据源并移动cell
        // 截图跟随手指移动
        [UIView animateWithDuration:0.1 animations:^{
            self.screenshotView.center = self.fingerLocation;
        }];

        // 检测是否到达边缘，如果到达边缘就开始运行定时器,自动滚动
        if ([self checkIfScreenshotViewMeetsEdge]) {
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
        // 其他情况，比如长按手势结束或被取消，移除截图，显示cell
        [self stopAutoScrollTimer];
        [self didEndDraging];
        
    }
    
    
    
}


////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////


- (void)startAutoScrollTimer{
    if (!self.autoScrollTimer) {
        self.autoScrollTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(startAutoScrollCell)];
        [self.autoScrollTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void)stopAutoScrollTimer {
    if (self.autoScrollTimer) {
        [self.autoScrollTimer invalidate];
        self.autoScrollTimer = nil;
    }
}


////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

// 修改数据后回调给外界，外界更新数据
- (void)_updateRollingDataSource {
    
    if (!self.rollingTempArray) {
        self.rollingTempArray = [NSMutableArray array];
    }
    
    [self.rollingTempArray removeAllObjects];
    if (self.originalDataBlock) {
        //通过originalDataBlock获得原始的数据
        [self.rollingTempArray addObjectsFromArray:self.originalDataBlock()];
    }
    //判断原始数据是否为嵌套数组
    if ([self.rollingTempArray xy_isArrayInChildElement]) {
        //是嵌套数组
        if (self.originalIndexPath.section == self.relocatedIndexPath.section) {
            //在同一个section内
            [self.rollingTempArray[self.originalIndexPath.section] exchangeObjectFromIndex:self.originalIndexPath.row toIndex:self.relocatedIndexPath.row];
        } else {
            //不在同一个section内
            // 容错处理：当外界的数组实际类型不是NSMutableArray时，将其转换为NSMutableArray
            id originalObj = self.rollingTempArray[self.originalIndexPath.section][self.originalIndexPath.item];
            [self.rollingTempArray[self.relocatedIndexPath.section] insertObject:originalObj atIndex:self.relocatedIndexPath.item];
            [self.rollingTempArray[self.originalIndexPath.section] removeObjectAtIndex:self.originalIndexPath.item];
        }
    } else {
        //不是嵌套数组
        [self.rollingTempArray exchangeObjectFromIndex:self.originalIndexPath.row toIndex:self.relocatedIndexPath.row];
    }
    
    if (self.rollingBlock) {
        self.rollingBlock();
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
    
    UIView *screenshotView = [cell screenshotViewWithShadowOpacity:self.rollIngShadowOpacity shadowColor:self.rollingColor];
    [self addSubview:screenshotView];
    self.screenshotView = screenshotView;
    cell.hidden = YES;
//    CGPoint center = self.screenshotView.center;
//    center.y = self.fingerLocation.y;
    [UIView animateWithDuration:0.2 animations:^{
        self.screenshotView.transform = CGAffineTransformMakeScale(1.03, 1.03);
        self.screenshotView.alpha = 0.98;
        self.screenshotView.center = cell.center;
    }];
    
}
/**
 *  截图被移动到新的indexPath范围，这时先更新数据源，重排数组，再将cell移至新位置
 *  @param indexPath 新的indexPath
 */
- (void)cellRelocatedToNewIndexPath:(NSIndexPath *)indexPath{
    //更新数据源并返回给外部
    [self _updateRollingDataSource];
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
    
    // 通过block将新数组回调给外界以更改数据源，
    if (self.newDataBlock) {
        self.newDataBlock(self.rollingTempArray);
    }
    
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
- (BOOL)checkIfScreenshotViewMeetsEdge{
    
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
- (void)startAutoScrollCell {
    
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


////////////////////////////////////////////////////////////////////////
#pragma mark - set \ get
////////////////////////////////////////////////////////////////////////

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


- (void)setLongPress:(UILongPressGestureRecognizer *)longPress {
    objc_setAssociatedObject(self, @selector(longPress), longPress, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UILongPressGestureRecognizer *)longPress {
    UILongPressGestureRecognizer *longPress = objc_getAssociatedObject(self, _cmd);
    if (!longPress) {
        longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressGestureRecognized:)];
        [self addGestureRecognizer:longPress];
        self.longPress = longPress;
    }
    return longPress;
}


- (void)setRollingTempArray:(NSMutableArray *)rollingTempArray {
    objc_setAssociatedObject(self, @selector(rollingTempArray), rollingTempArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableArray *)rollingTempArray {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setRollingBlock:(XYRollingBlock)rollingBlock {
    objc_setAssociatedObject(self, @selector(rollingBlock), rollingBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (XYRollingBlock)rollingBlock {
    return objc_getAssociatedObject(self, _cmd);
}

@end


@implementation UIView (XYScreenShotExtend)

////////////////////////////////////////////////////////////////////////
#pragma mark - screen shot
////////////////////////////////////////////////////////////////////////

- (UIImageView *)screenshotViewWithShadowOpacity:(CGFloat)shadowOpacity shadowColor:(UIColor *)shadowColor {
    
    // 开启图形上下文
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // 通过图形上下文生成的图片，创建一个和图片尺寸相同大小的imageView，将其作为截图返回
    UIImageView *screenshotView = [[UIImageView alloc] initWithImage:image];
    screenshotView.center = self.center;
    screenshotView.layer.masksToBounds = NO;
    screenshotView.layer.cornerRadius = 0.0;
    screenshotView.layer.shadowOffset = CGSizeMake(-5.0, 0.0);
    screenshotView.layer.shadowRadius = 5.0;
    screenshotView.layer.shadowOpacity = shadowOpacity;
    screenshotView.layer.shadowColor = shadowColor.CGColor;
    return screenshotView;
}


@end

@implementation NSMutableArray (XYExchangeObjectExtend)

- (void)exchangeObjectFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
    NSParameterAssert([self isKindOfClass:[NSMutableArray class]]);
    if (fromIndex < toIndex) {
        for (NSInteger i = fromIndex; i < toIndex; i++) {
            [self exchangeObjectAtIndex:i withObjectAtIndex:i + 1];
        }
    } else {
        for (NSInteger i = fromIndex; i > toIndex; i--) {
            [self exchangeObjectAtIndex:i withObjectAtIndex:i - 1];
        }
    }
}


- (BOOL)xy_isArrayInChildElement {
    NSInteger founIdx = [self indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL res = [obj isKindOfClass:[NSArray class]];
        if (res) {
            *stop = YES;
        }
        return res;
    }];
    return founIdx != NSNotFound;
}


@end
