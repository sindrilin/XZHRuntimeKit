##对于一个进行拷贝的Foundation类对象，所有的属性Ivar的类型分类

### 基本数值类型

```
- `c` >>> A char
- `i` >>> An int
- `s` >>> A short
- `l` >>> A long（l is treated as a 32-bit quantity on 64-bit programs.）
- `q` >>> A long long
- `C` >>> An unsigned char
- `I` >>> An unsigned int
- `S` >>> An unsigned short
- `L` >>> An unsigned long
- `Q` >>> An unsigned long long
- `f` >>> A float
- `d` >>> A double
- `B` >>> A C++ bool or a C99 _Bool
```

基本类型的值，直接进行设置，不需要考虑拷贝的问题。

### Foundation类对象（主要针对情况）

- (1) 系统的所有的Foundation类都实现了NSCopying协议，即都可以进行`-[NSObject copy]`
	- 容器类型:
		- NSArray、NSMutableArray
		- NSSet、NSMutableSet
		- NSDictionary、NSMutableDictionary
	- 非容器类型:
		- NSString ...
		- NSNumber ...
		- NSDate ...
		- NSData ...
		- NSURL ...
		
- (2) 但是对于我们自定义的NSObject类，通常没有实现NSCopying协议
	- 如果直接`-[自定义类型 copy]`就会导致崩溃

### CoreFoundation实例/c指针变量

这部分，基本上就不做拷贝的处理了，直接指针指向。

##下面是对上面所有情况下的浅拷贝、深拷贝下的处理情况

| 属性Ivar类型 | 浅拷贝 | 深拷贝 |
| :-------------: |:-------------:| :-----:|
| 基本类型（char、int、bool、float...） | 直接赋值 | 直接赋值 |
| 非容器Foundation类型（NSString、NSNumber、NSURL、NSDate、NSDate....） | 直接发送copy/mutableCopy消息 | 直接发送copy/mutableCopy消息 |
| 容器Foundation类型（NSArray、NSSet、NSDictionary） | 取出数组内对象，直接赋值 | 取出数组内对象，判断是否需要继续发送copy消息 |
| 自定义NSObject类 | 创建一个新的自定义NSObject类对象，内部Ivar直接指向原来对象的Ivar | 创建一个新的自定义NSObject类对象，内部Ivar继续发送copy消息 |
| CoreFoundation实例\c指针变量 | 直接指针指向 | 直接指针指向 |