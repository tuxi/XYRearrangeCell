//
//  UIView+XYRollView.h
//  XYRrearrangeCell
//  
//  Created by mofeini on 16/11/7.
//  Copyright © 2016年 com.test.demo. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, XYRollViewScreenshotMeetsEdge) {
    XYRollViewScreenshotMeetsEdgeNone = 0,     // 选中cell的截图没有到达父控件边缘
    XYRollViewScreenshotMeetsEdgeTop,          // 选中cell的截图到达父控件顶部边缘
    XYRollViewScreenshotMeetsEdgeBottom,       // 选中cell的截图到达父控件底部边缘
    XYRollViewScreenshotMeetsEdgeLeft,         // 选中cell的截图到达父控件左侧边缘
    XYRollViewScreenshotMeetsEdgeRight,        // 选中cell的截图到达父控件右侧边缘
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

/**
 @param originalDataBlock 源数据源
 @param newDataBlock     滚动完后的最终数据源，该block只会回调一次
 注意:外界的数据类型如果是数组中嵌套数据的，需要将嵌套的数组转换为可变数组添加到大数组中，不然当前方法对外界的数组进入重排列时会报错
 */
- (void)xy_rollViewFormOriginalDataSourceBlock:(nullable XYRollOriginalDataBlock)originalDataBlock
                            newDataSourceBlock:(nullable XYRollNewDataBlock)newDataBlock;

- (void)xy_rollViewFormOriginalDataSourceBlock:(nullable XYRollOriginalDataBlock)originalDataBlock
                                  rollingBlock:(nullable XYRollingBlock)rollingBlock
                            newDataSourceBlock:(nullable XYRollNewDataBlock)newDataBlock;



@end

NS_ASSUME_NONNULL_END
