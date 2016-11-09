//
//  UIView+XYRollView.h
//  XYRrearrangeCell
//  
//  Created by mofeini on 16/11/7.
//  Copyright © 2016年 com.test.demo. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void(^XYRollNewDataBlock)(NSArray * __nullable newData);
typedef NSArray *__nonnull(^XYRollOriginalDataBlock)();

@interface UIView (RollView)

/**
 回调重新排列的数据给外界
 作用:外界拿到新的数据后，更新数据源，刷新表格即可展示
 */
@property __nullable XYRollNewDataBlock newDataBlock;

/**
 返回外界的数据给当前类
 作用:在移动cell数据发生改变时，拿到外界的数据重新排列数据
 */
@property XYRollOriginalDataBlock  __nullable originalDataBlock;

/**
 cell在滚动时的阴影颜色,默认为黑色
 */
@property UIColor * __nullable rollingColor;
/**
 cell在滚动时的阴影的不透明度,默认为0.3
 注意:如果要设置临界点的值，比如0，请设置0.01，因为只要传0时，就默认设置为0.3了
 */
@property CGFloat rollIngShadowOpacity;

/**
 快速创建方法
 originalDataBlock:有返回值，返回外界的数据
 newDataBlock:     无返回值，回调当前类重新排列的数据给外界
 return:           XYRollView
 注意:外界的数据类型如果是数组中嵌套数据的，需要将嵌套的数组转换为可变数组添加到大数组中，不然当前方法对外界的数组进入重排列时会报错
 */
+ (nonnull instancetype)xy_rollViewWithOriginalDataBlock:(nullable XYRollOriginalDataBlock)originalDataBlock
                         callBlckNewDataBlock:(nullable XYRollNewDataBlock)newDataBlock;

- (nonnull instancetype)initWithOriginalDataBlock:(nullable XYRollOriginalDataBlock)originalDataBlock
                     callBlckNewDataBlock:(nullable XYRollNewDataBlock)newDataBlock;

+ (nonnull instancetype)xy_rollView;

- (void)xy_rollViewOriginalDataBlock:(nullable XYRollOriginalDataBlock)originalDataBlock
                callBlckNewDataBlock:(nullable XYRollNewDataBlock)newDataBlock;

/** 
 返回一个给定view的截图
 */
- (__kindof UIView * __nonnull)xy_customScreenshotViewFromView:(__kindof UIView * __nullable)inputView;

/**
 *  将可变数组中的一个对象移动到该数组中的另外一个位置
 *  array     要变动的数组
 *  fromIndex 从这个index
 *  toIndex   移至这个index
 */
- (void)xy_moveObjectInMutableArray:(nonnull NSMutableArray *)array fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;

/**
 *  检查数组是否为嵌套数组
 *  array 需要被检测的数组
 *  返回YES则表示是嵌套数组
 */
- (BOOL)xy_nestedArrayCheck:(nonnull NSArray *)array;

@end
