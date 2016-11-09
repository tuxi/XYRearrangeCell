//
//  UIView+XYRollView.m
//  XYRrearrangeCell
//  
//  Created by mofeini on 16/11/7.
//  Copyright © 2016年 com.test.demo. All rights reserved.
//

#import "UIView+RollView.h"
#import <objc/runtime.h>


char * const XYRollViewNewDataBlockKey = "XYRollViewNewDataBlockKey";
char * const XYRollViewOriginalDataBlockKey = "XYRollViewOriginalDataBlockKey";
char * const XYRollViewRollingColorKey = "XYRollViewRollingColorKey";
char * const XYRollViewRollIngShadowOpacityKey = "XYRollViewRollIngShadowOpacityKey";

@interface UIView ()

@end
@implementation UIView (XYRollView)
#pragma mark - 关联属性
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


#pragma mark - 快速创建
+ (nonnull instancetype)xy_rollView {
    
    return [self xy_rollViewWithOriginalDataBlock:nil callBlckNewDataBlock:nil];
}
+ (nonnull instancetype)xy_rollViewWithOriginalDataBlock:(nullable XYRollOriginalDataBlock)originalDataBlock callBlckNewDataBlock:(nullable XYRollNewDataBlock)newDataBlock {
    
    return [[self alloc] initWithOriginalDataBlock:originalDataBlock callBlckNewDataBlock:newDataBlock];
}

- (void)xy_rollViewOriginalDataBlock:(nullable XYRollOriginalDataBlock)originalDataBlock callBlckNewDataBlock:(nullable XYRollNewDataBlock)newDataBlock {
    if (self == [self initWithOriginalDataBlock:originalDataBlock callBlckNewDataBlock:newDataBlock]) {
        self.originalDataBlock = originalDataBlock;
        self.newDataBlock = newDataBlock;
        
    }
    

}

- (nonnull instancetype)initWithOriginalDataBlock:(nullable XYRollOriginalDataBlock)originalDataBlock callBlckNewDataBlock:(nullable XYRollNewDataBlock)newDataBlock {
    
    if (self = [self init]) {
        
        self.originalDataBlock = originalDataBlock;
        self.newDataBlock = newDataBlock;
    }
    
    return self;
}

#pragma mark - 返回一个给定view的截图
- (__kindof UIView * __nonnull)xy_customScreenshotViewFromView:(__kindof UIView * __nullable)inputView {
    
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

@end
