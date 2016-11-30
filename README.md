##看多了大牛们的轮子，寻思着自己弄一个runtime的一些小轮子....

可能部分代码并不是原创，也有很多是参考自开源库，比如: YYKit ...大神只能膜拜... 算是站在巨人的肩膀上偷偷的学习吧~~~

主要是将一些常用的基于runtime的代码整合起来:

- (1) JSON 映射 Model （结束）
- (2) Copy （结束）
- (3) Archive （结束）
- (4) Protocol Observer (doing)
- (5) ORM	(没开始)
- (6) Cache (没开始)

把这些全部整合起来，就算是对自己这两年来搞iOS的交代吧，菜鸟成长记 . . . 

##JSON映射Model用法

实体类

```objc
@interface Cat : NSObject
@property (nonatomic, assign) NSInteger cid;
@property (nonatomic, copy) NSString *name;
@end

@interface Child : NSObject
@property (nonatomic, assign) NSInteger cid;
@property (nonatomic, copy) NSString *name;
@end

@interface Dog : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, copy) NSString *sex1;
@property (nonatomic, copy) NSString *sex2;
@property (nonatomic, copy) NSString *sex3;
@property (nonatomic, strong) Cat *cat;
@property (nonatomic, strong) NSArray *childs;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, assign) BOOL flag1;
@property (nonatomic, assign) BOOL flag2;
@property (nonatomic, assign) BOOL flag3;
@property (nonatomic, assign) BOOL flag4;
@property (nonatomic, assign) BOOL flag5;
@property (nonatomic, assign) int flag6;
@property (nonatomic, assign) NSInteger flag7;
@property (nonatomic, assign) BOOL flag8;
@end
```

```objc
@implementation Dog
+ (NSDictionary *)xzh_customerMappings {
    return @{
             // 属性 : json key
             @"age" : @"p_age",
             @"uid" : @"data.uid",
             @"address" : @[@"address1", @"address2", @"address3", @"user.city.address"],
             @"sex1" : @"sex",
             @"sex2" : @"sex",
             @"sex3" : @"sex",
             @"cat" : @"animal.cat",
             };
}
+ (NSDictionary *)xzh_containerClass {
    return @{
             @"childs" : [Child class],
             };
}
+ (NSString *)xzh_dateFormat {
    return @"EEE MMM dd HH:mm:ss Z yyyy";
}
@end

@interface Cat : NSObject
@property (nonatomic, assign) NSInteger cid;
@property (nonatomic, copy) NSString *name;
@end
@implementation Cat
+ (NSDictionary *)xzh_customerMappings {
    return @{
             // 属性 : json key
             @"cid" : @"c_id",
             @"name" : @"c_name",
             };
}
@end

@implementation Child
@end
```

下面是对应的json

```objc
id json = @{
    @"name" : @"dog001",
    @"data" : @{
                @"uid" : @"100001",
            },
    @"p_age" : @"21",
    @"user" : @{
            @"city" : @{
                    @"address" : @"address4.....",
                    },
            },
    @"sex" : @"男",
    @"cat" : @{
            @"c_id" : @"111111",
            @"c_name" : @"cat_0000001",
            },
    @"animal" : @{
            @"cat" : @{
                    @"c_id" : @"111111",
                    @"c_name" : @"cat_0000001",
                    },
            
            },
    @"childs" : @[
            @{
                @"cid" : @"001",
                @"name" : @"child_001",
                },
            @{
                @"cid" : @"002",
                @"name" : @"child_002",
                },
            @{
                @"cid" : @(003),
                @"name" : @"child_003",
                },
            @{
                @"cid" : @(004),
                @"name" : @"child_004",
                },
            @{
                @"cid" : @"005",
                @"name" : @"child_005",
                },
            
            ],
    @"date" : @"Wed Dec 25 12:22:19 +0800 2013",
    @"url" : @"http://tp2.sinaimg.cn/3952070245/180/5737272572/0",
    @"flag1" : @(0),
    @"flag2" : @(1),
    @"flag3" : @"0",
    @"flag4" : @"1",
};
```

json to model

```objc
Dog *dog = [Dog xzh_modelFromJSONDictionary:json];
```

model to json

```objc
id jsonObj = [dog xzh_modelToJSONObject];
```

上面的json model的例子，基本上常用的映射方式基本就满足了。

速度稍微快于YYModel，因为我去掉了YYModel中提供各种null字符串的比较，他会转换成0和1的逻辑。这一部分的代码是比较耗时的。而且觉得好像作用也并不是很大....

```
@"NIL" :    (id)kCFNull,
@"Nil" :    (id)kCFNull,
@"nil" :    (id)kCFNull,
@"NULL" :   (id)kCFNull,
@"Null" :   (id)kCFNull,
@"null" :   (id)kCFNull,
@"(NULL)" : (id)kCFNull,
@"(Null)" : (id)kCFNull,
@"(null)" : (id)kCFNull,
@"<NULL>" : (id)kCFNull,
@"<Null>" : (id)kCFNull,
@"<null>" : (id)kCFNull};
```

因为上面这些字符串太相似了，在使用Map这样的结构存取的话，效率会降低很多。基本上每一个key都会散列冲突，不断的往后遍历查找，相当于每次都是for循环。

然后是参考YYModel中部分使用了CoreFoundation，索性我就大量的使用了CoreFoundation，以及内联函数/c函数来完成一些关键的逻辑，尽量较少经历Objective-C的消息传递过程。


[这部分实现原理小结](https://github.com/xiongzenghuidegithub/XZHRuntimeKit/wiki/JsonMappingModel%E9%83%A8%E5%88%86%E5%AE%9E%E7%8E%B0%E5%8E%9F%E7%90%86)

