//
//  UIView+XYRollView.h
//  XYRrearrangeCell
//  
//  Created by Ossey on 16/11/7.
//  Copyright © 2016年 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, XYRollViewScrollDirection) {
    XYRollViewScrollDirectionAll,
    XYRollViewScrollDirectionVertical,
    XYRollViewScrollDirectionHorizontal
};

typedef void(^XYRollNewDataBlock)(NSArray * __nullable newData);
typedef NSArray *__nonnull(^XYRollOriginalDataBlock)();
typedef void(^XYRollingBlock)();

@interface UIScrollView (RollView)

/** cell在滚动时的阴影颜色,默认为黑色 */
@property (nonatomic, strong) UIColor * __nullable rollingColor;

/** cell在滚动时的阴影的不透明度,默认为0.3 */
@property (nonatomic, assign) CGFloat rollIngShadowOpacity;

/** cell拖拽到屏幕边缘时，其他cell的滚动速度，数值越大滚动越快，默认为5.0,最大为15 */
@property (nonatomic, assign) CGFloat autoRollCellSpeed;

/** cell拖拽时允许拖拽的方法 , 默认XYRollViewScrollDirectionAll*/
@property (nonatomic, assign) XYRollViewScrollDirection rollDirection;

/**
 @param originalDataBlock 源数据源
 @param newDataBlock     滚动完后的最终数据源，该block只会回调一次
 @discussion 外界的数据类型如果是数组中嵌套数据的，需要将嵌套的数组转换为可变数组添加到大数组中，不然当前方法对外界的数组进入重排列时会报错
 */
- (void)xy_rollViewFormOriginalDataSourceBlock:(nullable XYRollOriginalDataBlock)originalDataBlock
                            newDataSourceBlock:(nullable XYRollNewDataBlock)newDataBlock;

- (void)xy_rollViewFormOriginalDataSourceBlock:(nullable XYRollOriginalDataBlock)originalDataBlock
                                  rollingBlock:(nullable XYRollingBlock)rollingBlock
                            newDataSourceBlock:(nullable XYRollNewDataBlock)newDataBlock;



@end

NS_ASSUME_NONNULL_END
