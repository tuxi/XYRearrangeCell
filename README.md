## XYRearrangeCell
* 简单实现：拖动cell时对其重新排列位置(适用collectionView和tableView)

![image](https://github.com/Ossey/XYRearrangeCell/blob/master/XYRearrangeCell/XYRearrangeCell/2016-11-09 00_03_21.gif)



## Features(特征) 
* 在不影响原有类的情况下，直接调用UIView的1个分类方法即可实现:长按cell拖动时对其进行重新排列

* 支持collectionView和tableView的分组和非分组样式

* 在长按cell进行拖动时，内部会拿到当前的数据进行处理，最后通过block回调处理完成的数据给外界，外界刷新数据

* 由于刷新的是模型数据，所以不不必担心cell循环利用问题

* 一行代码即可实现

* 支持iOS7以上


## Usage(使用方法)


```
#import "UIScrollView+RollView.h"

[self.tableView xy_rollViewFormOriginalDataSourceBlock:^NSArray *{
        // 返回当前的数据给tableView内部处理
        return self.plans; 
    } newDataSourceBlock:^(NSArray *newData) {
        // 回调处理完成的数据给外界
        [self.plans removeAllObjects];
        [self.plans addObjectsFromArray:newData];
    }];

```



* autoRollCellSpeed: cell拖拽到屏幕边缘时，控制其他cell的滚动速度:
数值越大滚动越快，默认为5.0, 最大为15

```
@property CGFloat autoRollCellSpeed;

```


![image](https://github.com/Ossey/XYRearrangeCell/blob/master/XYRearrangeCell/XYRearrangeCell/2016-11-09 00_06_42.gif)


