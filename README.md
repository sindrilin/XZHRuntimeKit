##看多了大牛们的轮子，寻思着自己弄一个runtime的一些小轮子....

可能部分代码并不是原创，也有很多是参考自开源库，比如: YYKit ...大神只能膜拜... 算是站在巨人的肩膀上偷偷的学习吧~~~

主要是将一些常用的基于runtime的代码整合起来:

- (1) JSON 映射 Model （第一版结束）
	- json to model
	- model to json
- (2) Copy （正在做ing）
	- 浅拷贝
	- 深拷贝
- (3) Archive
- (4) Protocol Observer (没开始)
- (5) ORM	(没开始)
- (6) Cache (没开始)

把这些全部整合起来，就算是对自己这两年来搞iOS的交代吧，菜鸟成长记 . . . 

###JSON 与 Model用法demo

实体类

```objc
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
+ (NSDictionary *)xzh_classInArray {
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


##下面是记录一些代码实现过程中遇到的一些问题和学习笔记。

###opensouece

http://opensource.apple.com/source/objc4/objc4-237/runtime/

###type encodings

http://opensource.apple.com/source/objc4/objc4-237/runtime/objc-class.h

```c
/* Definitions of filer types */

#define _C_ID       '@'
#define _C_CLASS    '#'
#define _C_SEL      ':'
#define _C_CHR      'c'
#define _C_UCHR     'C'
#define _C_SHT      's'
#define _C_USHT     'S'
#define _C_INT      'i'
#define _C_UINT     'I'
#define _C_LNG      'l'
#define _C_ULNG     'L'
#define _C_FLT      'f'
#define _C_DBL      'd'
#define _C_BFLD     'b'
#define _C_VOID     'v'
#define _C_UNDEF    '?'
#define _C_PTR      '^'
#define _C_CHARPTR  '*'
#define _C_ARY_B    '['
#define _C_ARY_E    ']'
#define _C_UNION_B  '('
#define _C_UNION_E  ')'
#define _C_STRUCT_B '{'
#define _C_STRUCT_E '}'
```


###Property 编码

```c
typedef struct {
    const char *name;         //T、V、R、C....  
    const char *value;        //@NSString、_name、....  
} objc_property_attribute_t;
```

```c
`T` >>> 表示属性生成的实例变量的类型编码
`V` >>> 标示实例变量的名字
`R` >>> The property is read-only (readonly).
`C` >>> The property is a copy of the value last assigned (copy).
`&` >>> The property is a reference to the value last assigned (retain).
`N` >>> The property is non-atomic (nonatomic).
`G` >>> The property defines a custom getter sel
`S` >>> The property defines a custom setter sel
`D` >>> The property is dynamic (@dynamic)
`W` >>> The property is a weak reference (__weak)
`P` >>> The property is eligible for garbage collection
`t` >>> Specifies the type using old-style encoding
```

最核心的是`T`，后面跟着的就是属性包含的实例变量的类型:


```
name = T, valie = @NSString
name = T, valie = @Person
name = T, valie = i

或

T@NSString、T@Person、Ti
```

###Ivar 编码

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
- `v` >>> A void
- `*` >>> A character string (char *)
- `@` >>> An object (whether statically typed or typed id)
	- @? >>> NSBlock
	- @NSArray、@NSString....Foundation类
	- @User、@Person....自定义类
- `#` >>> A class object (Class)
- `:` >>> A method selector (SEL)
- `[array type]` >>> An array
- `{name=type...}` >>> A structure
- `(name=type...)` >>>  A union
- `bnum` >>> A bit field of num bits
- `^type` >>> A pointer to type
- `?` >>> An unknown type (among other things, this code is used for function pointers)
```

可以大致分为组成:

```
- 基本数值类型
	- BOOL
	- char/int8_t
	- unsigned char/uint8_t
	- int/int32_t
	- unsigned int/uint32_t
	- float
	- double
	- short/int16_t
	- unsigned short/uint16_t
	- long
	- unsigned long
	- long long/int64_t
	- unsigned long long/uint64_t
- Foundation Object类型
	- NSURL
	- NSArray/NSMutableArray
	- NSSet/NSMutableSet
	- NSDictionary/NSMutableDictionary
	- NSDate
	- NSData/NSMutableData
	- NSNumber/NSDecimalNumber
	- NSString/NSMutableString
	- NSValue
	- NSNull
	- NSBlock
	- 自定义继承自NSObject类
- c复杂类型
	- c 指针类型（char*、int*....）
	- CoreFoundation结构体实例（Class、Property、Ivar、SEL、Method....）
	- 自定义struct/union
```

在NSInvocation.h中也找到了苹果自己定义的type encoding枚举:

```c
enum _NSObjCValueType {
    NSObjCNoType = 0,
    NSObjCVoidType = 'v',
    NSObjCCharType = 'c',
    NSObjCShortType = 's',
    NSObjCLongType = 'l',
    NSObjCLonglongType = 'q',
    NSObjCFloatType = 'f',
    NSObjCDoubleType = 'd',
    NSObjCBoolType = 'B',
    NSObjCSelectorType = ':',
    NSObjCObjectType = '@',
    NSObjCStructType = '{',
    NSObjCPointerType = '^',
    NSObjCStringType = '*',
    NSObjCArrayType = '[',
    NSObjCUnionType = '(',
    NSObjCBitfield = 'b'
} NS_DEPRECATED(10_0, 10_5, 2_0, 2_0);
```


###Method 编码

```
- `r` >>> const
- `n` >>> in
- `N` >>> inout
- `o` >>> out
- `O` >>> bycopy
- `R` >>> byref
- `V` >>> oneway
```

###将这三种编码组合到一个`NS_OPTION(){}`枚举中的结构

```c
- (1) Ivar 数据类型的 type encodings: 1 ~ 8位 >>> 单选 >>>> Mask: 0xFF
- (2) Property 各种修饰符的 type encodings: 9 ~ 15位 >>>> 多选 >>>> Mask: 0xFF00
- (3) Method  各种修饰符的 type encodings: 16 ~ 23位 >>>> 多选 >>>> Mask: 0xFF0000
```

###具体解析一个`objc_property`实例的type encodings时的逻辑

```c
- (1) property's type encodings >>>> 
    - `T` >>> 标示@property的type encodings字符串，eg: T@"NSString",C,N,V_name
        - 基本数值数据类型(c数据类型)
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
        - Foundation类型
            - `@` >>> An object (whether statically typed or typed id)
                - eg、@NSString、@NSArray、@Person ...
            - `?` >>> An unknown type (among other things, this code is used for function pointers)
                -  `@?` ===> NSBlock
            - 长度一定是大于等于2，才是有效的Foundation类型
        - CoreFoundation类型
            - `#` >>> A class object (Class)
            - `:` >>> A method selector (SEL)
            - `[array type]` >>> An array
            - `{name=type...}` >>> A structure
            - `(name=type...)` >>>  A union
            - `bnum` >>> A bit field of num bits
            - `^type` >>> A pointer to type
            - `v` >>> A void
            - `*` >>> A character string (char *)
    - `V` >>> 标示实例变量的名字
    - `R` >>> The property is read-only (readonly).
    - `C` >>> The property is a copy of the value last assigned (copy).
    - `&` >>> The property is a reference to the value last assigned (retain).
    - `N` >>> The property is non-atomic (nonatomic).
    - `G` >>> The property defines a custom getter sel
    - `S` >>> The property defines a custom setter sel
    - `D` >>> The property is dynamic (@dynamic)
    - `W` >>> The property is a weak reference (__weak)
    - `P` >>> The property is eligible for garbage collection
    - `t` >>> Specifies the type using old-style encoding
```


##c类型的编码、以及使用NSValue包装

NSValue直接可以支持包裹的 c struct 类型:

```objc
@interface NSValue (NSValueUIGeometryExtensions)

+ (NSValue *)valueWithCGPoint:(CGPoint)point;
+ (NSValue *)valueWithCGVector:(CGVector)vector;
+ (NSValue *)valueWithCGSize:(CGSize)size;
+ (NSValue *)valueWithCGRect:(CGRect)rect;
+ (NSValue *)valueWithCGAffineTransform:(CGAffineTransform)transform;
+ (NSValue *)valueWithUIEdgeInsets:(UIEdgeInsets)insets;
+ (NSValue *)valueWithUIOffset:(UIOffset)insets NS_AVAILABLE_IOS(5_0);

- (CGPoint)CGPointValue;
- (CGVector)CGVectorValue;
- (CGSize)CGSizeValue;
- (CGRect)CGRectValue;
- (CGAffineTransform)CGAffineTransformValue;
- (UIEdgeInsets)UIEdgeInsetsValue;
- (UIOffset)UIOffsetValue NS_AVAILABLE_IOS(5_0);

@end
```

- (1) CGPoint
- (2) CGVector
- (3) CGSize
- (4) CGRect
- (5) CGAffineTransform
- (6) UIEdgeInsets
- (7) UIOffset


如上几种系统c struct在32/64位下有不同的type encodings:

```objc
NSMutableSet *set = [NSMutableSet new];

// 32 bit
[set addObject:@"{CGSize=ff}"];
[set addObject:@"{CGPoint=ff}"];
[set addObject:@"{CGRect={CGPoint=ff}{CGSize=ff}}"];
[set addObject:@"{CGAffineTransform=ffffff}"];
[set addObject:@"{UIEdgeInsets=ffff}"];
[set addObject:@"{UIOffset=ff}"];

// 64 bit
[set addObject:@"{CGSize=dd}"];
[set addObject:@"{CGPoint=dd}"];
[set addObject:@"{CGRect={CGPoint=dd}{CGSize=dd}}"];
[set addObject:@"{CGAffineTransform=dddddd}"];
[set addObject:@"{UIEdgeInsets=dddd}"];
[set addObject:@"{UIOffset=dd}"];
types = set;
```

32位使用`f >>> float`声明成员变量，64位使用`d >>> double`声明成员变量。

以上几种c struct实例直接可以很容易使用NSValue提供的api进行包裹。除了如上几种直接支持的c struct之外，还有自定义的struct类型实例、以及各种c指针类型变量:


```objc
@interface Wife : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) long double pro4;
@property (nonatomic, strong) NSValue *cvalue1;
@property (nonatomic, strong) NSValue *cvalue2;
@property (nonatomic, strong) NSValue *cvalue3;
@property (nonatomic, strong) NSValue *cvalue4;
@property (nonatomic, strong) NSValue *cvalue5;
@property (nonatomic, strong) NSValue *cvalue6;
@property (nonatomic, strong) NSValue *cvalue7;
@end
@implementation Wife
@end
```

```objc
struct Node {
    int value;
    BOOL isMan;
    char sex;
};
```

```objc
- (void)testNSValue1 {
    Wife *obj = [Wife new];
    
    //1. NSValue包裹指针类型变量
    char *s = "Hello World";
    NSValue *value1 = [NSValue valueWithPointer:s];//默认转换成 void* 类型指针
    NSLog(@"value1.objcType = %s", value1.objCType);
    printf("%s\n", value1.pointerValue);
    
    //2. NSValue包裹c数组
    int intArr[5] = {1, 2, 3, 4, 5};
    NSValue *value2 = [NSValue value:intArr withObjCType:@encode(typeof(intArr))];
    NSLog(@"value2.objcType = %s", value2.objCType);
    NSValue *value3 = [NSValue value:intArr withObjCType:"[5i]"];
    int intArr1[5] = {0};
    int intArr2[5] = {0};
    [value2 getValue:&intArr1];
    [value3 getValue:&intArr2];
    
    //3. NSValue包裹 c struct 实例
    struct Node *node = {0};
    node = malloc(sizeof(struct Node));
    node->isMan = YES;
    node->sex = 'M';
    node->value = 1999;
    NSValue *value4 = [NSValue value:node withObjCType:@encode(struct Node)];
    NSValue *value5 = [NSValue value:node withObjCType:"{Node=iBc}"];
    NSLog(@"value4.objcType = %s", value4.objCType);
    struct Node node_1 = {0};
    struct Node node_2 = {0};
    [value4 getValue:&node_1];
    [value5 getValue:&node_2];
    
    //3. NSValue包裹 c struct 数组实例
    struct Node *nodeArr[3] = {0};
    nodeArr[0] = node;
    nodeArr[1] = node;
    nodeArr[2] = node;
    NSValue *value6 = [NSValue value:nodeArr withObjCType:@encode(typeof(nodeArr))];
    //NSValue *value7 = [NSValue value:node withObjCType:"[3^{Node=iBc}]"];//错误
    NSValue *value7 = [NSValue value:node withObjCType:"[3^{Node}]"];//错误
    NSLog(@"value6.objcType = %s", value6.objCType);
    struct Node *nodeArr_1[3] = {0};
    struct Node *nodeArr_2[3] = {0};
    [value6 getValue:&nodeArr_1];
    [value7 getValue:&nodeArr_2];
    
    //4. objc_msgSend() 设置NSValue
    ((void (*)(id, SEL, NSValue*)) (void *) objc_msgSend)(obj, @selector(setCvalue1:), value1);
    ((void (*)(id, SEL, NSValue*)) (void *) objc_msgSend)(obj, @selector(setCvalue2:), value2);
    ((void (*)(id, SEL, NSValue*)) (void *) objc_msgSend)(obj, @selector(setCvalue3:), value3);
    ((void (*)(id, SEL, NSValue*)) (void *) objc_msgSend)(obj, @selector(setCvalue4:), value4);
    ((void (*)(id, SEL, NSValue*)) (void *) objc_msgSend)(obj, @selector(setCvalue5:), value5);
    ((void (*)(id, SEL, NSValue*)) (void *) objc_msgSend)(obj, @selector(setCvalue6:), value6);
    ((void (*)(id, SEL, NSValue*)) (void *) objc_msgSend)(obj, @selector(setCvalue7:), value7);
    
    //5. kvc 设置NSValue
    [obj setValue:value1 forKey:@"_cvalue1"];
    [obj setValue:value2 forKey:@"_cvalue2"];
    [obj setValue:value3 forKey:@"_cvalue3"];
    [obj setValue:value4 forKey:@"_cvalue4"];
    [obj setValue:value5 forKey:@"_cvalue5"];
    [obj setValue:value6 forKey:@"_cvalue6"];
    [obj setValue:value7 forKey:@"_cvalue7"];
    
}
```

输出结果

```
2016-10-19 23:59:32.968 XZHRuntimeDemo[6709:68837] value1.objcType = ^v
Hello World
2016-10-19 23:59:32.969 XZHRuntimeDemo[6709:68837] value2.objcType = [5i]
2016-10-19 23:59:32.969 XZHRuntimeDemo[6709:68837] value4.objcType = {Node=iBc}
2016-10-19 23:59:32.969 XZHRuntimeDemo[6709:68837] value6.objcType = [3^{Node}]
```

```
(NSConcreteValue *) value1 = 0x00007fe55365a470 <aea27c04 01000000>
(int [5]) intArr = ([0] = 1, [1] = 2, [2] = 3, [3] = 4, [4] = 5)
(NSConcreteValue *) value2 = 0x00007fe55370af70 <01000000 02000000 03000000 04000000 05000000>
(NSConcreteValue *) value3 = 0x00007fe553624fe0 <01000000 02000000 03000000 04000000 05000000>
(int [5]) intArr1 = ([0] = 1, [1] = 2, [2] = 3, [3] = 4, [4] = 5)
(int [5]) intArr2 = ([0] = 1, [1] = 2, [2] = 3, [3] = 4, [4] = 5)
(Node *) node = 0x00007fe5536164c0
(NSConcreteValue *) value4 = 0x00007fe55365f520 <cf070000 014d0000>
(NSConcreteValue *) value5 = 0x00007fe553676b70 <cf070000 014d0000>
(Node) node_1 = (value = 1999, isMan = YES, sex = 'M')
(Node) node_2 = (value = 1999, isMan = YES, sex = 'M')
(Node *[3]) nodeArr = {
  [0] = 0x00007fe5536164c0
  [1] = 0x00007fe5536164c0
  [2] = 0x00007fe5536164c0
}
(NSConcreteValue *) value6 = 0x00007fe55368c1e0 <c0646153 e57f0000 c0646153 e57f0000 c0646153 e57f0000>
(NSConcreteValue *) value7 = 0x00007fe553619560 <cf070000 014d0000 032c3655 fe0700d0 00004a88 00000000>
(Node *[3]) nodeArr_1 = {
  [0] = 0x00007fe5536164c0
  [1] = 0x00007fe5536164c0
  [2] = 0x00007fe5536164c0
}
(Node *[3]) nodeArr_2 = {
  [0] = 0x00004d01000007cf
  [1] = 0xd00007fe55362c03
  [2] = 0x00000000884a0000
}
(lldb) 
```

可以小结:

- (1) `[NSValue valueWithPointer:s]`默认转换成`void*`类型指针变量
- (2) c struct 实例，使用NSValue包装后，可以使用`objc_msgSend()`也可以使用`KVC`的方式设置给实例变量


##JSON映射实现结构图

![](http://p1.bqimg.com/4851/cab547bf5d1864fc.jpg)

- （1） NSObject.class >>> ClassMapper

```
Person >>>> Person Class Mapper
```

- (2) `objc_class` >>> ClassMapper

```
Person Class Mapper 包含:
- (1) Person Class Model
	- Ivar Model List
	- Property Model List
	- Method Model List
- (2) Dictionary 缓存
	- <json key 1 : priperty mapper 1>
	- <json key 2 : priperty mapper 2>
	- <json key 3 : priperty mapper 3>
```

- (3) PropertyModel >>> ProeprtyMapper

```
Property Mapper 包含:
	- Property Model
	- 映射哪一种类型的json key
	- 其他辅助属性功能
```

- (4) `objc_property` >>> PropertyModel

```
Property Model 包含:
	- objc_property
	- 解析属性的修饰符、Ivar的类型、数组属性中的对象类型 ....
```

##JSON中的某一个数据项的类型

```
- null	>>> kCFNull、[NSNull null] 单例
	- 需要放置崩溃
	- 可以通过设置默认值
- 非null
	- NSString
		- NSDate日期字符串
		- @"1999"
		- @"1999.111111"
		- 其他字符串内容
	- NSNumber
		- BOOL
		- char/int8_t
		- unsigned char/uint8_t
		- int/int32_t
		- unsigned int/uint32_t
		- float
		- double
		- short/int16_t
		- unsigned short/uint16_t
		- long
		- unsigned long
		- long long/int64_t
		- unsigned long long/uint64_t
	- 自定义NSObject子类
	- NSArray
	- NSDictionary
	- NSSet
	- struct 
```

##可以与NSNumber互转的数据类型

基本数值类型

```
BOOL
char
double
float
int
NSInteger
long
long long
short
unsigned char
unsigned int
NSUInteger
unsigned long
unsigned long long
unsigned short
```

NSString类型

- (1) 简单的数值字符串
- (2) 日期字符串

NSDate日期

##JSON Key 与 `objc_property`的映射关系规则

###jsonkey与`objc_property`的映射关系种类

- (1) 1 property : 1 json key >>> 1 : 1

- (2) 1 property : n json key >>> 1 : n

- (3) n property : 1 json key >>> n : 1


注意 `n : n` 这是不可能的情况，这样根本就无法解析json。

###代码形式的具体某一个 `json key` 又分为三类:

- (1) 简单的json key，不带路径也不是数组，就是一个简单的string

```
name、age .... 
```

- (2) 带有路径的 json key path

```
data.user.name
```

- (3) 数组 json key array，此种情况主要针对 `1 property : n json key`

```
@[@"name", @"user_name", @"uname"] 
```

但注意，如上的数组中的每一个json key可能又是keyPath路径

```
@[@"name", @"user.name", @"uname"] 
```

###当多个属性同时映射一个jsonkey的特殊情况处理

```
name1 >>> name
name2 >>> name
name3 >>> name
```

并且这种情况不管jsonkey是 (1)、(2)、(3) 都是有可能存在的。

- (1) 多个属性同时映射一个简单的`json key`
- (2) 多个属性同时映射一个`json keyPath`
- (3) 多个属性同时映射一个`json KeyArray`


###多个不同属性映射同一个json key

```
eg1.
	{name1 : name}, {name2 : name}, {name3 : name}

eg2. 
	{name1 : user.name},
   {name2 : user.name},
   {name3 : user.name}

eg3.
	{name1 : @[@"name", @"user.name", @"user_name"]}, 
   {name2 : @[@"name", @"user.name", @"user_name"]}, 
   {name3 : @[@"name", @"user.name", @"user_name"]}
```


单独处理`多个属性 映射 一个json key`的情况，使用`_next`实例变量按照`单链表`的结构依次按照顺序串联起来，这样就不会出现某一个映射关系丢失的问题

| 属性名 | json key |
|:-------------:|:-------------:|
| name | user_name |
| title | user_name |
| tip | user_name |

- (1) name属性的PropertyMapper对象 >>> `PropertyMapper_name`

- (2) title属性的PropertyMapper对象 >>> `PropertyMapper_title`

- (3) tip属性的PropertyMapper对象 >>> `PropertyMapper_tip`


`PropertyMapper_name、PropertyMapper_title、PropertyMapper_tip`三者之间的关系:

缓存字典的name jsonKey只保存最后一个解析属性 `PropertyMapper_tip`

```objc
dic = {
	jsonKey : PropertyMapper_tip
}
```

但是`PropertyMapper_tip`依次讲前面的两个串联起来

```
PropertyMapper_tip->_next ==> PropertyMapper_title
```

```
PropertyMapper_tip->_title ==> PropertyMapper_name
```

还有一种是上面情况的扩展，即不同属性映射的jsonKey此时不是一个简单的key，而是`多个key`

```
//{属性 : [key1, key2, key3, ....., keyN]}

@{
	....
	@"uid" : @[@"id",@"uid",@"UserId",@"User.id"],
	@"pid" : @[@"id",@"uid",@"UserId",@"User.id"],
	....
}
```

那么数组`@[@"id",@"uid",@"UserId",@"User.id"]`就是保存PropertyMapper对象到字典的key（只要实现了NSCopying协议的对象都可以作为字典的key）。

![](http://i1.piimg.com/ee87eb2dff87aff8.png)

这样一来，如果有多个不同的属性映射同一个jsonKey（key、keyPath、keyArray）时，通过`PropertyMapper->_next`进行链式串联起来。

##ClassMapper包装一个`objc_class`与json的映射关系时，由于可能多次重复性解析，所以做了内存缓存，并使用semephore完成线程同步

```objc
+ (instancetype)classMapperWithClass:(Class)cls {
    if (cls == Nil) return nil;
    
    //1. 单利缓存字典、同步信号量 初始化
    static CFMutableDictionaryRef _cache;
    static dispatch_semaphore_t _semephore;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _cache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        _semephore = dispatch_semaphore_create(1);
    });
    
    //2. 缓存 ClassMapper 的key
    const void *clsName =  (__bridge const void *)(NSStringFromClass(cls));
    
    //3. 先读缓存是否已经存在解析完毕的Mapper对象
    dispatch_semaphore_wait(_semephore, DISPATCH_TIME_FOREVER);
    XZHClassMapper *clsMapper = CFDictionaryGetValue(_cache, clsName);
    dispatch_semaphore_signal(_semephore);
   
   //4. 如果缓存没有，再进行解析，并最后将解析的Mapper对象缓存起来
   if (!clsMapper) {
   		
   		//4.1 解析开始，开始多线程同步
   		dispatch_semaphore_wait(_semephore, DISPATCH_TIME_FOREVER);
   		
   		//4.2 完成对 objc_class 的解析
   		//生成: nethods、ivars、properties、categories、protocols  .... 的对应的model
   		
   		//4.3  解析结束，结束多线程同步
   		dispatch_semaphore_signal(_semephore);
	}
	
	return clsMapper;
}
    
```

##PropertyMapper、记录OC类对象的属性具体如何映射json中的某一个jsonkey

从逻辑上看:

```
PropertyMapper
	- jsonkey
		- simple key
		- keyPath
		- keyArray
	- property
		- <1property : 1jsonkey>
		- <1property : njsonkey>
		- <nproperty : 1jsonkey>
```

比如说管理如下的映射关系:

```
// 属性 : jsonKey
- {name : name}		
- {name : user_name}
- {name : user.name}
- {name : [name1, name2, name3, user.name]}
- {name1 : name}, {name2 : name}, {name3 : name}
```

从代码结构上看:

- (1) 三个重要的Class实例变量

```objc
Class                       _generacCls;        // 属性所属的实体类class
Class                       _containerCls;      // 容器属性变量内部元素的Class
Class                       _ivarClass;         // 当前属性变量的Class
```

- (2) 记录属性映射的jsonKey类型

```objc
NSString                    *_mappedToSimpleKey;
NSString                    *_mappedToKeyPath;
NSArray                     *_mappedToManyKey;
```

- (3) 如果出现多个属性映射同一个jsonkey，使用next指针串联起来


```objc
XZHPropertyMapper         *_next;
```


##KVC不支持long double类型、c pointer(such as SEL/CoreFoundation object)

```
1. long double 基本数值类型
2. c 指针类型 
	2.1 char*、int* .... （不包含结构体指针类型）
	2.2 CoreFoundation object
```

##iOS SDK并没有直接给出block的类型Class，只能通过代码手段测试得到

- (1) block有三种内部类型

```objc
Class cls1 = objc_getClass("__NSGlobalBlock__");
Class cls2 = objc_getClass("__NSMallocBlock__");
Class cls3 = objc_getClass("__NSStackBlock__");
```

输出如下

```
(Class) cls1 = __NSGlobalBlock__
(Class) cls2 = __NSMallocBlock__
(Class) cls3 = __NSStackBlock__
```

- (2) 类似NSArray/NSMutableArray是`__NSArrayI、__NSArrayM`的类簇类一样，如上三种block内部类也有`类簇类`就是`NSBlock`


```objc
Class cls = objc_getClass("NSBlock");
```

输出如下

```
(Class) cls = NSBlock
```

那么在我们代码中可以直接将`objc_getClass("NSBlock")`作为类簇类使用，但是为了考虑iOS SDK版本升级后，可能不再是`NSBlock`这个类来代替。那么所以如下这个代码可以在任何iOS SDK版本下找到block的对应的类簇类

```c
static Class XZHGetNSBlockClass() {
    static Class NSBlock = Nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void (^block)(void) = ^(){};
        Class cls = [(NSObject*)block class];
        while (cls && (class_getSuperclass(cls) != [NSObject class]) ) {
            cls = class_getSuperclass(cls);
        }
        NSBlock = cls;
    });
    return NSBlock;
}
```

##Foundation中给出的类基本上都是`类簇`类，不是真正使用的内部类，只是一个操作内部类的入口类

- (1) NSArray/NSMutableArray作为类簇操作的内部类 

```
__NSArrayI、__NSArray0、__NSArrayM、__PlaceholderArray
```

- (2) NSSet/NSMutableSet作为类簇操作的内部类 

```
__NSSetI、__NSSingleObjectSetI、__NSSetM
```

- (3) NSDictionary/NSMutableDictionary作为类簇操作的内部类 

```
__NSDictionary0、__NSDictionaryI、__NSDictionaryM
```

- (4) NSData作为类簇操作的内部类

```
_NSZeroData、NSConcreteData、NSConcreteMutableData
```

- (5) NSNumber作为类簇操作的内部类

```
__NSCFNumber
```

- (6) NSString/NSMutableString作为类簇操作的内部类

```
__NSCFConstantString、NSTaggedPointerString、__NSCFString
```

- (7) NSValue作为类簇操作的内部类

```
NSConcreteValue
```

- (8) NSBlock作为类簇操作的内部类（NSBlock没有被开放的）

```
__NSGlobalBlock__、__NSMallocBlock__、__NSStackBlock__
```

- 不是类簇的

```
NSURL
NSDate
NSDecimalNumber
```

判断一个Class属于哪一种类型，直接判断这个Class是否是如上`类簇类的subClass`即可:

```objc
XZHFoundationType XZHGetClassFoundationType(Class cls) {
    if (NULL == cls) {return XZHFoundationTypeUnKnown;}
    if ([cls isSubclassOfClass:[NSArray class]]) {return XZHFoundationTypeNSArray;}
    else if ([cls isSubclassOfClass:[NSURL class]]) {return XZHFoundationTypeNSURL;}
    else if ([cls isSubclassOfClass:[NSMutableArray class]]) {return XZHFoundationTypeNSMutableArray;}
    else if ([cls isSubclassOfClass:[NSSet class]]) {return XZHFoundationTypeNSSet;}
    else if ([cls isSubclassOfClass:[NSMutableSet class]]) {return XZHFoundationTypeNSMutableSet;}
    else if ([cls isSubclassOfClass:[NSDictionary class]]) {return XZHFoundationTypeNSMutableArray;}
    else if ([cls isSubclassOfClass:[NSMutableDictionary class]]) {return XZHFoundationTypeNSMutableDictionary;}
    else if ([cls isSubclassOfClass:[NSDate class]]) {return XZHFoundationTypeNSDate;}
    else if ([cls isSubclassOfClass:[NSData class]]) {return XZHFoundationTypeNSData;}
    else if ([cls isSubclassOfClass:[NSMutableData class]]) {return XZHFoundationTypeNSMutableData;}
    else if ([cls isSubclassOfClass:[NSNumber class]]) {return XZHFoundationTypeNSNumber;}
    else if ([cls isSubclassOfClass:[NSDecimalNumber class]]) {return XZHFoundationTypeNSDecimalNumber;}
    else if ([cls isSubclassOfClass:[NSString class]]) {return XZHFoundationTypeNSString;}
    else if ([cls isSubclassOfClass:[NSMutableString class]]) {return XZHFoundationTypeNSMutableString;}
    else if ([cls isSubclassOfClass:[NSValue class]]) {return XZHFoundationTypeNSValue;}
    else if ([cls isSubclassOfClass:[NSNull class]]) {return XZHFoundationTypeNSNull;}
    else if ([cls isSubclassOfClass:XZHGetNSBlockClass()]) {return XZHFoundationTypeNSBlock;}
    else {return XZHFoundationTypeUnKnown;}//未知、自定义类型
}
```

基本上类簇模式，都是使用`继承`的方式来实现不同的版本实现。

##摘录自YYModel中对日期字符串处理的c函数代码

使用一个static数组保存若干个不同计算类型的Block对象，然后取出某一个进行对应类型的数据计算。

```c

typedef NSDate* (^XZHDateParseBlock)(NSString *dateString);

/**
 *  日期字符串格式化
 */
static force_inline NSDate* XZHDateFromString(__unsafe_unretained NSString *dataString) {
    
//1. 日期字符串的最大长度为32
#define kParserNum 32
    
    //2. 保存对应长度长度日期字符串解析的Block数组
    static XZHDateParseBlock blocks[kParserNum + 1] = {0};//长度+1，保持下标同步
    
    //3. 单例化 对应日期字符串长度的 解析成NSDate的Block
    //NSDate解析Block = blocks[日期字符串长度];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        {
            /*
             Google、长度为10的日期字符串解析
             
                2014-01-20 --> yyyy-MM-dd
             */
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            
            //字符串长度为10
            formatter.dateFormat = @"yyyy-MM-dd";
            
            //对应解析NSDate的Block，保存到数组第10个（声明blocks数组时长度+1）
            blocks[10] = ^NSDate* (NSString *string) {
                return [formatter dateFromString:string];
            };
        }
        
        {
            /*
             Google、长度为19的日期字符串解析，分两种
             
                格式一、2014-01-20 12:24:48 --> yyyy-MM-dd'T'HH:mm:ss
                格式二、2014-01-20T12:24:48 --> yyyy-MM-dd'T'HH:mm:ss
             */
            NSDateFormatter *formatter1 = [[NSDateFormatter alloc] init];
            formatter1.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter1.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            
            formatter1.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
            
            NSDateFormatter *formatter2 = [[NSDateFormatter alloc] init];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            
            formatter2.dateFormat = @"yyyy-MM-dd HH:mm:ss";
            
            //将日期字符串解析的Block保存到19的数组位置
            blocks[19] = ^(NSString *string) {
                if ([string characterAtIndex:10] == 'T') {
                    return [formatter1 dateFromString:string];
                } else {
                    return [formatter2 dateFromString:string];
                }
            };
        }
        
        {
            /*
             Github, Apple、2014-01-20T12:24:48Z （长度=20）--> yyyy-MM-dd'T'HH:mm:ssZ
             Facebook、2014-01-20T12:24:48+0800（长度=24）--> yyyy-MM-dd'T'HH:mm:ssZ
             Facebook、2014-01-20T12:24:48+12:00（长度=25）--> yyyy-MM-dd'T'HH:mm:ssZ
             */
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
            blocks[20] = ^(NSString *string) {
                return [formatter dateFromString:string];
            };
            blocks[24] = ^(NSString *string) {
                return [formatter dateFromString:string];
            };
            blocks[25] = ^(NSString *string) {
                return [formatter dateFromString:string];
            };
        }
        
        {
            /*
             Weibo, Twitter、Fri Sep 04 00:12:21 +0800 2015（长度=30）--> EEE MMM dd HH:mm:ss Z yyyy
             */
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.dateFormat = @"EEE MMM dd HH:mm:ss Z yyyy";
            blocks[30] = ^(NSString *string) {
                return [formatter dateFromString:string];
            };
        }
    });
    
    //4. 传入的日期字符串空
    if (!dataString) return nil;
    
    //5. 取出日期字符串长度对应的 转换日期的Block
    XZHDateParseBlock parser = blocks[dataString.length];
    
    //6.
    if (!parser) return nil;
    
    //7. 执行Block，传入日期字符串
    return parser(dataString);
#undef kParserNum
}
```

##json dic >>> model 的大体逻辑

- (1) json dic

```objc
id json = @{
                @"name" : @"dog001",
                @"data" : @{
                            @"uid" : @(100001),
                            @"uid" : @"100001",
                            @"uid" : @"nil",
                            @"uid" : @"Nil",
                            @"uid" : @"NULL",
                            @"uid" : @"null",
                            @"uid" : @"<null>",
                            @"uid" : [NSNull null],
                        },
                @"p_age" : @"21",
                @"user" : @{
                        @"city" : @{
                                @"address" : @"address4.....",
                                },
                        },
                @"sex" : @"男",
                @"animal" : @{
                        @"cat" : @{
                                @"c_id" : @"cat_hahahha",
                                @"c_name" : @"cat_0000001",
                                },
                        },
                };
```

- (2) 使用类方法解析json

```objc
Dog *dog = [Dog xzh_modelFromObject:json];
```

- (3) 生成`[Dog class]`对应的 ClassMapper
	- 生成 ClassModel
		- IvarModel
		- PropertyModel
		- MethodModel
		- CategoryModel
		- ProtocolModel
	- 生成PropertyMapper记录所有的PropertyModel与jsonkey的映射关系

- (3) 遍历`[Dog class]`对应的 ClassMapper->_jsonKeyMappedPropertyMapperDic 
	- 取出jsonkey对应的jsonvalue
	- 设置到model的属性值


##嵌套单个NSObject类的处理逻辑

```objc
@interface Cat : NSObject
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
@end
```

- (1) 首先按照`[Dog class]`解析json
- (2) 当取到item json对应的类型是`[Cat class]`时
- (3) 开始解析`[Cat class]`，生成`[Cat class]`对应的ClassMapper实例
- (4) 然后将item json 按照`[Cat class]`对应的ClassMapper实例，进行设置

所以并不是一开始解析 `[Dog class]` 时，就直接将内部的`[Cat class]`同时解析。

也没有必要，因为有可能`[Cat class]`没有对应的json value。所以用到的时候再去解析并生成对应的ClassMapper实例。

##嵌套NSObject类的处理逻辑

```objc
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
@property (nonatomic, strong) NSArray *childs;
@end
```

- (1) 首先按照`[Dog class]`解析json
- (2) 当取到item json对应的类型是`[NSArray class]`时
- (3) 遍历 json array 中的每一个item json value
- (4) 获取`PropertyMapper->_containerCls`对应的Array内部元素对象的Class
- (5) 判断每一个item json value的类型
	- `NSDictionary`
	- `PropertyMapper->_containerCls`

- (6) 如果是NSDictionary类型，则继续讲json item value 按照 `PropertyMapper->_containerCls` 进行json转model

```objc
id obj = [PropertyMapper->_containerCls _xzh_modelFromJSONDictionary:jsonItemValue];
```
	
- (7) 如果已经是`PropertyMapper->_containerCls`直接加入数组

- (8) 如果根本就不存在`PropertyMapper->_containerCls`，则直接当做NSArray对象存入model属性值


##json解析优化一、使用`__unsafe_unretained`修饰指针变量指向的`Objective-C`对象，提升代码的执行速度

###首先`__unsafe_unretained、__weak、__strong、__assign`只能对指向`Objective-C`对象的指针变量进行修饰

同样的实现代码，发现和YYModel的运行速度慢2倍多，于是找了很久的而原因，原来是`__unsafe_unretained`的效果。

如果对于一个传入的对象，只是需要临时使用，而不是长时间需要持有的话，那么可以显示的使用`__unsafe_unretained`来修饰指针变量。

因为`__unsafe_unretained`是不会去持有指针变量所指向的对象，仅仅只是指针指向对象临时使用，不会修改对象的retainCount，即不会指向`[对象 retain];`的操作。

但是不要使用`__weak`修饰指针变量，因为使用weak修饰的指针变量指向的对象时，runtime system默认会会将这个对象加入到一个autoreleasepool对象中，来保证使用这个对象的期间都不会释放，很明显这会影响执行速度。


注意、OC代码中对于一个对象的指针变量，默认都是`__strong`修饰。

下面是默认情况下使用`__strong`修饰对象指针变量 和 `__unsafe_unretained`修饰对象指针变量 同时完成一样的事情的时候消耗的代码运行时间:

```objc
@interface UnContext : NSObject
@property (nonatomic, copy) NSString *value1;
@property (nonatomic, strong) id value2;
@end
@implementation UnContext
@end


void test1(UnContext *ctx) {
    ctx.value1 = @"hahahaha2";
    ctx.value2 = [NSObject new];
}

void test2(__unsafe_unretained UnContext *ctx) {
    ctx.value1 = @"hahahaha2";
    ctx.value2 = [NSObject new];
}

@implementation UnSafeUnRetainedViewController
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UnContext *ctx = [UnContext new];
    ctx.value1 = @"hahaha";
    ctx.value2 = [NSObject new];
    
    double date_s = CFAbsoluteTimeGetCurrent();
    for (int i = 0; i < 100000; i++) {
		 test1(ctx);
        test2(ctx);
    }
    double date_current = CFAbsoluteTimeGetCurrent() - date_s;
    NSLog(@"consumeTime: %f μs",date_current * 11000 * 1000);
}
@end
```

如上代码，`test1()`消耗的时间范围大概是:

```
258510.768414 μs
```

如上代码，`test2()`消耗的时间范围:

```
199925.065041 μs
```

随着循环的次数越来越大，`test1()`与`test2()`两个函数执行所消耗的时间的区别也越来越大。

但是需要注意，`__unsafe_unretained`修饰的指针变量不会在被指向对象废弃时而自动赋值为nil，就有可能引发一些崩溃，但是分情况:

- (1) `[nil sel:args]` 这种肯定是没问题的
- (2) `[array addObject:nil];` 这种就会崩溃

使用`__unsafe_unretained`的时候就需要特别的小心。参考YYModel的代码，发现只对象方法传入的参数使用`__unsafe_unretained`修饰，但是对象的实例变量、属性都不会使用`__unsafe_unretained`修饰。

除非是不需要持有某一个实例变量对象，就使用`__unsafe_unretained`。

总之使用的时候，搞清楚到底需不需要strong持有这个`Objective-c`对象。

##json解析优化二、一个json object 与 该class的所有property mapper 之间的解析规则

我之前的做法就是直接 遍历所有的`ClassMapper->_proeprtyMappers`数组挨个解析json dic，并没有关心如下连个count的大小关系:

- (1) class mappded count
- (2) json dic key count 

那么虽然这么做也是OK的，但是有个效率问题。很可能json的value item个数是小于Model的属性个数的:

- (1) json 

```objc
{
    "login": "facebook",
    "id": 69631,
    "avatar_url": "https://avatars.githubusercontent.com/u/69631?v=3",
    "gravatar_id": "",
    "url": "https://api.github.com/users/facebook",
    "html_url": "https://github.com/facebook",
    "followers_url": "https://api.github.com/users/facebook/followers",
    "following_url": "https://api.github.com/users/facebook/following{/other_user}",
    "gists_url": "https://api.github.com/users/facebook/gists{/gist_id}",
    "starred_url": "https://api.github.com/users/facebook/starred{/owner}{/repo}",
}
```

- (2) 实体类

```objc
@interface XZHRuntimeUserModel : NSObject
@property (nonatomic, strong) NSString *login;
@property (nonatomic, assign) UInt64 userID;
@property (nonatomic, strong) NSString *avatarURL;
@property (nonatomic, strong) NSString *gravatarID;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *htmlURL;
@property (nonatomic, strong) NSString *followersURL;
@property (nonatomic, strong) NSString *followingURL;
@property (nonatomic, strong) NSString *gistsURL;
@property (nonatomic, strong) NSString *starredURL;
@property (nonatomic, strong) NSString *subscriptionsURL;
@property (nonatomic, strong) NSString *organizationsURL;
@property (nonatomic, strong) NSString *reposURL;
@property (nonatomic, strong) NSString *eventsURL;
@property (nonatomic, strong) NSString *receivedEventsURL;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, assign) BOOL siteAdmin;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *company;
@property (nonatomic, strong) NSString *blog;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *hireable;
@property (nonatomic, strong) NSString *bio;
@property (nonatomic, assign) UInt32 publicRepos;
@property (nonatomic, assign) UInt32 publicGists;
@property (nonatomic, assign) UInt32 followers;
@property (nonatomic, assign) UInt32 following;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, strong) NSValue *test;
@end
```

可以看到实体类属性的个数远远大于json的item value的个数。

那如果这种情况下，也是直接遍历`实体类的所有属性`都对json进行一次解析。那么其实就有很多次循环操作都是浪费的。

因为json中映射某一个属性值的json item value根本就没有值，那么就白白的浪费了一次循环执行的时间。

###所以需要区别对待 classMapper's property mappded count 与 json dic key count 的大小情况

> `classMapper's property mappded count >= json dic key count` >>>> 此种情况下，应该主要依靠json dic本身的所有的Key进行解析。

- (1) 首先按照json dic.key 找到对应的PropertyMapper来解析json item value
- (2) 再按照 映射 jsonkeyPath PropertyMapper来解析json item value
- (3) 再按照 映射 jsonKeyArray PropertyMapper来解析json item value

(2)和(3)为了可能有一些key是`keyPath`或`keyArray`类型的，那么就可能无法在第一轮进行正常解析，所以需要辅助执行按照`keyPath`或`keyArray`类型进行解析一次。

这样一来，远远比统统按照实体类属性个数进行循环遍历的次数少的多。

> `classMapper's property mappded count < json dic key count` >>>> 此种情况下，可以直接遍历体类所有的属性进行解析。


###参考自YYModel的做法，分成如上两种情况

```objc
if (modelMeta->_keyMappedCount >= CFDictionaryGetCount((CFDictionaryRef)dic)) {
	
	//1. 第一步、首先按照json dic 中的所有的单个key进行json解析
    CFDictionaryApplyFunction((CFDictionaryRef)dic, ModelSetWithDictionaryFunction, &context);
    
    //2. 第二步、再特别针对映射keyPath的属性解析
    if (modelMeta->_keyPathPropertyMetas) {
        CFArrayApplyFunction((CFArrayRef)modelMeta->_keyPathPropertyMetas,
                             CFRangeMake(0, CFArrayGetCount((CFArrayRef)modelMeta->_keyPathPropertyMetas)),
                             ModelSetWithPropertyMetaArrayFunction,
                             &context);
    }
    
    //3. 第三步、再特别针对映射keyArray的属性解析
    if (modelMeta->_multiKeysPropertyMetas) {
        CFArrayApplyFunction((CFArrayRef)modelMeta->_multiKeysPropertyMetas,
                             CFRangeMake(0, CFArrayGetCount((CFArrayRef)modelMeta->_multiKeysPropertyMetas)),
                             ModelSetWithPropertyMetaArrayFunction,
                             &context);
    }
} else {
	// 4. 直接所有的属性映射进行解析
    CFArrayApplyFunction((CFArrayRef)modelMeta->_allPropertyMetas,
                         CFRangeMake(0, modelMeta->_keyMappedCount),
                         ModelSetWithPropertyMetaArrayFunction,
                         &context);
}
```

这样一来比所有情况，都按照实体类所有的属性都进行一次循环遍历解析所消耗的时间小多了。


##json解析优化三、追求极致使用CoreFoundation来代替Foundation

就没啥写了，就是一些CoreFoundation的c函数api使用。

##json解析优化四、XZHSetFoundationObjectToProperty()这个负责完成将一个Foundation对象设置到NSObject实体类对象的属性变量的c函数代码优化

发现这个函数运行的时间非常的长，是YYModel中类似函数运行消耗时间的2-3倍，卧槽了妈个比，目前我自己的代码大致流程:

```c
if ((mapper->_typeEncoding & XZHTypeEncodingDataTypeMask) == XZHTypeEncodingFoundationObject){
	 //1. Foundation Object
	 - NSURL
	 - NSArray/NSMutableArray
	 - NSSet/NSMutableSet
	 - NSDictionary/NSMutableDictionary
	 - NSDate
	 - NSData/NSMutableData
	 - NSNumber/NSDecimalNumber
	 - NSString/NSMutableString
	 - NSValue
	 - NSNull
	 - NSBlock
	 - 自定义继承自NSObject类
} else if (mapper->_isCNumber) {
	 //2. int、float、double、long ... 数值需要预先使用NSNumber进行打包，然后传入进行设值
	 - BOOL
	 - char/int8_t
	 - unsigned char/uint8_t
	 - int/int32_t
	 - unsigned int/uint32_t
	 - float
	 - double
	 - short/int16_t
	 - unsigned short/uint16_t
	 - long
	 - unsigned long
	 - long long/int64_t
 - unsigned long long/uint64_t
} else {
	//3. c 指针类型/CoreFoundation实例，数值需要预先使用NSValue进行打包，然后传入进行设值
	 - int *p，char *s，int arr[5],
	 - Class、Method、Property、SEL ... 等CoreFoundation结构体实例
	 - 自定义c结构体实例、结构体数组 ....
}
```

从代码分支来看，应该是 (1)分支走的是最多的，应该耗时就在这个分支的代码。

发现就是其中的NSString、NSMutableString case分支的代码比较耗时:

```objc
switch (mapper->_foundationType) {//start switch mapper->_foundationType
    case XZHFoundationTypeNSString:
    case XZHFoundationTypeNSMutableString: {
        // jsonValue.class ==> 1)NSString 2)NSMutableString 3)NSDate 4)NSNumber 5)NSData 6)NSURL
        if ([value isKindOfClass:[NSString class]]) {
            value = XZHConvertNullNSString(value);
            if (!value)return;
            if (mapper->_foundationType == XZHFoundationTypeNSString) {
                ((void (*)(id, SEL, NSString*))(void *) objc_msgSend)(object, setter, value);
            } else {
                ((void (*)(id, SEL, NSString*))(void *) objc_msgSend)(object, setter, [value mutableCopy]);
            }
        } else if ([value isKindOfClass:[NSDate class]]) {
            if ([mapper->_generacCls respondsToSelector:@selector(xzh_dateFormat)]) {
                NSString *dateFormat = [mapper->_generacCls xzh_dateFormat];
                if (dateFormat) {
                    NSDateFormatter *fomatter = XZHDateFormatter(dateFormat);
                    NSString *dateStr = [fomatter stringFromDate:value];
                    if (dateStr) {
                        if (mapper->_foundationType == XZHFoundationTypeNSString) {
                            ((void (*)(id, SEL, NSString*))(void *) objc_msgSend)(object, setter, dateStr);
                        } else {
                            ((void (*)(id, SEL, NSString*))(void *) objc_msgSend)(object, setter, dateStr.mutableCopy);
                        }
                    }
                }
            }
        } else if ([value isKindOfClass:[NSNumber class]]) {
            NSString *valueString = [(NSNumber*)value stringValue];
            if (valueString) {
                if (mapper->_foundationType == XZHFoundationTypeNSString) {
                    ((void (*)(id, SEL, NSString*))(void *) objc_msgSend)(object, setter, valueString);
                } else {
                    ((void (*)(id, SEL, NSString*))(void *) objc_msgSend)(object, setter, valueString.mutableCopy);
                }
            }
        } else if ([value isKindOfClass:[NSURL class]]) {
            NSString *valueString = [(NSURL*)value absoluteString];
            if (valueString) {
                if (mapper->_foundationType == XZHFoundationTypeNSString) {
                    ((void (*)(id, SEL, NSString*))(void *) objc_msgSend)(object, setter, valueString);
                } else {
                    ((void (*)(id, SEL, NSString*))(void *) objc_msgSend)(object, setter, valueString.mutableCopy);
                }
            }
        } else if ([value isKindOfClass:[NSData class]]) {
            NSString *valueString = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
            if (valueString) {
                if (mapper->_foundationType == XZHFoundationTypeNSString) {
                    ((void (*)(id, SEL, NSString*))(void *) objc_msgSend)(object, setter, valueString);
                } else {
                    ((void (*)(id, SEL, NSString*))(void *) objc_msgSend)(object, setter, valueString.mutableCopy);
                }
            }
        }
    }
        break;
            
..........
```

然后参考了下YYModel的这部分的代码:

```objc
switch (meta->_nsType) {
    case YYEncodingTypeNSString:
    case YYEncodingTypeNSMutableString: {
        if ([value isKindOfClass:[NSString class]]) {
            if (meta->_nsType == YYEncodingTypeNSString) {
                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
            } else {
                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, ((NSString *)value).mutableCopy);
            }
        } else if ([value isKindOfClass:[NSNumber class]]) {
            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model,
                                                           meta->_setter,
                                                           (meta->_nsType == YYEncodingTypeNSString) ?
                                                           ((NSNumber *)value).stringValue :
                                                           ((NSNumber *)value).stringValue.mutableCopy);
        } else if ([value isKindOfClass:[NSData class]]) {
            NSMutableString *string = [[NSMutableString alloc] initWithData:value encoding:NSUTF8StringEncoding];
            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, string);
        } else if ([value isKindOfClass:[NSURL class]]) {
            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model,
                                                           meta->_setter,
                                                           (meta->_nsType == YYEncodingTypeNSString) ?
                                                           ((NSURL *)value).absoluteString :
                                                           ((NSURL *)value).absoluteString.mutableCopy);
        } else if ([value isKindOfClass:[NSAttributedString class]]) {
            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model,
                                                           meta->_setter,
                                                           (meta->_nsType == YYEncodingTypeNSString) ?
                                                           ((NSAttributedString *)value).string :
                                                           ((NSAttributedString *)value).string.mutableCopy);
        }
    } break;
                
....
```

然后对比我的代码，发现如下几个影响效率的地方:

- (1) 每一个子if代码块中，又添加了`if-else`的判断
- (2) 没有过滤掉null的情况，造成多次null对象的`objc_msgSend()`调用
- (3) 而且发现，null对象设置给其他类型的Ivar时，很消耗时间

```c
((void (*)(id, SEL, NSString*))(void *) objc_msgSend)(object, setter, (id)kCFNull);
```

修改后的代码如下:

```objc
switch (mapper->_foundationType) {//start switch mapper->_foundationType
    case XZHFoundationTypeNSString:
    case XZHFoundationTypeNSMutableString: {
        if ((id)kCFNull == value) {return;}//过滤掉null
        
        // jsonValue.class ==> 1)NSString 2)NSMutableString 3)NSDate 4)NSNumber 5)NSData 6)NSURL
        if ([value isKindOfClass:[NSString class]]) {
            value = XZHConvertNullNSString(value);
            ((void (*)(id, SEL, NSString*))(void *) objc_msgSend)(object, setter, (mapper->_foundationType == XZHFoundationTypeNSString) ? value : [value mutableCopy]);
        } else if ([value isKindOfClass:[NSDate class]]) {
            if ([mapper->_generacCls respondsToSelector:@selector(xzh_dateFormat)]) {
                NSString *dateFormat = [mapper->_generacCls xzh_dateFormat];
                if (dateFormat) {
                    NSDateFormatter *fomatter = XZHDateFormatter(dateFormat);
                    NSString *dateStr = [fomatter stringFromDate:value];
                    if (dateStr) {
                        ((void (*)(id, SEL, NSString*))(void *) objc_msgSend)(object, setter, (mapper->_foundationType == XZHFoundationTypeNSString) ? dateStr : [dateStr mutableCopy]);
                    }
                }
            }
        } else if ([value isKindOfClass:[NSNumber class]]) {
            NSString *valueString = [(NSNumber*)value stringValue];
            if (valueString) {
                ((void (*)(id, SEL, NSString*))(void *) objc_msgSend)(object, setter, (mapper->_foundationType == XZHFoundationTypeNSString) ? valueString : [valueString mutableCopy]);
            }
        } else if ([value isKindOfClass:[NSURL class]]) {
            NSString *valueString = [(NSURL*)value absoluteString];
            if (valueString) {
                ((void (*)(id, SEL, NSString*))(void *) objc_msgSend)(object, setter, (mapper->_foundationType == XZHFoundationTypeNSString) ? valueString : [valueString mutableCopy]);
            }
        } else if ([value isKindOfClass:[NSData class]]) {
            NSString *valueString = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
            if (valueString) {
                ((void (*)(id, SEL, NSString*))(void *) objc_msgSend)(object, setter, (mapper->_foundationType == XZHFoundationTypeNSString) ? valueString : [valueString mutableCopy]);
            }
        }
    }
        break;
        
....
```

代码运行时间，立马降了一倍多....

最后发现，还是有个比较耗时的地方，`XZHConvertNullNSString()` 这个转换各种null字符串的函数:

```c
static xzh_force_inline NSString* XZHConvertNullNSString(__unsafe_unretained id value) {
    if (!value || ![value isKindOfClass:[NSString class]]) return value;
    static NSDictionary *defaultDic = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultDic = @{
                       @"NIL"   :   @"",
                       @"Nil"   :   @"",
                       @"nil"   :   @"",
                       @"NULL"  :   @"",
                       @"Null"  :   @"",
                       @"null"  :   @"",
                       @"(NULL)" :  @"",
                       @"(Null)" :  @"",
                       @"(null)" :  @"",
                       @"<NULL>" :  @"",
                       @"<Null>" :  @"",
                       @"<null>" :  @"",
                       };
    });
    if (nil != [defaultDic objectForKey:value]) {//如果是以上情况的string，返回nil
        return nil;
    }
    return value;
}
```

因为这些key值都太相似，NSDictionary在查找的时候，效率降低了很多。所以，暂时先把这个过滤null字符串的处理先去掉了。

##model to json

###苹果对可以json化的OC对象的要求

https://developer.apple.com/reference/foundation/jsonserialization

```
An object that may be converted to JSON must have the following properties:

- (1) The top level object is an NSArray or NSDictionary.

- (2) All objects are instances of NSString, NSNumber, NSArray, NSDictionary, or NSNull.

- (3) All dictionary keys are instances of NSString.

- (4) Numbers are not NaN or infinity.

Other rules may apply. Calling isValidJSONObject(_:) or attempting a conversion are the definitive ways to tell if a given object can be converted to JSON data.
```

所以，当model转json的时候，需要注意如上几点。如果`isValidJSONObject:`返回NO，就需要对当前model进行json化转换处理，按照上面4点进行转换即可。

###Json Serialization Thread Safety

On iOS 7 and later and macOS 10.9 and laterNSJSONSerialization is thread safe.

##JSON To Model过程中，对内存缓存dic的读/写，都使用了`dispatch_semephore_t`进行多线程同步互斥，所以可以在任意子线程上进行解析json

- (1) XZHClassMapper 解析对应Class时候做了缓存
	- XZHClassModel 
	- PropertyMapper List
	
- (2) XZHClassModel 解析对应Class时候做了缓存
	- Property List
	- Ivar List
	- Method List
	- Category List
	- .......

做缓存的目的就是，不用重复的解析同一个NSObject类的`objc_class`实例。但是对缓存的读/写必须要加锁同步，否则就会出现程序崩溃的问题。

在使用MJExtensions的时候，经常在子线程上解析json的时候就发生崩溃。也给MJ大大反映过，然后看也改了....但是仍然还是有发生崩溃，说明MJ大大在多线程上操作内存缓存的那一块还是有待优化....