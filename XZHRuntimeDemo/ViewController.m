//
//  ViewController.m
//  XZHRuntimeDemo
//
//  Created by fenqile on 16/8/26.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import "ViewController.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <mach/mach_time.h>
#import "XZHRuntime.h"
#import "NSObject+XZHJSONMapping.h"
#import "Dog.h"
#import "YYModel.h"
#import "UserModel.h"

double MachTimeToSecs(uint64_t time)
{
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);
    return (double)time * (double)timebase.numer /  (double)timebase.denom / 1e9;
}

@protocol XZHHahaProtocol <NSObject>

@optional

- (void)haha1;
- (void)haha2:(NSInteger)age;
- (NSDictionary *)haha3:(NSInteger)age name:(NSArray *)name;
+ (NSArray *)haha4;

@required

- (void)haha5:(NSInteger)age name:(NSString *)name;
- (NSInteger)haha6;
+ (NSString *)haha7;
- (NSArray *)haha8;

@end

@interface TestObj : NSObject
@property (nonatomic, strong) NSNumber *value1;
@property (nonatomic, assign) NSInteger value2;
@property (nonatomic, assign) CGFloat value3;
@end
@implementation TestObj
- (NSString *)description {
    return [NSString stringWithFormat:@"_value1 = %@, _value2 = %ld, _value3 = %lf", _value1, _value2, _value3];
}
@end

@interface Wife : NSObject {
    CGFloat _pro1;
    float _pro2;
    NSInteger _pro3;
//    long double _pro4;
}
//@property (nonatomic, assign) CGFloat pro1;
//@property (nonatomic, assign) float pro2;
//@property (nonatomic, assign) NSInteger pro3;
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

@interface Person : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, assign) NSInteger level;
@property (nonatomic, strong) NSArray *wifeArray;
- (void)log:(NSString *)age;
@end
@implementation Person
- (void)log:(NSString *)age {
    NSLog(@"age = %@", age);
}
@end

struct LinkLeftNode {
    int data;
    struct LinkLeftNode *next;
};

struct LinkRightNode {
    int data;
    struct LinkRightNode *next;
};

struct LinkMap1 {
    struct LinkLeftNode left;
    struct LinkRightNode right;
    int data;
};

struct LinkMap2 {
    struct LinkLeftNode *left;
    struct LinkRightNode *right;
    int data;
};

struct Node {
    int value;
//    struct Node *next;
    BOOL isMan;
    char sex;
};

@interface ViewController () <XZHHahaProtocol> {
    
}
@property (nonatomic, copy) void (^block)(NSInteger);
@property (nonatomic, copy, readonly, setter=setHahaname:, getter=hahaname) NSString *name;
@property (nonatomic, copy, setter=setMyAge:, getter=myAge) NSString *age;
@property (nonatomic, assign) NSInteger price;
@property (nonatomic, strong) NSArray *list;
@property (nonatomic, strong) NSArray<Person *> *persons;
@property (nonatomic, strong) NSDictionary *dic;
@property (nonatomic, strong) NSMutableArray *mlist;
@property (nonatomic, copy) void (^block3)(void);
@property (nonatomic, strong) Person *person;
@property (nonatomic, assign) struct Node *node;


@property (nonatomic, assign) char *ivar1;
@property (nonatomic, assign) char ivar2;
@property (nonatomic, assign) int ivar3;
@property (nonatomic, assign) int8_t ivar4;
@property (nonatomic, assign) int16_t ivar5;
@property (nonatomic, assign) int32_t ivar6;
@property (nonatomic, assign) uint8_t ivar7;
@property (nonatomic, assign) uint16_t ivar8;
@property (nonatomic, assign) uint32_t ivar9;
@property (nonatomic, assign) float ivar10;
@property (nonatomic, assign) CGFloat ivar11;
@property (nonatomic, assign) double ivar12;
@property (nonatomic, assign) long ivar13;
@property (nonatomic, assign) long long ivar14;
@property (nonatomic, assign) long double ivar15;
@property (nonatomic, assign) short ivar16;
@property (nonatomic, assign) BOOL ivar17;

// 无符号
@property (nonatomic, assign) unsigned int ivar18;
@property (nonatomic, assign) unsigned char ivar19;
@property (nonatomic, assign) unsigned short ivar20;
@property (nonatomic, assign) unsigned long ivar21;
@property (nonatomic, assign) unsigned long long ivar22;

@property (nonatomic, assign) struct Node ivar23;
@property (nonatomic, assign) struct Node *ivar24;
@property (nonatomic, assign) CGRect ivar25;
@property (nonatomic, assign) NSValue *ivar26;
//@property (nonatomic, assign) c array ?

@property (nonatomic, strong) NSMutableArray *ivar27;
@end

@implementation ViewController {
    NSString *_hahaName;
}

- (NSString *)haha:(NSString *)arg1 age:(NSInteger)age {
    
    return @"hahah";
}

//- (void)setName:(NSString *)name {
//    if (_hahaName) {
//
//    }
//}
//
//- (NSString *)name {
//    return _hahaName;
//}

#pragma mark - XZHHahaProtocol

//- (void)haha1 {}
//- (void)haha2:(NSInteger)age {}
//- (NSDictionary *)haha3:(NSInteger)age name:(NSArray *)name {return nil;}
//+ (NSArray *)haha4 {return nil;}
//- (void)haha5:(NSInteger)age name:(NSString *)name {}
//- (NSInteger)haha6{return 0;}
//+ (NSString *)haha7{return nil;}


- (void)testProtocol {
    
//    unsigned int count;
//    struct objc_method_description *methods = protocol_copyMethodDescriptionList(@protocol(XZHHahaProtocol), YES, YES, &count);
//    
//    for(unsigned i = 0; i < count; i++)
//    {
//        NSString *signature = [NSString stringWithCString: methods[i].types encoding: [NSString defaultCStringEncoding]];
//        NSLog(@"method.name = %@, method.types = %@", NSStringFromSelector(methods[i].name), signature);
//    }
//    
//    free(methods);
    
//    id obj1 = @protocol(XZHHahaProtocol);
//    id obj2 = NSProtocolFromString(@"XZHHahaProtocol");
//    id obj3 = objc_getProtocol("XZHHahaProtocol");
    
//    XZHProtocolModel *model = [[XZHProtocolModel alloc] initWithProtocolName:@"XZHHahaProtocol"];
//    NSArray *array1 = [model methodsRequired:YES instance:YES];
//    NSArray *array2 = [model methodsRequired:YES instance:NO];
//    NSArray *array3 = [model methodsRequired:NO instance:YES];
//    NSArray *array4 = [model methodsRequired:NO instance:NO];

}

- (void)testTypesEncodings {
    
//    NSLog(@">>>>>>>Foundation 类对象>>>>>>>>>");
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(id)]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(NSArray*)]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(NSDictionary*)]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(NSSet*)]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(NSString*)]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(NSData*)]);
//    
//    NSLog(@">>>>>>> char >>>>>>>>>");
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(char)]);                   
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(unsigned char)]);
//    
//    NSLog(@">>>>>>>bool >>>>>>>>>");
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(BOOL)]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(Boolean)]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(boolean_t)]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(_Bool)]);
//    
//    NSLog(@">>>>>>> short >>>>>>>>>");
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(short)]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(unsigned short)]);
//
//    NSLog(@">>>>>>> int >>>>>>>>>");
    NSLog(@"%@", [NSString stringWithUTF8String:@encode(int)]);//==int32_t >>> i
    NSLog(@"%@", [NSString stringWithUTF8String:@encode(unsigned int)]);//I
    NSLog(@"%@", [NSString stringWithUTF8String:@encode(NSInteger)]);//==int64_t >>> q
    NSLog(@"%@", [NSString stringWithUTF8String:@encode(NSUInteger)]);//==uint64_t >>> Q
    NSLog(@"%@", [NSString stringWithUTF8String:@encode(int8_t)]);//c
    NSLog(@"%@", [NSString stringWithUTF8String:@encode(uint8_t)]);//C
    NSLog(@"%@", [NSString stringWithUTF8String:@encode(int16_t)]);//s
    NSLog(@"%@", [NSString stringWithUTF8String:@encode(uint16_t)]);//S
    NSLog(@"%@", [NSString stringWithUTF8String:@encode(int32_t)]);//i
    NSLog(@"%@", [NSString stringWithUTF8String:@encode(uint32_t)]);//I
    NSLog(@"%@", [NSString stringWithUTF8String:@encode(int64_t)]);//q
    NSLog(@"%@", [NSString stringWithUTF8String:@encode(uint64_t)]);//Q
//
//    NSLog(@">>>>>>> float >>>>>>>>>");
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(float)]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(CGFloat)]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(double)]);
//
//    NSLog(@">>>>>>> long >>>>>>>>>");
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(long)]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(unsigned long)]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(long long)]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(unsigned long long)]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(long double)]);
//
//    NSLog(@">>>>>> objc_class >>>>>>>>>>");
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(typeof([NSObject class]))]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(typeof([Person class]))]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(typeof([[Person new] class]))]);
//    
//    NSLog(@">>>>>> c >>>>>>>>>>");
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(char *)]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(int *)]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(void *)]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(CGRect)]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(CGPoint)]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(struct LinkMap1)]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(struct LinkMap2)]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(char[])]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(int[])]);
//    NSLog(@"%@", [NSString stringWithUTF8String:@encode(int[5])]);
}

- (void)testProperty {
//    objc_property_t property = class_getProperty([self class], "age");//name = T, value = @"NSString", name = G, value = myAge, name = S, value = setMyAge:
//    objc_property_t property = class_getProperty([self class], "price");
//    objc_property_t property = class_getProperty([self class], "list");
//    objc_property_t property = class_getProperty([self class], "mlist");
//    objc_property_t property = class_getProperty([self class], "dic");
//    objc_property_t property = class_getProperty([self class], "block3");//name = T, value = @?
//    objc_property_t property = class_getProperty([self class], "person");
//    objc_property_t property = class_getProperty([self class], "node");//name = T, value = ^{Node=i^{Node}}
    
//    objc_property_t property = class_getProperty([self class], "ivar1");
//    objc_property_t property = class_getProperty([self class], "ivar2");
//    objc_property_t property = class_getProperty([self class], "ivar3");
//    objc_property_t property = class_getProperty([self class], "ivar4");
//    objc_property_t property = class_getProperty([self class], "ivar5");
//    objc_property_t property = class_getProperty([self class], "ivar6");
//    objc_property_t property = class_getProperty([self class], "ivar7");
//    objc_property_t property = class_getProperty([self class], "ivar8");
//    objc_property_t property = class_getProperty([self class], "ivar9");
//    objc_property_t property = class_getProperty([self class], "ivar10");
//    objc_property_t property = class_getProperty([self class], "ivar11");
//    objc_property_t property = class_getProperty([self class], "ivar12");
//    objc_property_t property = class_getProperty([self class], "ivar13");
//    objc_property_t property = class_getProperty([self class], "ivar14");
//    objc_property_t property = class_getProperty([self class], "ivar15");
//    objc_property_t property = class_getProperty([self class], "ivar16");
//    objc_property_t property = class_getProperty([self class], "ivar17");
//    objc_property_t property = class_getProperty([self class], "ivar18");
//    objc_property_t property = class_getProperty([self class], "ivar19");
//    objc_property_t property = class_getProperty([self class], "ivar20");
//    objc_property_t property = class_getProperty([self class], "ivar21");
//    objc_property_t property = class_getProperty([self class], "ivar22");
//    objc_property_t property = class_getProperty([self class], "ivar23");
    objc_property_t property = class_getProperty([Dog class], "animales1");
    
    XZHPropertyModel *pModel = [[XZHPropertyModel alloc] initWithProperty:property];
    
//    objc_property_t property = class_getProperty([self class], "ivar24");
    
//    unsigned int num = 0;
//    objc_property_attribute_t *atts = property_copyAttributeList(property, &num);
//    for (int i = 0; i < num; i++) {
//        objc_property_attribute_t att = atts[i];
//        const char *name = att.name;
//        const char *value = att.value;
//        printf("name = %s, value = %s\n", name, value);
//    }
//    free(atts);
//    XZHPropertyModel *pModel = [[XZHPropertyModel alloc] initWithProperty:property];
//    const char*attributes = property_getAttributes(property);
}

- (void)testClass {
//    id obj1 = [[NSObject new] class];
//    id obj2 = objc_getClass("NSObject");

//    id obj1 = @"hahaha";
//    id obj2 = [@"hahaha" mutableCopy];
//    id obj3 = [NSString stringWithFormat:@"%@_%@", @"1", @"2"];
//    id obj4 = [obj3 copy];
//    id obj5 = [obj4 mutableCopy];
    
//    id obj1 = [@[] class];
//    id obj2 = [@[@"1"] class];
//    id obj3 = [[@[@"1"] mutableCopy] class];
//    id obj4 = objc_getClass("__NSArray0");
//    id obj5 = objc_getClass("__NSArrayI");
//    id obj6 = objc_getClass("__NSArrayM");
    
//    id obj1 = [[NSSet set] class];
//    id obj2 = [[NSSet setWithObjects:@"1", nil] class];
//    id obj3 = [[NSMutableSet setWithObjects:@"1", nil] class];
//    id obj4 = objc_getClass("__NSSetI");
//    id obj5 = objc_getClass("__NSSetM");
//    id obj6 = objc_getClass("__NSSingleObjectSetI");

//    id obj1 = [@{} class];
//    id obj2 = [@{@"key":@"value"} class];
//    id obj3 = [[@{@"key":@"value"} mutableCopy] class];
//    id obj4 = objc_getClass("__NSDictionary0");
//    id obj5 = objc_getClass("__NSDictionaryI");
//    id obj6 = objc_getClass("__NSDictionaryM");

//    id obj1 = [[NSDate date] class];
//    id obj1 = [[NSData data] class];
//    id obj2 = [[@"hahaah" dataUsingEncoding:NSUTF8StringEncoding] class];
////    [obj2 appendData:[NSData data]];
//    id obj3 = [[[@"hahaah" dataUsingEncoding:NSUTF8StringEncoding] mutableCopy] class];
////    [obj3 appendData:[NSData data]];
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"goodslistitemdetail_bubble@2x" ofType:@"png"];
//    id obj4 = [[NSData alloc] initWithContentsOfFile:path];
//    id obj5 = [obj4 mutableCopy];
//    [obj5 appendData:[NSData data]];
    
//    id obj1 = @1;
//    id obj2 = @(2);
//    id obj3 = [NSNumber numberWithInteger:20];
//    id obj4 = [NSDecimalNumber numberWithInteger:19];
//    id obj5 = [NSDecimalNumber decimalNumberWithMantissa:1275 exponent:-2 isNegative:NO];   //12.75
//    id obj6 = [NSDecimalNumber decimalNumberWithMantissa:1275 exponent:2 isNegative:YES];   //-127500
    
//    id obj1 = [@"hahaha" class];
//    id obj2 = [[NSString stringWithFormat:@"hahaha"] class];
//    id obj3 = [[NSString stringWithFormat:@"hahaha%@", @"ahahaha"] class];
//    id obj4 = [[[NSString alloc] initWithString:@"hahaha"] class];
//    id obj5 = [obj1 mutableCopy];
////    [obj5 appendString:@"111"];
//    id obj6 = [[NSMutableString alloc] init];
//    [obj6 appendString:@"111"];
//    id obj7 = [[NSMutableString alloc] initWithString:@"hahah1111"];
//    [obj7 appendString:@"111"];
//    id obj8 = [obj7 stringByAppendingString:@"cache"];
    
//    id obj1 = [NSValue valueWithRange:NSMakeRange(0, 2)];
//    id obj2 = [NSValue value:"hahaha" withObjCType:"*"];
    
//    void (^block1)(void) = ^(){};
//    
//    NSInteger i = 0;
//    void (^block2)(void) = ^(){
//        NSLog(@"i");
//    };
//    
//    _block3 = ^() {
//        [self description];
//    };
    
//    Class cls1 = objc_getClass("NSArray");
//    Class cls2 = [NSArray class];
//    NSLog(@"%p", cls1);
//    NSLog(@"%p", cls2);
}

- (void)testClassFunc {
//    XZHFoundationType type1 = XZHGetClassFoundationType([NSObject class]);
//    XZHFoundationType type2 = XZHGetClassFoundationType([NSArray class]);
//    XZHFoundationType type3 = XZHGetClassFoundationType([NSMutableArray class]);
//    XZHFoundationType type4 = XZHGetClassFoundationType([NSSet class]);
//    XZHFoundationType type5 = XZHGetClassFoundationType([NSMutableSet class]);
//    XZHFoundationType type6 = XZHGetClassFoundationType([NSDictionary class]);
//    XZHFoundationType type7 = XZHGetClassFoundationType([NSMutableDictionary class]);
//    XZHFoundationType type8 = XZHGetClassFoundationType([NSDate class]);
//    XZHFoundationType type9 = XZHGetClassFoundationType([NSData class]);
//    XZHFoundationType type10 = XZHGetClassFoundationType([NSMutableData class]);
//    XZHFoundationType type11 = XZHGetClassFoundationType([NSNumber class]);
//    XZHFoundationType type12 = XZHGetClassFoundationType([NSDecimalNumber class]);
//    XZHFoundationType type13 = XZHGetClassFoundationType([NSString class]);
//    XZHFoundationType type14 = XZHGetClassFoundationType([NSMutableString class]);
//    XZHFoundationType type15 = XZHGetClassFoundationType([NSValue class]);
//    XZHFoundationType type16 = XZHGetClassFoundationType([NSNull class]);
//    void(^block)(void) = ^() {
//        NSLog(@"%@", self);
//    };
//    XZHFoundationType type17 = XZHGetClassFoundationType([block class]);
//    XZHFoundationType type18 = XZHGetClassFoundationType([Person class]);
    
}

- (void)testObjectFunc {
//    XZHFoundationType type1 = XZHGetObjectFoundationType([NSObject new]);
//    XZHFoundationType type2 = XZHGetObjectFoundationType(@[@"1", @"2"]);
//    XZHFoundationType type3 = XZHGetObjectFoundationType([[NSMutableArray alloc] initWithObjects:@"1", nil] );
//    XZHFoundationType type4 = XZHGetObjectFoundationType([NSSet setWithObject:@"1"]);
//    XZHFoundationType type5 = XZHGetObjectFoundationType([NSMutableSet setWithObject:@"1"]);
//    XZHFoundationType type6 = XZHGetObjectFoundationType(@{@"key":@"value"});
//    XZHFoundationType type7 = XZHGetObjectFoundationType([@{@"key":@"value"} mutableCopy]  );
//    XZHFoundationType type8 = XZHGetObjectFoundationType([NSDate date] );
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"goodslistitemdetail_bubble@2x" ofType:@"png"];
//    id obj1 = [[NSData alloc] initWithContentsOfFile:path];
//    XZHFoundationType type9 = XZHGetObjectFoundationType(obj1);
//    XZHFoundationType type10 = XZHGetObjectFoundationType([obj1 mutableCopy]);
//    XZHFoundationType type11 = XZHGetObjectFoundationType(@(19) );
//    XZHFoundationType type12 = XZHGetObjectFoundationType([NSDecimalNumber decimalNumberWithString:@"1999"] );
//    XZHFoundationType type13 = XZHGetObjectFoundationType(@"hello" );
//    XZHFoundationType type14 = XZHGetObjectFoundationType([@"hello" mutableCopy] );
//    XZHFoundationType type15 = XZHGetObjectFoundationType([NSValue value:"hahaha" withObjCType:"*"] );
//    XZHFoundationType type16 = XZHGetObjectFoundationType([NSNull null] );
//    XZHFoundationType type17 = XZHGetObjectFoundationType((id)kCFNull );
//    void(^block)(void) = ^() {
//        NSLog(@"%@", self);
//    };
//    XZHFoundationType type18 = XZHGetObjectFoundationType(block);
//    XZHFoundationType type19 = XZHGetObjectFoundationType([Person new]);
    
}

- (void)testMethod {
    Method m = class_getInstanceMethod([Person class], NSSelectorFromString(@"log:"));
    XZHMethodModel *method = [[XZHMethodModel alloc] initWithMethod:m];
}

- (void)setHahaname:(NSString *)name {
    _hahaName = [name copy];
}

- (NSString *)hahaname {
    return _hahaName;
}

- (void)testMethodWithName:(in NSString *)name age:(inout int)age{
    NSLog(@"name = %@, age = %d", name, age);
    name = @"Hello";
    age = 19;
}

- (void)testKVC {
    
    // KVC KeyPath 异常捕获
    @try {
        [self valueForKeyPath:@"ahahha.dwd.dwd"];
    }
    @catch (NSException *exception) {
        NSLog(@"hahahahahahha");
    }
    @finally {
        
    }
    
    Wife *obj = [Wife new];
    [obj setValue:@(19.23232) forKey:@"pro1"];
    [obj setValue:@(19.23232) forKey:@"pro2"];
    [obj setValue:@(9999) forKey:@"pro3"];
    //    [obj setValue:@(19.23232) forKey:@"pro4"];//不支持long double 实例变量的 KVC
    //    ((void (*)(id, SEL, long double)) (void *) objc_msgSend)(obj, @selector(setPro4:), 19.23232);
    
    //    NSLog(@"%c", [[NSNumber numberWithChar:'K'] charValue]);
    //    NSLog(@"%c", [[NSNumber numberWithChar:'Kssss'] charValue]);
    
    //    ((void (*)(id, SEL, void(^)()))(void *) objc_msgSend)(self, @selector(setBlock:), ^(NSInteger age){NSLog(@"age = %ld", age);});
    //    _block(19);
}

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
    
    //6. 设置struct属性值
    struct Node node_3 = {1, YES, 'M'};
    ((void (*)(id, SEL, struct Node))(void *) objc_msgSend)(self, @selector(setIvar23:), node_3);
    
    CGRect rect = {10, 20, 100, 200};
    ((void (*)(id, SEL, struct Node))(void *) objc_msgSend)(self, @selector(setIvar25:), node_3);
    
    NSValue *value19 = [NSValue valueWithCGRect:rect];
    ((void (*)(id, SEL, NSValue*))(void *) objc_msgSend)(self, @selector(setIvar26:), value19);
    
}

- (void)testJSONMapping1 {
    
    
    // KVC默认将 NSNumber <<===> int、float、double... 之间进行转换
     
    // NSNumber >>> int、float、double...
//    id dic = @{
//           @"key1" : @(19),
//           @"key2" : @{
//                   @"key3" : @(20),
//                   },
//           };
//
//    id value1 = [dic valueForKey:@"key1"];
//    id value2 = [dic valueForKeyPath:@"key2.key3"];
//    NSLog(@"value1.class = %@", [value1 class]);
//    NSLog(@"value2.class = %@", [value2 class]);
    
    // int、float、double... >>> NSNumber
//    TestObj *obj = [TestObj new];
//    [obj setValue:@(1) forKey:@"_value1"];
//    [obj setValue:@(2) forKey:@"_value2"];
//    [obj setValue:@(3.0) forKey:@"_value3"];
//    NSLog(@"%@", obj);
//
//    NSLog(@"value1 = %@, class = %@", [obj valueForKey:@"_value1"], [[obj valueForKey:@"_value1"] class]);
//    NSLog(@"value2 = %@, class = %@", [obj valueForKey:@"_value2"], [[obj valueForKey:@"_value2"] class]);
//    NSLog(@"value3 = %@, class = %@", [obj valueForKey:@"_value3"], [[obj valueForKey:@"_value3"] class]);
    
}

- (void)testJSONMapping2 {
id json = @{
            @"name" : @"dog001",
            @"data" : @{
                        @"uid" : @(100001),
//                            @"uid" : @"100001", NSString >>> NSNumber
//                            @"uid" : [NSNull null], NSNumber >>> nil
                    },
            @"p_age" : @"21",
            @"address1" : @"address1......",
            @"address2" : @"address2......",
            @"address3" : @"address3......",
            @"user" : @{
                    @"city" : @{
                            @"address" : @"address4.....",
                            },
                    },
            @"sex" : @"男",
            };

Dog *dog = [Dog xzh_modelFromObject:json];
}

- (void)testJSONMapping3 {
//    id json = @{
//                @"name" : @"dog001",
//                @"data" : @{
//                            @"uid" : @(100001),
//                            @"uid" : @"100001",
//                            @"uid" : @"nil",
//                            @"uid" : @"Nil",
//                            @"uid" : @"NULL",
//                            @"uid" : @"null",
//                            @"uid" : @"<null>",
//                            @"uid" : [NSNull null],
//                        },
//                @"p_age" : @"21",
//                @"user" : @{
//                        @"city" : @{
//                                @"address" : @"address4.....",
//                                },
//                        },
//                @"sex" : @"男",
//                @"animal" : @{
//                        @"cat" : @{
//                                @"c_id" : @"111111",
//                                @"c_name" : @"cat_0000001",
//                                },
//                        },
//                };
    
    id json = @{
                    @"name" : @"dog001",
                    @"data" : @{
                            @"uid" : @(100001),
//                            @"uid" : @"100001",
//                            @"uid" : @"nil",
//                            @"uid" : @"Nil",
//                            @"uid" : @"NULL",
//                            @"uid" : @"null",
//                            @"uid" : @"<null>",
//                            @"uid" : [NSNull null],
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
                
                };
    
    Dog *dog = [Dog xzh_modelFromObject:json];
    
    NSLog(@"");
}

- (void)testJSONMapping4 {
    id json = @{
                @"name" : @"dog001",
                @"data" : @{
                        @"uid" : @(100001),
//                            @"uid" : @"100001", NSString >>> NSNumber
//                            @"uid" : [NSNull null], NSNumber >>> nil
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
                                @"c_id" : @"111111",
                                @"c_name" : @"cat_0000001",
                                },
                            },
                @"cat" : @{
                        @"c_id" : @"111111",
                        @"c_name" : @"cat_0000001",
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
                @"flag5" : @"false",
                @"flag6" : @"true",
                @"flag7" : @"YES",
                @"flag8" : @"NO",
                };

    
    double date_s = CFAbsoluteTimeGetCurrent();
    Dog *dog = [Dog xzh_modelFromObject:json];
    double date_current = CFAbsoluteTimeGetCurrent() - date_s;
    NSLog(@"consumeTime: %f μs",date_current * 11000 * 1000);
}

- (void)testJSONMapping5 {
    
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
//                @"cat" : @{
//                        @"c_id" : @"111111",
//                        @"c_name" : @"cat_0000001",
//                        },
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
                @"childs" : @[],
                @"childs" : [NSNull null],
                @"date" : @"Wed Dec 25 12:22:19 +0800 2013",
                @"url" : @"http://tp2.sinaimg.cn/3952070245/180/5737272572/0",
                @"flag1" : @(0),
                @"flag2" : @(1),
                @"flag3" : @"0",
                @"flag4" : @"1",
                @"flag5" : @"false",
                @"flag6" : @"true",
                @"flag7" : @"YES",
                @"flag8" : @"NO",
                };
    
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        Dog *dog = [Dog xzh_modelFromObject:json];
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        Dog *dog = [Dog xzh_modelFromObject:json];
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        Dog *dog = [Dog xzh_modelFromObject:json];
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        Dog *dog = [Dog xzh_modelFromObject:json];
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        Dog *dog = [Dog xzh_modelFromObject:json];
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        Dog *dog = [Dog xzh_modelFromObject:json];
    });
    
}

- (void)testJSONMapping6 {
    objc_property_t property1 = class_getProperty([Dog class], "animales1");
    XZHPropertyModel *model1 = [[XZHPropertyModel alloc] initWithProperty:property1];
    NSLog(@"%@", model1.encodingString);//NSArray<Animal>
    
//    objc_property_t property2 = class_getProperty([Dog class], "animales2");
//    XZHPropertyModel *model2 = [[XZHPropertyModel alloc] initWithProperty:property2];
//    NSLog(@"%@", model2.encodingString);//NSArray
//    
//    objc_property_t property3 = class_getProperty([Dog class], "block");
//    XZHPropertyModel *model3 = [[XZHPropertyModel alloc] initWithProperty:property3];
//    NSLog(@"%@", model3.encodingString);//@?

}

- (void)testJSONMapping7 {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"user" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    int count = 100000;
    double date_s = CFAbsoluteTimeGetCurrent();
    for (int i = 0; i < count; i++) {
//       YYModelUserModel *model = [YYModelUserModel yy_modelWithJSON:json];
        XZHRuntimeUserModel *model = [XZHRuntimeUserModel xzh_modelFromJSONDictionary:json];
//        NSLog(@"");
    }
    double date_current = CFAbsoluteTimeGetCurrent() - date_s;
    NSLog(@"consumeTime: %f μs",date_current * 11000 * 1000);
}

- (void)testJSONMapping8 {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"user" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
   YYModelUserModel *model = [YYModelUserModel yy_modelWithJSON:json];
//    XZHRuntimeUserModel *model = [XZHRuntimeUserModel xzh_modelFromJSONDictionary:json];
    
    int count = 100000;
    double date_s = CFAbsoluteTimeGetCurrent();
    for (int i = 0; i < count; i++) {
//        id json = [model xzh_modelToJSONObject];
        id json = [model yy_modelToJSONObject];
//        NSLog(@"");
    }
    double date_current = CFAbsoluteTimeGetCurrent() - date_s;
    NSLog(@"consumeTime: %f μs",date_current * 11000 * 1000);
}

- (void)testJSONMapping9 {
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
    
    Dog *dog = [Dog xzh_modelFromJSONDictionary:json];
    id jsonObj = [dog xzh_modelToJSONObject];
    
}

- (void)testHash {
    NSUInteger NIL_hash1 = [@"NIL" hash];
    NSUInteger Nil_hash = [@"Nil" hash];
    NSUInteger nil_hash = [@"nil" hash];
    NSUInteger NULL_hash = [@"NULL" hash];
    NSUInteger Null_hash = [@"Null" hash];
    NSUInteger null_hash = [@"null" hash];
    NSUInteger _NULL_hash = [@"(NULL)" hash];
    NSUInteger _Null_hash = [@"(Null)" hash];
    NSUInteger _null_hash = [@"(null)" hash];
    NSUInteger __NULL_hash = [@"<NULL>" hash];
    NSUInteger __Null_hash = [@"<Null>" hash];
    NSUInteger __null_hash = [@"<null>" hash];
    
}

- (void)testTypeConvert {
    //NSMutableArray对象
    NSMutableArray *arr = [@[@"1", @"2"] mutableCopy];
    
    //将NSMutableArray对象，按照NSArray类型设置
    ((void (*)(id, SEL, NSArray*))(void *) objc_msgSend)(self, @selector(setIvar27:), arr);
    
    [_ivar27 addObject:@"3"];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [self testProtocol];
//    [self testTypesEncodings];
//    [self testProperty];
//    [self testClass];
//    [self testClassFunc];
//    [self testObjectFunc];
//    [self testMethod];
//    [self testKVC];
//    [self testNSValue1];
//    [self testJSONMapping1];
//    [self testJSONMapping2];
//    [self testJSONMapping3];
//    [self testJSONMapping4];
    [self testJSONMapping5];
//    [self testJSONMapping6];
//    [self testJSONMapping7];
//    [self testHash];
//    [self testTypeConvert];
//    [self testJSONMapping8];
//    [self testJSONMapping9];
}









@end
