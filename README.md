## XYRearrangeCell
* 非常简单的实现：拖动cell时对其重新排列位置

![https://github.com/Ossey/XYRearrangeCell/blob/master/2016-11-08%2018_07_08.gif](https://github.com/Ossey/XYRearrangeCell/blob/master/2016-11-08%2018_07_08.gif)



## Features(特征) 
* 在不影响原有类的情况下直接调用一个方法即可实现:长按cell拖动时对其进行重新排列

* 支持collectionView和tableView的分组和非分组类型

* 一行代码即可

## Usage(使用方法)

* 将XYRearrangeCell文件拖到项目中，导入头文件

```
	#import "XYRearrangeCell.h"

```

```

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


## Prepare(准备增加左滑删除及右滑收藏功能)
* 已实现普通的左滑删除)




