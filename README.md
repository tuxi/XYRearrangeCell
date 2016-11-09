## XYRearrangeCell
* 简单实现：拖动cell时对其重新排列位置(适用collectionView和tableView)

![image](https://github.com/Ossey/XYRearrangeCell/blob/master/2016-11-09%2000_03_21.gif)



## Features(特征) 
* 在不影响原有类的情况下，直接调用UIView的1个分类方法即可实现:长按cell拖动时对其进行重新排列

* 支持collectionView和tableView的分组和非分组样式

* 在长按cell进行拖动时，内部会拿到当前的数据进行处理，最后通过block回调处理完成的数据给外界，外界刷新数据

* 由于刷新的是模型数据，所以不不必担心cell循环利用问题

* 一行代码即可实现

* 支持iOS7以上


## Usage(使用方法)

* 将XYRearrangeView文件拖到项目中，导入头文件
* tableView和collectionView都可以调用这个方法即可实现

```
#import "XYRearrangeView.h"

[self.tableView xy_rollViewOriginalDataBlock:^NSArray *{
		// 返回当前的数据给tableView内部处理
        return self.plans; 
    } callBlckNewDataBlock:^(NSArray *newData) {
        // 回调处理完成的数据给外界
        [self.plans removeAllObjects];
        [self.plans addObjectsFromArray:newData];
    }];    
```


## Other(其他用法)
* 上面的使用方法是在当前控制器的view就是tableView或collectionView时调用方法，您也可以使用类方法，创建对象时调用更方便,比如以下:

```
UICollectionView *collectionView = [UICollectionView xy_collectionViewLayout:flowLayout originalDataBlock:^NSArray *{
        return self.plans;
    } callBlckNewDataBlock:^(NSArray *newData) {
        [self.plans removeAllObjects];
        [self.plans addObjectsFromArray:newData];
    }];

```

* autoRollCellSpeed: cell拖拽到屏幕边缘时，控制其他cell的滚动速度:
数值越大滚动越快，默认为5.0，注意临界点的值，如果要设置为0时，设置为0.01才有效,最大为15

```
@property CGFloat autoRollCellSpeed;

```
* 注意: 使用时不用调用reload，内部已经处理了

## Prepare(准备增加左滑删除及右滑收藏功能)
* 已实现普通的左滑删除)


![image](https://github.com/Ossey/XYRearrangeCell/blob/master/2016-11-09%2000_06_42.gif)


