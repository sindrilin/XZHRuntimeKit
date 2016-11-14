//
//  XZHRuntime.h
//  XZHRuntimeDemo
//
//  Created by XiongZenghui on 16/8/26.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//
//  ObjectiveC2.0数据类型对应的objc结构体可以在http://opensource.apple.com//tarballs/objc4/查看.

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#define xzh_force_inline __inline__ __attribute__((always_inline))

/**
 * 
    ************************************************************************************************
    Objective-C中所有数据类型的type encodings定义，主要分为三类（参考自YYModel）:
        - (1) Ivar/ReturnValue返回值 类型编码  >>>>  单选
        - (2) Method的编码，方法修饰符   >>>>  多选
        - (3) Property的编码，属性读取修饰符、getter/setter生成修饰符、内存管理修饰符   >>>>  多选
 
    我觉得其实Ivar的编码包括在Property的编码中。
    所有的类型编码可参考: https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
    
    ************************************************************************************************
    如下是参考YYModel，将如上三种type encoding集合在一起的结构:
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
     
     - (2) method's type encodings
        - `r` >>> const
        - `n` >>> in
        - `N` >>> inout
        - `o` >>> out
        - `O` >>> bycopy
        - `R` >>> byref
        - `V` >>> oneway
    ************************************************************************************************
 */
typedef NS_ENUM(NSInteger, XZHTypeEncoding) {
    
////////////////////////////////////////////////////////////////////////////////////////////////
/// Objective-c 常用数据类型编码 0xFF >>> 1111,1111
////////////////////////////////////////////////////////////////////////////////////////////////
    XZHTypeEncodingDataTypeMask                                         = 0xFF,
    
    // 基本数据类型、Foundation Obejct类型
    XZHTypeEncodingsUnKnown                                             = 0,//? >>> An unknown type (among other things, this code is used for function pointers)
    XZHTypeEncodingFoundationObject                                     = 1,// @ >>> OC Foudnation Object
    XZHTypeEncodingChar                                                 = 2,//c >>> A char、int8_t、
    XZHTypeEncodingUnsignedChar                                         = 3,//C >>> An unsigned char、uint8_t
    XZHTypeEncodingBOOL                                                 = 4,//B >>> BOOL
    XZHTypeEncodingShort                                                = 5,//s >>> A short、int16_t、
    XZHTypeEncodingUnsignedShort                                        = 6,//S >>> A unsigned short、uint16_t
    XZHTypeEncodingInt                                                  = 7,//i >>> An int、int32_t、
    XZHTypeEncodingUnsignedInt                                          = 8,//I >>> An unsigned int、uint32_t
    XZHTypeEncodingFloat                                                = 9,//f >>> A float
    XZHTypeEncodingLong32                                               = 10,//l >>> A long，l is treated as a 32-bit quantity on 64-bit programs.
    XZHTypeEncodingLongLong                                             = 11,//q >>> A long long/int64_t
    XZHTypeEncodingUnsignedLong                                         = 12,//L >>> An unsigned long
    XZHTypeEncodingUnsignedLongLong                                     = 13,//Q >>> An unsigned long long/uint64_t
    XZHTypeEncodingDouble                                               = 14,//d >>> A double
    XZHTypeEncodingLongDouble                                           = 15,// Objective-C does not support the long double type. @encode(long double) returns d, which is the same encoding as for double
    
    // c语法据类型编码
    XZHTypeEncodingVoid                                                 = 16,//V >>> A void return value type
    XZHTypeEncodingCString                                              = 17,//* >>> A character string (char *)
    XZHTypeEncodingObjcClass                                            = 18,//# >>> A struct objc_class instance
    XZHTypeEncodingSEL                                                  = 19,//: >>> A struct objc_selector instance
    XZHTypeEncodingCArray                                               = 20,//@encode(int[5]) >>> [5i] >>> [长度, 数组元素类型编码]
    XZHTypeEncodingCStruct                                              = 21,//@encode(CGPint) >>> {CGPoint=dd} >>> d是double >>> 两个double变量
    XZHTypeEncodingCUnion                                               = 22,//(name=type...) 与 Struct不同的是括号
    XZHTypeEncodingCPointer                                             = 23,//@encode(char *) >>> ^i >>> ^类型
    XZHTypeEncodingCBitFields                                           = 24,//bnum >>> A bit field of num bits (这个好像用的很少在iOS中)
    
////////////////////////////////////////////////////////////////////////////////////////////////
/// Objective-C method 编码 0xFF00 >>> 1111,1111,0000,0000
/// 方法的修饰符是可以叠加的
///
///     r const
///     n in
///     N inout
///     o out
///     O bycopy
///     R byref
///     V oneway
////////////////////////////////////////////////////////////////////////////////////////////////
    XZHTypeEncodingMethodMask                                           = 0xFF00,
    XZHTypeEncodingMethodConst                                          = 1<<8,
    XZHTypeEncodingMethodIn                                             = 1<<9,
    XZHTypeEncodingMethodInOut                                          = 1<<10,
    XZHTypeEncodingMethodOut                                            = 1<<11,
    XZHTypeEncodingMethodByCopy                                         = 1<<12,
    XZHTypeEncodingMethodByRef                                          = 1<<13,
    XZHTypeEncodingMethodOneWay                                         = 1<<14,

    
////////////////////////////////////////////////////////////////////////////////////////////////
/// Objective-C @property属性类型编码 0xFF0000 >>> 1111,1111,0000,0000,0000,0000
/// 属性修饰符是可以互相叠加的
///
///    T Means this is property's encoding type string. 比如: @property(copy) id name; >>> T@,C,Vname
///    V The instance variable's name (ivar name)
///    R The property is read-only (readonly).
///    C The property is a copy of the value last assigned (copy).
///    & The property is a reference to the value last assigned (retain).
///    N The property is non-atomic (nonatomic).
///    G<name> The property defines a custom getter selector name. The name follows the G (@property (getter=hahaname) NSString *name;).
///    S<name> The property defines a custom setter selector name. The name follows the S (@property (setter=setHahaname:) NSString *name;).
///    D The property is dynamic (@dynamic).
///    W The property is a weak reference (__weak).
///    P The property is eligible for garbage collection.
///    t<encoding> Specifies the type using old-style encoding.
///    @property char charDefault;                         Tc,VcharDefault
///    @property double doubleDefault;                     Td,VdoubleDefault
///    @property enum FooManChu enumDefault;               Ti,VenumDefault
///    @property float floatDefault;                       Tf,VfloatDefault
///    @property int intDefault;                           Ti,VintDefault
///    @property long longDefault;                         Tl,VlongDefault
///    @property short shortDefault;                       Ts,VshortDefault
///    @property signed signedDefault;                     Ti,VsignedDefault
///    @property struct YorkshireTeaStruct structDefault;  T{YorkshireTeaStruct="pot"i"lady"c},VstructDefault
///    @property YorkshireTeaStructType typedefDefault;    T{YorkshireTeaStruct="pot"i"lady"c},VtypedefDefault
///    @property union MoneyUnion unionDefault;            T(MoneyUnion="alone"f"down"d),VunionDefault
///    @property unsigned unsignedDefault;                 TI,VunsignedDefault
///    @property int (*functionPointerDefault)(char *);    T^?,VfunctionPointerDefault
///    @property id idDefault;
///////////////////////////////////////////////////////////////////////////////////////////////////////
    XZHTypeEncodingPropertyMask                                             = 0xFF0000,
//    XZHTypeEncodingPropertyT  表示属性的编码字符串
//    XZHTypeEncodingPropertyV  表示Ivar的名字
    XZHTypeEncodingPropertyCopy                                             = 1<<16,
    XZHTypeEncodingPropertyCustomGetter                                     = 1<<17,
    XZHTypeEncodingPropertyCustomSetter                                     = 1<<18,
    XZHTypeEncodingPropertyDynamic                                          = 1<<19,
//    XZHTypeEncodingPropertyGarbageCollection                                = 1<<20, iOS不能使用
    XZHTypeEncodingPropertyNonatomic                                        = 1<<20,
    XZHTypeEncodingPropertyReadonly                                         = 1<<21,
    XZHTypeEncodingPropertyStrong                                           = 1<<22,
    XZHTypeEncodingPropertyWeak                                             = 1<<23,
//    XZHTypeEncodingPropertyOldStyleCoding                                   = 1<<24, //iOS SDK版本太老，现在基本上用不到
};

/**
 *  Objective-C Foundation 对象类型，参考Foundation.h中常用的类型
 */
typedef NS_ENUM(NSInteger, XZHFoundationType) {
    XZHFoundationTypeNone   = 0,
    XZHFoundationTypeNSString,
    XZHFoundationTypeNSMutableString,
    XZHFoundationTypeNSNumber,
    XZHFoundationTypeNSDecimalNumber,
    XZHFoundationTypeNSURL,
    XZHFoundationTypeNSArray,
    XZHFoundationTypeNSMutableArray,
    XZHFoundationTypeNSSet,
    XZHFoundationTypeNSMutableSet,
    XZHFoundationTypeNSDictionary,
    XZHFoundationTypeNSMutableDictionary,
    XZHFoundationTypeNSDate,
    XZHFoundationTypeNSData,
    XZHFoundationTypeNSMutableData,
    XZHFoundationTypeNSValue,
    XZHFoundationTypeNSNull,
    XZHFoundationTypeNSBlock,//Foundation中没有直接暴露NSBlock这个Class，需要使用代码进行获取
    XZHFoundationTypeCustomer,//自定义的NSObject子类
};

@class XZHClassModel;

/*
    struct objc_ivar {
        char *ivar_name                                          OBJC2_UNAVAILABLE;
        char *ivar_type                                          OBJC2_UNAVAILABLE;
        int ivar_offset                                          OBJC2_UNAVAILABLE;
    #ifdef __LP64__
        int space                                                OBJC2_UNAVAILABLE;
    #endif
    }
 */

@interface XZHIvarModel : NSObject
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *ivarName;
@property (nonatomic, copy, readonly) NSString *type;

/**
 *  注意，对于已经存在源文件的OC类，是无法在运行时添加Ivar的，代码不会崩溃但是不会起任何话作用
 *  只有那些在运行时register的OC类，才可以添加Ivar
 */
@property (nonatomic, assign, readonly) ptrdiff_t offset;
- (instancetype)initWithIvar:(Ivar)ivar;
- (BOOL)isEqualToIvar:(XZHIvarModel *)object;
@end

/**
    typedef struct {
        const char *name;
        const char *value;
    } objc_property_attribute_t;
 
    struct objc_property {
        const char *name;
        const char *attributes;
    };
 */

@interface XZHPropertyModel : NSObject
@property (nonatomic, copy, readonly) NSString *name;//实例变量Ivar名，如：_name
@property (nonatomic, strong) NSArray<NSString *> *protocols;//如: @property (nonatomic, strong) NSArray<协议1,协议2,协议3...> *arr;
@property (nonatomic, assign, readonly) SEL getter;//如：name
@property (nonatomic, assign, readonly) SEL setter;//如：setName:
@property (nonatomic, assign, readonly) XZHTypeEncoding typeEncoding;
@property (nonatomic, assign, readonly) XZHFoundationType foundationType;
@property (nonatomic, assign, readonly) Class cls;//Ivar的类型
@property (nonatomic, copy, readonly) NSString *encodingString;//name=T,value=@NSArray、{CGSize=ff}...
@property (nonatomic, assign, readonly) BOOL isCNumber;// Ivar是否是c基本数值类型
@property (nonatomic, assign, readonly) BOOL isCanArchived;// Ivar类型是否支持归档
@property (nonatomic, assign, readonly) BOOL isKVCCompatible;// Ivar值是否能够使用KVC

- (instancetype)initWithProperty:(objc_property_t)property;
- (BOOL)isEqualToProperty:(XZHPropertyModel *)property;
@end

/*
    struct objc_method {
        SEL method_name                                          OBJC2_UNAVAILABLE;
        char *method_types                                       OBJC2_UNAVAILABLE;
        IMP method_imp                                           OBJC2_UNAVAILABLE;
    }
 
    struct objc_method_description {
        SEL name;
        char *types;
    };
*/

@interface XZHMethodModel : NSObject
@property (nonatomic, assign, readonly) SEL sel;
@property (nonatomic, copy, readonly) NSString *selString;
@property (nonatomic, copy, readonly) NSString *returnType;
@property (nonatomic, copy, readonly) NSArray *argumentTypes;
@property (nonatomic, copy, readonly) NSString *type;
@property (nonatomic, assign, readonly) IMP imp;

- (instancetype)initWithMethod:(Method)method;

- (BOOL)isEqualToMethod:(XZHMethodModel *)method;

@end

/**
    typedef struct objc_object Protocol;
    struct objc_object {
        Class isa  OBJC_ISA_AVAILABILITY;
    };
 
    注意: 如果仅仅是声明了一个协议，而未在任何类中实现或使用这个协议，那么获取methods将会为nil
    必须至少使用这个协议进行声明，eg、@interface MyClass () <XZHHahaProtocol> .....
 */
@interface XZHProtocolModel : NSObject
@property (nonatomic, copy, readonly) NSString *name;
- (instancetype)initWithProtocol:(Protocol *)protocol;
- (instancetype)initWithProtocolName:(NSString *)protocolName;

/**
 *  获取这个协议中 可选实现、必选实现、对象方法、类方法 这四种类型的method数组
 *
 *  @param isRequiredMethod 可选实现 or 必选实现
 *  @param isInstanceMethod 对象方法 or 类方法
 *
 *  @return
 */
- (NSArray *)methodsRequired:(BOOL)isRequiredMethod instance:(BOOL)isInstanceMethod;


@end

/*
    struct objc_category {
        char *category_name                                      OBJC2_UNAVAILABLE;
        char *class_name                                         OBJC2_UNAVAILABLE;
        struct objc_method_list *instance_methods                OBJC2_UNAVAILABLE;
        struct objc_method_list *class_methods                   OBJC2_UNAVAILABLE;
        struct objc_protocol_list *protocols                     OBJC2_UNAVAILABLE;
    }
 */

@interface XZHCategoryModel : NSObject
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *class_name;
@property (nonatomic, strong, readonly) NSArray<XZHMethodModel*> *method_list;
@property (nonatomic, strong, readonly) NSArray<XZHClassModel*> *class_list;
@property (nonatomic, strong, readonly) NSArray<XZHProtocolModel*> *protocol_list;
@end

/*
    struct objc_class {
        Class isa;
    #if !__OBJC2__
        Class super_class                                        OBJC2_UNAVAILABLE;
        const char *name                                         OBJC2_UNAVAILABLE;
        long version                                             OBJC2_UNAVAILABLE;
        long info                                                OBJC2_UNAVAILABLE;
        long instance_size                                       OBJC2_UNAVAILABLE;
        struct objc_ivar_list *ivars                             OBJC2_UNAVAILABLE;
        struct objc_method_list **methodLists                    OBJC2_UNAVAILABLE;
        struct objc_cache *cache                                 OBJC2_UNAVAILABLE;
        struct objc_protocol_list *protocols                     OBJC2_UNAVAILABLE;
    #endif
        
    } OBJC2_UNAVAILABLE;
 */

@interface XZHClassModel : NSObject
@property (nonatomic, assign, readonly) BOOL isMeta;
@property (nonatomic, strong, readonly) Class superCls;
@property (nonatomic, strong, readonly) XZHClassModel *superClassModel;
@property (nonatomic, copy, readonly)   NSString *name;
@property (nonatomic, strong, readonly) NSDictionary<NSString*, XZHPropertyModel*> *propertyMap;// 属性名 : PropertyModel
@property (nonatomic, strong, readonly) NSDictionary<NSString*, XZHIvarModel*> *ivarMap;// 实例变量名 : IvarModel
@property (nonatomic, strong, readonly) NSDictionary<NSString*, XZHMethodModel*> *methodMap;// 方法SEL : MethodModel
@property (nonatomic, strong, readonly) NSDictionary<NSString*, XZHProtocolModel*> *protocolMap;// 协议名 : ProtocolModel

/**
 *  创建/查询缓存
 *
 *  @param cls          objc_class实例
 *  @param isNeedUpdate 是否需要重新解析Class
 */
+ (instancetype)instanceWithClass:(Class)cls;
+ (instancetype)instanceWithClassName:(char *)name;

/**
 *  如果是通过runtime函数添加了Property，则找到对应的ClassModel对象调用这个方法
 *  重新解析Class结构
 */
- (void)setNeedUpdate;

- (BOOL)isNeedUpdate;

@end

@interface NSObject (XZHSendMessage)

/**
 *  可以获取返回值的performSelector
 
    假设有如下OC函数:
 
     @implementation ViewController
     
     - (NSString *)haha:(NSString *)arg1 age:(NSInteger)age {
        return @"hahah";
     }
    
    错误的peformSelector使用方式:
        NSString *ret = [self xzh_performSelector:@selector(haha:age:) withObjects:@"name", 19]; 参数传入必须使用OC类对象
        NSString *ret = [self xzh_performSelector:@selector(haha:age:) withObjects:@"name", @19]; 参数必须以nil作为结束
    
    正确的peformSelector使用方式:
        NSString *ret = [self xzh_performSelector:@selector(haha:age:) withObjects:@"name", @19, nil];
 
 */
- (id)xzh_performSelector:(SEL)aSelector withObjects:(id)object, ...;

@end

Class XZHGetNSBlockClass();
