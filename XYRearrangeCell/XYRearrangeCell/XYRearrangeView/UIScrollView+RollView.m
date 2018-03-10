//
//  UIView+XYRollView.m
//  XYRrearrangeCell
//  
//  Created by Ossey on 16/11/7.
//  Copyright © 2016年 Ossey. All rights reserved.
//

#import "UIScrollView+RollView.h"
#import <objc/runtime.h>

typedef NS_ENUM(NSInteger, XYRollViewautoScrollDirection) {
    XYRollViewautoScrollDirectionNone = 0,     // 选中cell的截图没有到达父控件边缘
    XYRollViewautoScrollDirectionTop,          // 选中cell的截图到达父控件顶部边缘
    XYRollViewautoScrollDirectionBottom,       // 选中cell的截图到达父控件底部边缘
    XYRollViewautoScrollDirectionLeft,         // 选中cell的截图到达父控件左侧边缘
    XYRollViewautoScrollDirectionRight,        // 选中cell的截图到达父控件右侧边缘
};


char * const XYRollViewNewDataBlockKey = "XYRollViewNewDataBlockKey";
char * const XYRollViewOriginalDataBlockKey = "XYRollViewOriginalDataBlockKey";
char * const XYRollViewRollingColorKey = "XYRollViewRollingColorKey";
char * const XYRollViewRollIngShadowOpacityKey = "XYRollViewRollIngShadowOpacityKey";

char * const XYRollViewScreenshotViewKey = "XYRollViewScreenshotViewKey";
char * const XYRollViewBeginRollIndexPathKey = "XYRollViewBeginRollIndexPathKey";
char * const XYRollViewNewRollIndexPathKey = "XYRollViewNewRollIndexPathKey";
char * const XYRollViewDisplayLinkKey = "XYRollViewDisplayLinkKey";
char * const XYRollViewautoScrollDirectionKey = "XYRollViewautoScrollDirectionKey";
char * const XYRollViewAutoRollCellSpeedKey   = "XYRollViewAutoRollCellSpeedKey";
char * const XYRollViewUpdateDataGroupKey = "XYRollViewUpdateDataGroupKey";
char * const XYRollViewLastRollIndexPath = "XYRollViewLastRollIndexPath";

#define XY_ROLLVIEW_SELF \
UITableView *tableView = nil;\
UICollectionView *collectionView = nil;\
if ([self isKindOfClass:[UICollectionView class]]) {\
    collectionView = (UICollectionView *)self;\
}\
else if ([self isKindOfClass:[UITableView class]]) {\
    tableView = (UITableView *)self;\
}

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
 *  @param fromIndex 开始的index
 *  @param toIndex   目的index
 */
- (void)exchangeObjectFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
@end

@interface UIScrollView () <UIGestureRecognizerDelegate>

/** 对被选中的cell的截图 */
@property (nonatomic, strong) UIView *xy_screenshotView;
/** 被选中的cell的原始位置，这个值是手机开始拖动cell时记录的原始值，只有下次开始拖动时才会被更改 */
@property (nonatomic, strong) NSIndexPath *beginRollIndexPath;
/** 开始移动的起始位置，这个值会随时改变 */
@property (nonatomic, strong) NSIndexPath *lastRollIndexPath;
/** 记录被选中的cell的新位置，手指移动时会从lastRollIndexPath移动到xy_newRollIndexPath */
@property (nonatomic, strong) NSIndexPath *xy_newRollIndexPath;
/** cell被拖动到边缘后开启，tableview自动向上或向下滚动 */
@property (nonatomic, strong) CADisplayLink *xy_displayLink;
 /** 记录手指所在的位置 */
@property (nonatomic, assign) CGPoint xy_fingerPosition;
/** 自动滚动的方向 */
@property (nonatomic, assign) XYRollViewautoScrollDirection xy_autoScrollDirection;
/** 长按cell时触发的手势 */
@property (nonatomic, strong, readonly) UILongPressGestureRecognizer *xy_longPress;
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
    [self xy_longPress];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Events
////////////////////////////////////////////////////////////////////////


- (void)xy_longPressGestureRecognized:(UILongPressGestureRecognizer *)longPress {
    if (![self isKindOfClass:[UITableView class]] &&
        ![self isKindOfClass:[UICollectionView class]]) {
        return;
    }
    
    UITableView *tableView = nil;
    UICollectionView *collectionView = nil;
    if ([self isKindOfClass:[UICollectionView class]]) {
        collectionView = (UICollectionView *)self;
    }
    else if ([self isKindOfClass:[UITableView class]]) {
        tableView = (UITableView *)self;
    }
    
#warning Mark: iOS11 下 locationInView:bug 获取当前手指所在的点存在错误，导致瞬间移动乱窜，待解决
    // 获取手指在rollView上的坐标
    CGPoint fingerPosition = [longPress locationInView:longPress.view];
    NSLog(@"xy_fingerPosition:(%@)", NSStringFromCGPoint(self.xy_fingerPosition));
//    if (!CGPointEqualToPoint(self.xy_fingerPosition, CGPointZero) && fingerPosition.y - self.xy_fingerPosition.y >= 100) {
////        return;
//    }
    self.xy_fingerPosition = fingerPosition;
    
    // 手指按住位置对应的indexPath，可能为nil
    self.xy_newRollIndexPath = tableView ? [tableView indexPathForRowAtPoint:self.xy_fingerPosition] : [collectionView indexPathForItemAtPoint:self.xy_fingerPosition];
    
    
    if (longPress.state == UIGestureRecognizerStateBegan) {
        // 获取beginRollIndexPath，注意容错处理，因为可能为nil
        self.beginRollIndexPath = tableView ? [tableView indexPathForRowAtPoint:self.xy_fingerPosition] : [collectionView indexPathForItemAtPoint:self.xy_fingerPosition];
        self.lastRollIndexPath = self.beginRollIndexPath;
        if (self.lastRollIndexPath) {
            //手势开始，对被选中cell截图，隐藏原cell
            [self cellSelectedAtIndexPath:self.lastRollIndexPath];
        }
        
    }
    else if (longPress.state == UIGestureRecognizerStateChanged) {
        // 长按手势开始移动，判断手指按住位置是否进入其它indexPath范围，若进入则更新数据源并移动cell
        // 截图跟随手指移动
        [UIView animateWithDuration:0.1 animations:^{
            CGPoint xy_screenshotViewCenter = self.xy_screenshotView.center;
            switch (self.rollDirection) {
                case XYRollViewScrollDirectionNotKnow: {
                    xy_screenshotViewCenter.x = self.xy_fingerPosition.x;
                    xy_screenshotViewCenter.y = self.xy_fingerPosition.y;
                } break;
                case XYRollViewScrollDirectionHorizontal: {
                    xy_screenshotViewCenter.x = self.xy_fingerPosition.x;
                } break;
                case XYRollViewScrollDirectionVertical: {
                    xy_screenshotViewCenter.y = self.xy_fingerPosition.y;
                } break;
                default:
                    break;
            }
            self.xy_screenshotView.center = xy_screenshotViewCenter;
        }];
        
        //手指按住位置对应的indexPath，可能为nil
        self.xy_newRollIndexPath = tableView ? [tableView indexPathForRowAtPoint:self.xy_fingerPosition] : [collectionView indexPathForItemAtPoint:self.xy_fingerPosition];
        if (self.xy_newRollIndexPath &&
            ![self.xy_newRollIndexPath isEqual:self.lastRollIndexPath]) {
            // 移动cell到新的位置
            [self moveCellToNewIndexPath:self.xy_newRollIndexPath];
        }
        // 检测是否到达边缘，如果到达边缘就开始运行定时器,自动滚动
        if ([self checkIfScreenshotViewMeetsEdge]) {
            [self startAutoScroll];
        }
        else {
            [self stopAutoScroll];
        }
    }
    else {
        // 其他情况，比如长按手势结束或被取消，移除截图，显示cell
        [self stopAutoScroll];
        [self rollingCellDidEndScroll];
        
    }
    
    
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////


- (void)startAutoScroll {
    if (!self.xy_displayLink) {
        self.xy_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(startAutoScrollCell)];
        [self.xy_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void)stopAutoScroll {
    if (self.xy_displayLink) {
        [self.xy_displayLink invalidate];
        self.xy_displayLink = nil;
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
        NSArray *orginalArray = self.originalDataBlock();
        [self.rollingTempArray addObjectsFromArray:orginalArray];
    }
    //判断原始数据是否为嵌套数组
    if ([self.rollingTempArray xy_isArrayInChildElement]) {
        //是嵌套数组
        if (self.lastRollIndexPath.section == self.xy_newRollIndexPath.section) {
            //在同一个section内
            [self.rollingTempArray[self.lastRollIndexPath.section] exchangeObjectFromIndex:self.lastRollIndexPath.row toIndex:self.xy_newRollIndexPath.row];
        }
        else {
            //不在同一个section内
            // 容错处理：当外界的数组实际类型不是NSMutableArray时，将其转换为NSMutableArray
            id originalObj = self.rollingTempArray[self.lastRollIndexPath.section][self.lastRollIndexPath.item];
            [self.rollingTempArray[self.xy_newRollIndexPath.section] insertObject:originalObj atIndex:self.xy_newRollIndexPath.item];
            [self.rollingTempArray[self.lastRollIndexPath.section] removeObjectAtIndex:self.lastRollIndexPath.item];
        }
    }
    else {
        //不是嵌套数组
        [self.rollingTempArray exchangeObjectFromIndex:self.lastRollIndexPath.row toIndex:self.xy_newRollIndexPath.row];
    }
    
    if (self.rollingBlock) {
        self.rollingBlock();
    }
}



// cell被长按手指选中，对其进行截图，原cell隐藏
- (void)cellSelectedAtIndexPath:(NSIndexPath *)indexPath {
    if (self.xy_screenshotView) {
        [self.xy_screenshotView removeFromSuperview];
        self.xy_screenshotView = nil;
    }
    UIView *cell = [self cellForIndexPath:indexPath];
    UIView *screenshotView = [cell screenshotViewWithShadowOpacity:self.rollIngShadowOpacity shadowColor:self.rollingColor];
    [self addSubview:screenshotView];
    [self bringSubviewToFront:screenshotView];
    self.xy_screenshotView = screenshotView;
    cell.hidden = YES;
    [UIView animateWithDuration:0.2 animations:^{
        self.xy_screenshotView.transform = CGAffineTransformMakeScale(1.03, 1.03);
        self.xy_screenshotView.alpha = 0.98;
        self.xy_screenshotView.center = cell.center;
    }];
    
}

- (UIView *)cellForIndexPath:(NSIndexPath *)indexPath {
    UIView *cell = nil;
    if ([self isKindOfClass:[UITableView class]]) {
        cell = [(UITableView *)self cellForRowAtIndexPath:indexPath];
    }
    else if ([self isKindOfClass:[UICollectionView class]]) {
        cell = [(UICollectionView *)self cellForItemAtIndexPath:indexPath];
    }
    return cell;
}

/**
 *  截图被移动到新的indexPath范围，这时先更新数据源，重排数组，再将cell移至新位置
 *  @param newIndexPath 新的indexPath
 */
- (void)moveCellToNewIndexPath:(NSIndexPath *)newIndexPath{
//    NSLog(@"lastRollIndexPath:%@-------newIndexPath:%@", self.lastRollIndexPath, newIndexPath);
    // 更新数据源并返回给外部
    [self _updateRollingDataSource];
    // 通过block将新数组回调给外界以更改数据源，
    if (self.newDataBlock) {
        self.newDataBlock(self.rollingTempArray);
    }
    
    if ([newIndexPath isEqual:[NSIndexPath indexPathForRow:15 inSection:0]] || [newIndexPath isEqual:[NSIndexPath indexPathForRow:14 inSection:0]] || [newIndexPath isEqual:[NSIndexPath indexPathForRow:16 inSection:0]]) {
        NSLog(@"");
//        return;
    }
    //交换移动cell位置
    if ([self isKindOfClass:[UITableView class]]) {
        [(UITableView *)self moveRowAtIndexPath:self.lastRollIndexPath toIndexPath:newIndexPath];
    }
    else if ([self isKindOfClass:[UICollectionView class]]) {
        [(UICollectionView *)self moveItemAtIndexPath:self.lastRollIndexPath toIndexPath:newIndexPath];
    }
        
    // 更新lastRollIndexPath当前indexPath
    self.lastRollIndexPath = newIndexPath;
}

// 拖拽结束，显示cell，并移除截图
- (void)rollingCellDidEndScroll {
    
    UIView *cell = [self cellForIndexPath:self.lastRollIndexPath];
    
    cell.hidden = NO;
    cell.alpha = 0;
    [UIView animateWithDuration:0.2 animations:^{
        self.xy_screenshotView.center = cell.center;
        self.xy_screenshotView.alpha = 0;
        self.xy_screenshotView.transform = CGAffineTransformIdentity;
        cell.alpha = 1;
        cell.hidden = NO;
    } completion:^(BOOL finished) {
        [self.xy_screenshotView removeFromSuperview];
//        // 更新数据源并返回给外部
//        [self _updateRollingDataSource];
//        // 通过block将新数组回调给外界以更改数据源，
//        if (self.newDataBlock) {
//            self.newDataBlock(self.rollingTempArray);
//        }
        self.xy_screenshotView = nil;
        self.beginRollIndexPath = nil;
        self.xy_newRollIndexPath = nil;
        self.lastRollIndexPath = nil;
        self.xy_fingerPosition = CGPointZero;
    }];
    
}


// 检查截图是否到达边缘，并作出响应
- (BOOL)checkIfScreenshotViewMeetsEdge {
    
    CGFloat minY = CGRectGetMinY(self.xy_screenshotView.frame);
    CGFloat maxY = CGRectGetMaxY(self.xy_screenshotView.frame);
    CGFloat MinX = CGRectGetMinX(self.xy_screenshotView.frame);
    CGFloat maxX = CGRectGetMaxX(self.xy_screenshotView.frame);
    if (minY < self.contentOffset.y) {
        self.xy_autoScrollDirection = XYRollViewautoScrollDirectionTop;
        return YES;
    }
    if (maxY > self.bounds.size.height + self.contentOffset.y) {
        self.xy_autoScrollDirection = XYRollViewautoScrollDirectionBottom;
        return YES;
    }
    if ([self isKindOfClass:[UICollectionView class]]) {
        UICollectionView *collectionView = (UICollectionView *)self;
        UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)collectionView.collectionViewLayout;
        if (flowLayout.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
            if (MinX < self.contentOffset.x) {
                self.xy_autoScrollDirection = XYRollViewautoScrollDirectionLeft;
                return YES;
            }
            if (maxX > self.bounds.size.width + self.contentOffset.x) {
                self.xy_autoScrollDirection = XYRollViewautoScrollDirectionRight;
                return YES;
            }
        }
        
    }
    
    self.xy_autoScrollDirection = XYRollViewautoScrollDirectionNone;
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
    
    if ((self.rollDirection == XYRollViewScrollDirectionVertical || self.rollDirection == XYRollViewScrollDirectionNotKnow) &&
        self.xy_autoScrollDirection == XYRollViewautoScrollDirectionTop) {//向上滚动
        //向上滚动最大范围限制
        if (self.contentOffset.y > 0) {
            
            self.contentOffset = CGPointMake(0, self.contentOffset.y - autoRollCellSpeed);
            self.xy_screenshotView.center = CGPointMake(self.xy_screenshotView.center.x, self.xy_screenshotView.center.y - autoRollCellSpeed);
        }
    } else if ((self.rollDirection == XYRollViewScrollDirectionVertical || self.rollDirection == XYRollViewScrollDirectionNotKnow) &&
               self.xy_autoScrollDirection == XYRollViewautoScrollDirectionBottom) { // 向下滚动
        //向下滚动最大范围限制
        if (self.contentOffset.y + self.bounds.size.height < self.contentSize.height) {
            
            self.contentOffset = CGPointMake(0, self.contentOffset.y + autoRollCellSpeed);
            self.xy_screenshotView.center = CGPointMake(self.xy_screenshotView.center.x, self.xy_screenshotView.center.y + autoRollCellSpeed);
        }
    } else if (self.xy_autoScrollDirection == XYRollViewautoScrollDirectionLeft) {
        // 向左滚动滚动的最大范围限制
        if (self.contentOffset.x > 0) {
            self.contentOffset = CGPointMake(self.contentOffset.x - autoRollCellSpeed, 0);
            self.xy_screenshotView.center = CGPointMake(self.xy_screenshotView.center.x - autoRollCellSpeed, self.xy_screenshotView.center.y);
        }
    } else if (self.xy_autoScrollDirection == XYRollViewautoScrollDirectionRight) {
        
        // 向右滚动滚动的最大范围限制
        if (self.contentOffset.x + self.bounds.size.width < self.contentSize.width) {
            self.contentOffset = CGPointMake(self.contentOffset.x + autoRollCellSpeed, self.contentOffset.y);
            self.xy_screenshotView.center = CGPointMake(self.xy_screenshotView.center.x + autoRollCellSpeed, self.xy_screenshotView.center.y);
        }
    }
    
    //  当把截图拖动到边缘自动滚动,手指不动手时，手动触发
    if ([self isKindOfClass:[UITableView class]]) {
        
        self.xy_newRollIndexPath = [(UITableView *)self indexPathForRowAtPoint:self.xy_screenshotView.center];
    }
    else if ([self isKindOfClass:[UICollectionView class]]) {
        self.xy_newRollIndexPath = [(UICollectionView *)self indexPathForItemAtPoint:self.xy_screenshotView.center];
    }
    
    if (self.xy_newRollIndexPath &&
        ![self.xy_newRollIndexPath isEqual:self.lastRollIndexPath]) {
        [self moveCellToNewIndexPath:self.xy_newRollIndexPath];
    }
}


////////////////////////////////////////////////////////////////////////
#pragma mark - set \ get
////////////////////////////////////////////////////////////////////////

- (void)setXy_screenshotView:(UIView *)screenshotView {
    
    objc_setAssociatedObject(self, XYRollViewScreenshotViewKey, screenshotView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (UIView *)xy_screenshotView {
    return objc_getAssociatedObject(self, XYRollViewScreenshotViewKey);
}

- (void)setBeginRollIndexPath:(NSIndexPath *)beginRollIndexPath {
    objc_setAssociatedObject(self, XYRollViewBeginRollIndexPathKey, beginRollIndexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSIndexPath *)beginRollIndexPath {
    return objc_getAssociatedObject(self, XYRollViewBeginRollIndexPathKey);
}

- (void)setXy_newRollIndexPath:(NSIndexPath *)xy_newRollIndexPath {
    NSIndexPath *indexPath = [self xy_newRollIndexPath];
    if ([indexPath isEqual:xy_newRollIndexPath]) {
        return;
    }
    objc_setAssociatedObject(self, XYRollViewNewRollIndexPathKey, xy_newRollIndexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSIndexPath *)xy_newRollIndexPath {
    return objc_getAssociatedObject(self, XYRollViewNewRollIndexPathKey);
}

- (void)setXy_displayLink:(CADisplayLink *)xy_displayLink {
    objc_setAssociatedObject(self, XYRollViewDisplayLinkKey, xy_displayLink, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (CADisplayLink *)xy_displayLink {
    return objc_getAssociatedObject(self, XYRollViewDisplayLinkKey);
}

- (void)setXy_fingerPosition:(CGPoint)xy_fingerPosition {
    NSValue *pointValue = [NSValue valueWithCGPoint:xy_fingerPosition];
    objc_setAssociatedObject(self, @selector(xy_fingerPosition), pointValue, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (CGPoint)xy_fingerPosition {
    NSValue *pointValue = objc_getAssociatedObject(self, _cmd);
    CGPoint xy_fingerPosition = [pointValue CGPointValue];
    return xy_fingerPosition;
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

- (void)setXy_autoScrollDirection:(XYRollViewautoScrollDirection)autoScrollDirection {
    
    objc_setAssociatedObject(self, XYRollViewautoScrollDirectionKey, @(autoScrollDirection), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (XYRollViewautoScrollDirection)xy_autoScrollDirection {
    
    return [objc_getAssociatedObject(self, XYRollViewautoScrollDirectionKey) integerValue];;
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

- (void)setLastRollIndexPath:(NSIndexPath *)lastRollIndexPath {
    objc_setAssociatedObject(self, XYRollViewLastRollIndexPath, lastRollIndexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSIndexPath *)lastRollIndexPath {
    return objc_getAssociatedObject(self, XYRollViewLastRollIndexPath);
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
    CGFloat rollIngShadowOpacity = [objc_getAssociatedObject(self, XYRollViewRollIngShadowOpacityKey) doubleValue];
    if (rollIngShadowOpacity == 0.0) {
        return 0.3;
    }
    return rollIngShadowOpacity;
}

- (void)setRolleEnabled:(BOOL)rolleEnabled {
    self.xy_longPress.enabled = rolleEnabled;
}

- (BOOL)rolleEnabled {
    return self.xy_longPress.isEnabled;
}

- (UILongPressGestureRecognizer *)xy_longPress {
    UILongPressGestureRecognizer *longPress = objc_getAssociatedObject(self, _cmd);
    if (!longPress) {
        longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(xy_longPressGestureRecognized:)];
        [self addGestureRecognizer:longPress];
        longPress.delegate = self;
        
        // 当是侧滑手势的时候设置scrollview需要此手势失效才生效即可
        for (UIGestureRecognizer *gesture in self.gestureRecognizers) {
            if ([gesture isKindOfClass:[UIScreenEdgePanGestureRecognizer class]]) {
                [self.panGestureRecognizer requireGestureRecognizerToFail:gesture];
            }
        }
        objc_setAssociatedObject(self, _cmd, longPress, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return longPress;
}


- (void)setRollingTempArray:(NSMutableArray *)rollingTempArray {
    objc_setAssociatedObject(self, @selector(rollingTempArray), rollingTempArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (XYRollViewScrollDirection)rollDirection {
    XYRollViewScrollDirection rollDirection = 0;
    if ([self isKindOfClass:[UITableView class]]) {
        rollDirection = XYRollViewScrollDirectionVertical;
    }
    else if ([self isKindOfClass:[UICollectionView class]]) {
//        UICollectionView *collectionView = (UICollectionView *)self;
//        UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)collectionView.collectionViewLayout;
        rollDirection = XYRollViewScrollDirectionNotKnow;
//        if (flowLayout.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
//            rollDirection = XYRollViewScrollDirectionHorizontal;
//        }
//        else {
//            rollDirection = XYRollViewScrollDirectionVertical;
//        }
    }
    return rollDirection;
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
    UIImageView *screenshotImageView = [[UIImageView alloc] initWithImage:image];
    screenshotImageView.center = self.center;
    screenshotImageView.layer.masksToBounds = NO;
    screenshotImageView.layer.cornerRadius = 0.0;
    screenshotImageView.layer.shadowOffset = CGSizeMake(-5.0, 0.0);
    screenshotImageView.layer.shadowRadius = 5.0;
    screenshotImageView.layer.shadowOpacity = shadowOpacity;
    screenshotImageView.layer.shadowColor = shadowColor.CGColor;
    return screenshotImageView;
}


@end

@implementation NSMutableArray (XYExchangeObjectExtend)

- (void)exchangeObjectFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
    NSParameterAssert([self isKindOfClass:[NSMutableArray class]] || !self.count);
    if (fromIndex < toIndex) {
        for (NSInteger i = fromIndex; i < toIndex; i++) {
            [self exchangeObjectAtIndex:i withObjectAtIndex:i + 1];
        }
    }
    else {
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
