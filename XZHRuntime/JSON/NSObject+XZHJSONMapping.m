//
//  NSObject+XZHJSONMapping.m
//  XZHRuntimeDemo
//
//  Created by XiongZenghui on 16/9/11.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import "NSObject+XZHJSONMapping.h"
#import <objc/message.h>
#import "XZHRuntime.h"

/**
 *  属性映射jsonkey的类型
 */
typedef NS_ENUM(NSInteger, XZHPropertyMappedToJsonKeyType) {
    /**
     *  映射的jsonkey
     */
    XZHPropertyMappedToJsonKeyTypeSimple             = 1,
    /**
     *  带有路径的jsonkey
     */
    XZHPropertyMappedToJsonKeyTypeKeyPath,
    /**
     *  映射多个jsonkey
     */
    XZHPropertyMappedToJsonKeyTypeKeyArray,
};

@class XZHPropertyMapper;

typedef struct XZHJsonToModelContext {
    void *model;            // 实体类的一个对象
    void *classMapper;      // 实体类的ClassMapper
    void *jsonDic;          // 要解析的jsonDic
}XZHJsonToModelContext;

typedef struct XZHModelToJsonContext {
    void *model;            // 从哪一个对象转成json对象
    void *objectDic;        // 最终转换成的json对象
}XZHModelToJsonContext;

/**
 *  日期字符串格式化
 */
static xzh_force_inline NSDateFormatter* XZHDateFormatter(__unsafe_unretained NSString *dateFormat);

/**
 *  json字符串转换成NSDictioanry
 */
static xzh_force_inline NSDictionary* XZHJSONStringToDic(__unsafe_unretained NSString *jsonString);

/**
 *  从NSDictionary中使用keypath获取值，防止崩溃处理
 */
static xzh_force_inline id XZHGetValueFromDictionaryWithKeyPath(__unsafe_unretained NSDictionary *dic, __unsafe_unretained NSString *keyPath);

/**
 *  NSString/NSNumber/NSNull >>> NSNumber
 */
static xzh_force_inline NSNumber* XZHNumberWithValue(__unsafe_unretained id value);

/**
 *  将Objective-C实体类对象的属性值转换成NSNumber
 */
static xzh_force_inline NSNumber* XZHNumberWithModelProperty(__unsafe_unretained id object, __unsafe_unretained XZHPropertyMapper *mapper);

/**
 *  将id value根据property mapper记录的jsonkey，设置给property mapper保存的objc_property属性变量
 *  只接收Foundation类型对象，(Class、Method、SEL、等CoreFoundation实例、c指针需要使用NSValue预先包装好)
 *
 *  @param jsonItemValue        对应的jsonValue，只接受三种Foundation类型值: 1)NSObject 2)NSNumber 3)NSValue
 *  @param object               实体类对象
 *  @param propertyMapper       PropertyMapper对象，属性与jsonkey的映射关系
 *
 *  该函数大体的逻辑为如下:
 *  - (1) 外层: 首先根据属性Ivar的类型分类
 *  - (2) 内层: 再根据传入的json item value的类型
 *
 *  if ((mapper->_typeEncoding & XZHTypeEncodingDataTypeMask) == XZHTypeEncodingFoundationObject){
         // Foundation Object
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
         // int、float、double、long ... 数值需要预先使用NSNumber进行打包，然后传入进行设值
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
         // c 指针类型/CoreFoundation实例，数值需要预先使用NSValue进行打包，然后传入进行设值
         - int *p，char *s，int arr[5],
         - Class、Method、Property、SEL ... 等CoreFoundation结构体实例
         - 自定义c结构体实例、结构体数组 ....
     }
 */
static void XZHSetFoundationObjectToProperty(__unsafe_unretained id jsonItemValue, __unsafe_unretained id model, __unsafe_unretained XZHPropertyMapper *propertyMapper);

/**
 *  将传入的Foundation对象首先检查是否可以json化，如果可以直接返回，如果不可以进行处理。
 *  最终处理成为合法能够json化的如下类型对象:
 *  - 基本类型:
 *      - (1) NSString
 *      - (2) NSNumber
 *  - 容器类型:
 *      - (1) NSDictionary
 *      - (2) NSArray
 *  - 自定义类型:
 *      - (1) NSDictionary
 *
 *  Apple在开发文档中规定对 objc对象 ====> json时，对objc对象需要满足的要求如下:
 *  (https://developer.apple.com/reference/foundation/jsonserialization)
 *  - (1) The top level object is an NSArray or NSDictionary.
 *  - (2) All objects are instances of NSString, NSNumber, NSArray, NSDictionary, NSNull.
 *  - (3) All dictionary keys are instances of NSString.
 *  - (4) Numbers are not NaN or infinity.
 *
 *  线程安全:
 *  - On iOS 7 and later and macOS 10.9 and laterNSJSONSerialization is thread safe.
 *
 *  根据Apple对json化的objc对象的要求，大致对objc对象json化处理时的规则:
 *  - (1) 首先最终得到的objc对象类型，只能是NSDictionary、NSArray
 *  - (2) 顶层对象是NSArray时，内部的所有子对象类型只能是:
 *      - NSString、NSNumber、NSArray、NSDictionary、NSNull（这个直接过滤掉）
 *  - (3) 顶层对象是NSDictionary时，内部的所有子对象类型只能是:
 *      - dic.key >>> 只能是NSSting
 *      - dic.value >>> NSString、NSNumber、NSArray、NSDictionary、NSNull（这个直接过滤掉）
 *  - (4) 那么json化处理时，数据的分类:
 *      - 基本类型: NSString、NSNumer >>>> 直接可以添加到最终的容器json对象中
 *      - 容器类型: NSArray、NSDictionary >>>> 需要再次进行json化处理，才能添加到最终的容器json对象中
 *      - 自定义NSObject类型: >>>> 进行json化处理成为NSDictionary对象，再添加到最终的容器json对象中
 *  - (5) 对于容器内子对象的递归json化处理情况:
 *      - 容器类型: NSArray、NSDictionary
 *      - 自定义NSObject类型:
 */
static id XZHConvertModelToAbleJSONSerialization(id object);

/**
 *  遍历JSON Dictionary 进行解析
 *
 *  @param key           dictionary.key
 *  @param value         dictionary.value
 *  @param context       XZHModelContext
 */
static void XZHJsonToModelApplierFunctionWithJSONDict(const void *jsonKey, const void *jsonItemValue, void *context);

/**
 *  遍历XZHClassMapper 进行解析
 *  - (1) _keyPathPropertyMappers
 *  - (2) _keyArrayPropertyMappers
 *  - (3) _allPropertyMappers
 *
 *  @param value        XZHPeropertyMapper
 *  @param context      XZHModelContext
 */
static void XZHJsonToModelApplierFunctionWithPropertyMappers(const void *value, void *context);

/**
 *  负责记录XZHPropertyModel属性与jsonkey之间如何映射的:
 *      - (1) XZHPropertyModel >>>> objc_property_t
 *      - (2) jsonKey >>>> 1)simple 2)keyPath 3)keyArray
 *
 *  PropertyMapper主要完成的事情:
 *
 *      - (1) 记录property映射哪一种类型的json key
 *          - 简单的单个key
 *              - {name : name}
 *              - {name : user_name}
 *          - 带有 `.` 的路径key
 *              - {name : user.name}
 *          - 同时映射多个key，且子key可以是单个key，也可以是路径key
 *              - {name : [name1, name2, name3, user.name]}
 *
 *      - (2) 记录property如何映射json key
 *          - 1 json key : 1 property
 *          - 1 json key : n property
 *          - n json key : 1 property
 *              - {name1 : name}, {name2 : name}, {name3 : name}
 *              - 这种情况是单链表的结构将所有映射同一个jsonkey的PropertyMapper对象全部串联起来
 *          - n json key : n property （这种不应该不存在的错误情况）
 */
@interface XZHPropertyMapper : NSObject {
    @package
    
    /**
     *  描述的objc_property实例
     */
    XZHPropertyModel            *_property;
    
    /**
     *  属性所属的[NSObject类 class]
     */
    Class                       _generacCls;
    
    /**
     *  属性变量Ivar的类型Class
     */
    Class                       _ivarClass;
    
    /**
     *  容器属性变量为容器类型（Array、Dic、Set）时，内部子对象的类型Class
     */
    Class                       _containerCls;
    
    /**
     *  Ivar的类型编码
     */
    XZHTypeEncoding             _typeEncoding;
    
    /**
     *  Ivar的类型编码字符串
     */
    NSString                    *_typeEncodingString;
    
    /**
     *  Ivar的Foundation类型
     */
    XZHFoundationType           _foundationType;
    
    BOOL                        _isFoundationObject;
    
    /**
     *  Ivar是否是c基本数值类型(int、float、double、long ....)
     */
    BOOL                        _isCNumber;
    
    /**
     *  Ivar是否是NSNumber基本数值类型
     */
    BOOL                        _isNSNumber;
    
    /**
     *  是否能够使用setter/getter
     */
    BOOL                        _isGetterAccess;
    BOOL                        _isSetterAccess;
    
    /**
     *  属性映射简单的json key
        @{ @"user":@"user" }
     */
    NSString                    *_mappedToSimpleKey;
    
    /**
        属性映射一个 json key path 路径
        {@"name":@"user.name"}
     */
    NSString                     *_mappedToKeyPath;
    
    /**
     *  一个属性 映射 多个json key
         @{
             //属性名 : json key
             @"id":@"userId",
             @"id":@"User.id",
             @"id":@"UID",
         }
     */
    NSArray                     *_mappedToKeyArray;
    
    XZHPropertyMappedToJsonKeyType _mappedType;
    
    /**
     *  多个实体类属性 映射 同一个json key
         @{
             //属性名 : json key
             @"id"       :@"uid",
             @"userId"   :@"uid",
             @"ID"       :@"uid",
         }
         
         id->userId->ID 链起来
     */
    XZHPropertyMapper         *_next;
}
@end
@implementation XZHPropertyMapper

/**
 *  创建描述Property与jsonKey之间映射规则的PropertyMapper对象:
 *
 *  @param property         objc_property对应的 XZHPropertyModel对象
 *  @param containerCls     objc_property如果是Array/Dic/Set容器类型时，内部子对象的containerCls
 *  @param generacCls       objc_property所属NSObject类的generacCls
 */
- (instancetype)initWithPropertyModel:(XZHPropertyModel *)property containerCls:(Class)containerCls generacCls:(Class)generacCls{
    if (self = [super init]) {
        _property = property;
        _ivarClass = property.cls;
        _generacCls = generacCls;
        _typeEncoding = property.typeEncoding;
        _typeEncodingString = property.encodingString;
        _foundationType = property.foundationType;
        _isCNumber = property.isCNumber;
        _isNSNumber = (XZHFoundationTypeNSNumber == _foundationType) || (XZHFoundationTypeNSDecimalNumber == _foundationType);
        _containerCls = containerCls;
        _isSetterAccess = property.isSetterAccess;
        _isGetterAccess = property.isGetterAccess;
    }
    return self;
}

@end

@interface XZHClassMapper : NSObject {
    @package
    XZHClassModel                      *_classModel;
    
    /**
     *  1、记录所有的属性与jsonkey的映射存储
     *  @{
     *      jsonkey : PropertyMapper对象，
     *  }
     *
     *  2. 大致有如下这些映射关系:
     *  {name : name}
     *  {name : user_name}
     *  {name : user.name}
     *  {name1 : name}, {name2 : name}, {name3 : name}
     *  {name : [name1, name2, name3, user.name]}
     *
     *  2. 映射关系为<n属性:1jsonkey>时:
     *      - 只保存最后一次解析的PropertyMapper对象
     *      - 使用_next属性依次将映射相同jsonkey的PropertyMapper对象串联起来
     *      - PropertyMapper1->PropertyMapper2->PropertyMapper3->nil
     */
    CFMutableDictionaryRef              _jsonKeyPropertyMapperDic;
    
    /**
     *  保存如果属性变量是NSArray/NSDictionary/NSSet等容器类型时，其内部子对象的class
     *  @{
     *      jsonkey : objc_class,
     *  }
     */
    CFMutableDictionaryRef              _objectInArrayClassDic;
    
    /**
     *  记录属性可能映射的jsonkey的类型:
     *  - (1) simple json key
     *  - (2) json keyPath
     *  - (3) json keyArray
     */
    CFMutableArrayRef                  _allPropertyMappers;
    CFMutableArrayRef                  _keyPathPropertyMappers;
    CFMutableArrayRef                  _keyArrayPropertyMappers;
    
    CFIndex                             _totalMappedCount;          //>>> 记录总的属于与jsonkey映射个数，注意:映射相同的jsonkey的次数只有一次
    CFIndex                             _keyPathMappedCount;
    CFIndex                             _keyArrayMappedCount;
}

@end
@implementation XZHClassMapper

- (void)dealloc {
    _classModel = nil;
    CFRelease(_jsonKeyPropertyMapperDic);
    CFRelease(_objectInArrayClassDic);
    CFRelease(_allPropertyMappers);
    CFRelease(_keyPathPropertyMappers);
    CFRelease(_keyArrayPropertyMappers);
}

/**
 *  解析当前NSObject类的objc_class实例
 *  - (1) 给所有的objc_property实例生成对应的ProeprtyMapper对象
 *  - (2) 设置objc_property实例配置的映射json key类型到ProeprtyMapper对象
 *
 *  ClassMapper 的结构:
 *      - ClassModel
 *          - Ivar List Model
 *          - Property List Model
 *          - Method List Model
 *      - jsonMappingDic
 *          @{
 *              json key 1 : PropertyMapper 1,
 *              json key 2 : PropertyMapper 2,
 *          }
 *
 */
+ (instancetype)classMapperWithClass:(Class)cls {
    if (Nil == cls) return nil;
    static CFMutableDictionaryRef _cache;
    static dispatch_semaphore_t _semephore;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _cache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        _semephore = dispatch_semaphore_create(1);
    });
    
    const void *clsName =  (__bridge const void *)(NSStringFromClass(cls));
    dispatch_semaphore_wait(_semephore, DISPATCH_TIME_FOREVER);
    XZHClassMapper *clsMapper = CFDictionaryGetValue(_cache, clsName);
    dispatch_semaphore_signal(_semephore);
    
    if (!clsMapper) {
        /**
         *  下面拿到的XZHClassModel对象，已经被内部单例缓存dic持有，所以此处就不需要进行持有，保持弱引用即可。后面这样的地方都使用__unsafe_unretained来修饰指针。
         *  尝试使用__weak修饰，发现耗时比较多的，因为__weak指针在使用的时候，会被注册到AutoReleasePool中。
         *  __unsafe_unretained类似__weak，不会retain对象，但是不会像__weak修饰的对象会自动注册到AutoReleasePool，所以比__weak运行速度快。
         */
        __unsafe_unretained XZHClassModel *clsModel = [XZHClassModel instanceWithClass:cls];
        
        clsMapper = [[XZHClassMapper alloc] init];
        clsMapper->_classModel = clsModel;
        
        __block CFIndex totalMappedCount = 0;
        __block CFIndex keyPathMappedCount = 0;
        __block CFIndex keyArrayMappedCount = 0;
        
        CFMutableDictionaryRef jsonKeyPropertyMapperDic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFMutableDictionaryRef objectInArrayClassDic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        
        CFMutableArrayRef allPropertyMappers = CFArrayCreateMutable(CFAllocatorGetDefault(), 32, &kCFTypeArrayCallBacks);
        CFMutableArrayRef keyPathPropertyMappers = CFArrayCreateMutable(CFAllocatorGetDefault(), 32, &kCFTypeArrayCallBacks);
        CFMutableArrayRef keyArrayPropertyMappers = CFArrayCreateMutable(CFAllocatorGetDefault(), 32, &kCFTypeArrayCallBacks);
        
        NSMutableArray *allPropertyNames = [[NSMutableArray alloc] initWithArray:[clsModel.propertyMap allKeys]];
        
        /**
         *  添加父类的所有property属性，
         *  但是忽略对 NSObject/NSProxy 这两个跟类的解析，
         *  NSObject/NSProxy.superclass == NULL 结束循环条件
         */
        __unsafe_unretained XZHClassModel *clsTmpModel = clsModel;
        while (clsTmpModel && (clsTmpModel.superClassModel != nil)) {
            for (__unsafe_unretained XZHPropertyModel *propertyModel in clsTmpModel.propertyMap.allValues) {
                if (!propertyModel.name) {continue;}
                if (!propertyModel.setter || !propertyModel.getter) {continue;}
                [allPropertyNames addObject:propertyModel.name];
            }
            clsTmpModel = clsTmpModel.superClassModel;
        }
        
        /**
         *  移除忽略映射的属性
         */
        if (XZHClassRespondsToSelector(cls, @selector(xzh_ignoreMappingJSONKeys))) {
            NSArray *ignoreJSONKeys = [(id<XZHJSONModelMappingRules>)cls xzh_ignoreMappingJSONKeys];
            if (ignoreJSONKeys) {[allPropertyNames removeObjectsInArray:ignoreJSONKeys];}
        }
        
        /**
         *  如果属性的类型是Array、Set、Dictionary容器时，记录其数组内部元素Class
         */
        if (XZHClassRespondsToSelector(cls, @selector(xzh_classInArray))) {
            NSDictionary *classInArrayDic = [(id<XZHJSONModelMappingRules>)cls xzh_classInArray];
            [classInArrayDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull propertyName, id  _Nonnull class, BOOL * _Nonnull stop) {
                if ([propertyName isKindOfClass:[NSString class]]) {
                    if ([class isKindOfClass:[NSString class]]) {
                        Class cls = NSClassFromString(class);
                        if (cls) {CFDictionarySetValue(objectInArrayClassDic, (__bridge const void *)(propertyName), (__bridge const void *)(cls));}
                    } else {
                        if (!class_isMetaClass(cls)) {
                            CFDictionarySetValue(objectInArrayClassDic, (__bridge const void *)(propertyName), (__bridge const void *)(class));
                        }
                    }
                }
            }];
        }
        
        /**
         *  建立自定义属性映射jsonkey
         *  <jsonKey : PropertyMapper>
         */
        if (XZHClassRespondsToSelector(cls, @selector(xzh_customerMappings))) {
            NSDictionary *customerJSONKeyMapping = [(id<XZHJSONModelMappingRules>)cls xzh_customerMappings];
            [customerJSONKeyMapping enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull propertyName, id  _Nonnull jsonKey, BOOL * _Nonnull stop) {
                if (![propertyName isKindOfClass:[NSString class]]) {return ;}
                [allPropertyNames removeObject:propertyName];
                
                __unsafe_unretained XZHPropertyModel *propertyModel = [clsModel.propertyMap objectForKey:propertyName];
                if (!propertyModel) {return ;}
                
                XZHPropertyMapper *newMapper = [[XZHPropertyMapper alloc] initWithPropertyModel:propertyModel containerCls:CFDictionaryGetValue(objectInArrayClassDic, (__bridge const void *)(propertyName)) generacCls:cls];
                if (!newMapper) {return ;}
                
                XZHPropertyMappedToJsonKeyType type = 0;
                if ([jsonKey isKindOfClass:[NSString class]]) {
                    /**
                     *  情况一、{属性 : user_name}
                     *  情况二、{属性 : user.name}
                     *  情况三、{属性1 : name}, {属性2 : name}, {属性3 : name}
                     */
                    if ([jsonKey rangeOfString:@"."].location != NSNotFound) {
                        newMapper->_mappedToKeyPath = jsonKey;
                        type = XZHPropertyMappedToJsonKeyTypeKeyPath;
                    } else {
                        newMapper->_mappedToSimpleKey = jsonKey;
                        type = XZHPropertyMappedToJsonKeyTypeSimple;
                    }
                } else if ([jsonKey isKindOfClass:[NSArray class]]) {
                    /**
                     *  情况四、{属性 : [name1, name2, name3, user.name]}
                     */
                    newMapper->_mappedToKeyArray = jsonKey;
                    type = XZHPropertyMappedToJsonKeyTypeKeyArray;
                }
                newMapper->_mappedType = type;
                
                /**
                 *  处理多个不同属性，映射同一个jsonkey
                 */
                __unsafe_unretained XZHPropertyMapper *preMapper = CFDictionaryGetValue(jsonKeyPropertyMapperDic, (__bridge const void *)(jsonKey));
                if (preMapper) {
                    newMapper->_next = preMapper;
                } else {
                    totalMappedCount++;
                    CFArrayAppendValue(allPropertyMappers, (__bridge const void *)(newMapper));
                    switch (type) {
                        case XZHPropertyMappedToJsonKeyTypeKeyPath: {
                            CFArrayAppendValue(keyPathPropertyMappers, (__bridge const void *)(newMapper));
                            keyPathMappedCount++;
                            break;
                        }
                        case XZHPropertyMappedToJsonKeyTypeKeyArray: {
                            CFArrayAppendValue(keyArrayPropertyMappers, (__bridge const void *)(newMapper));
                            keyArrayMappedCount++;
                            break;
                        }
                        default:
                            break;
                    }
                }
                CFDictionarySetValue(jsonKeyPropertyMapperDic, (__bridge const void *)(jsonKey), (__bridge const void *)(newMapper));
            }];
        }
        
        /**
         *  没有自定义jsonkey与属性映射，按照simple jsonkey 映射
         *  格式: <jsonKey:PropertyMapper>
         */
        [allPropertyNames enumerateObjectsUsingBlock:^(NSString * _Nonnull propertyName, NSUInteger idx, BOOL * _Nonnull stop) {
            __unsafe_unretained XZHPropertyModel *propertyModel = [clsModel.propertyMap objectForKey:propertyName];
            if (!propertyModel) {return ;}
            
            XZHPropertyMapper *newMapper = [[XZHPropertyMapper alloc] initWithPropertyModel:propertyModel containerCls:CFDictionaryGetValue(objectInArrayClassDic, (__bridge const void *)(propertyName)) generacCls:cls];
            newMapper->_mappedToSimpleKey = propertyName;
            newMapper->_mappedType = XZHPropertyMappedToJsonKeyTypeSimple;
            
            __unsafe_unretained XZHPropertyMapper *preMapper = CFDictionaryGetValue(jsonKeyPropertyMapperDic, (__bridge const void *)(propertyName));
            if (preMapper) {
                newMapper->_next = preMapper;
            } else {
                totalMappedCount++;
                CFArrayAppendValue(allPropertyMappers, (__bridge const void *)(newMapper));
            }
            CFDictionarySetValue(jsonKeyPropertyMapperDic, (__bridge const void *)(propertyName), (__bridge const void *)(newMapper));
        }];
        
        clsMapper->_jsonKeyPropertyMapperDic = jsonKeyPropertyMapperDic;
        clsMapper->_objectInArrayClassDic = objectInArrayClassDic;
        clsMapper->_allPropertyMappers = allPropertyMappers;
        clsMapper->_keyPathPropertyMappers = keyPathPropertyMappers;
        clsMapper->_keyArrayPropertyMappers = keyArrayPropertyMappers;
        clsMapper->_totalMappedCount = totalMappedCount;
        clsMapper->_keyPathMappedCount = keyPathMappedCount;
        clsMapper->_keyArrayMappedCount = keyArrayMappedCount;
        
        dispatch_semaphore_wait(_semephore, DISPATCH_TIME_FOREVER);
        CFDictionarySetValue(_cache, clsName, (__bridge const void *)(clsMapper));
        dispatch_semaphore_signal(_semephore);
    }
    
    return clsMapper;
}

@end

@implementation NSObject (XZHJSONModelMapping)

#pragma mark - JSON To Object

+ (instancetype)xzh_modelFromObject:(id)obj {
    if (!obj || (id)kCFNull == obj) {return nil;}
    if ([obj isKindOfClass:[NSDictionary class]]) {
        return [self xzh_modelFromJSONDictionary:(NSDictionary*)obj];
    } else if ([obj isKindOfClass:[NSString class]]) {
        return [self xzh_modelFromJSONString:(NSString*)obj];
    } else if ([obj isKindOfClass:[NSData class]]) {
        return [self xzh_modelFromJSONData:(NSData*)obj];
    } else if ([obj isKindOfClass:[NSArray class]]) {
        return [self xzh_modelFromJSONArray:obj];
    }
    return nil;
}

// NSString >>> NSData >>> NSDictionary
+ (instancetype)xzh_modelFromJSONString:(NSString *)jsonString {
    if (!jsonString || ((id)kCFNull == jsonString) || (jsonString.length < 1)) {return nil;}
    NSData *jsonData = [(NSString *)jsonString dataUsingEncoding: NSUTF8StringEncoding];
    return [self xzh_modelFromJSONData:jsonData];
}

// NSData >>> NSDictionary
+ (instancetype)xzh_modelFromJSONData:(NSData *)jsonData {
    if (!jsonData || (id)kCFNull == jsonData) {return nil;}
    NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:NULL];
    if (![jsonDic isKindOfClass:[NSDictionary class]]) {return nil;}
    return [self xzh_modelFromJSONDictionary:jsonDic];
}

+ (instancetype)xzh_modelFromJSONDictionary:(NSDictionary *)jsonDic {
    if (![jsonDic isKindOfClass:[NSDictionary class]]) {return nil;}
    
    XZHClassMapper *clsMapper = [XZHClassMapper classMapperWithClass:[self class]];
    if (!clsMapper || 0 == clsMapper->_totalMappedCount) {return nil;}

    id model = [[self alloc] init];
    if (!model) {return nil;}
    
    XZHJsonToModelContext ctx = {0};
    ctx.model       = (__bridge void*)(model);
    ctx.jsonDic     = (__bridge void *)(jsonDic);
    ctx.classMapper = (__bridge void *)(clsMapper);
    
    if (jsonDic.count <= clsMapper->_totalMappedCount) {
        /**
         *  此种情况下，实体类中的一部分属性，可能不存在对应的jsonvalue
         *  - (1) 首先遍历jsondic.key对应的PropertyMapper来解析所有的 json item value，来完成大部分的属性值设置
         *  - (2) 再按照 映射 jsonkeyPath PropertyMapper来解析对应的 json item value，辅助部分属性值设置
         *  - (3) 再按照 映射 jsonKeyArray PropertyMapper来解析对应的 json item value，辅助部分属性值设置
         */
        CFDictionaryApplyFunction((CFDictionaryRef)jsonDic, XZHJsonToModelApplierFunctionWithJSONDict, &ctx);
        if(clsMapper->_keyPathMappedCount > 0) {CFArrayApplyFunction(clsMapper->_keyPathPropertyMappers, CFRangeMake(0, clsMapper->_keyPathMappedCount), XZHJsonToModelApplierFunctionWithPropertyMappers, &ctx);}
        if(clsMapper->_keyArrayMappedCount > 0) {CFArrayApplyFunction(clsMapper->_keyArrayPropertyMappers, CFRangeMake(0, clsMapper->_keyArrayMappedCount), XZHJsonToModelApplierFunctionWithPropertyMappers, &ctx);}
    } else {
        /**
         *  此种情况下，可能实体类全部属性都存在对应的jsonvalue，所以直接遍历所有的classMapper's property来解析json
         */
        CFArrayApplyFunction(clsMapper->_allPropertyMappers, CFRangeMake(0, clsMapper->_totalMappedCount), XZHJsonToModelApplierFunctionWithPropertyMappers, &ctx);
    }
    return model;
}

+ (instancetype)xzh_modelFromJSONArray:(NSArray *)jsonArray {
    if ([jsonArray isKindOfClass:[NSArray class]]) {
        NSMutableArray *modelArray = [[NSMutableArray alloc] initWithCapacity:jsonArray.count];
        id model = nil;
        id json = nil;
        for (id jsonItem in jsonArray) {
            if ([jsonItem isKindOfClass:[NSString class]]) {
                json = [(NSString *)jsonItem dataUsingEncoding: NSUTF8StringEncoding];
            }
            if ([jsonItem isKindOfClass:[NSData class]]) {
                json = [NSJSONSerialization JSONObjectWithData:jsonItem options:kNilOptions error:NULL];
            }
            if ([jsonItem isKindOfClass:[NSDictionary class]]) {
                model = [self xzh_modelFromJSONDictionary:jsonItem];
            }
        }
        if (model) {[modelArray addObject:model];}
    }
    return nil;
}

#pragma mark - Object To JSON

- (instancetype)xzh_modelToJSONObject {
    id json = XZHConvertModelToAbleJSONSerialization(self);
    if ([json isKindOfClass:[NSDictionary class]]) {return json;}
    if ([json isKindOfClass:[NSArray class]]) {return json;}
    return nil;
}

- (instancetype)xzh_modelToJSONData {
    id json = [self xzh_modelToJSONObject];
    if (!json) {return nil;}
    return [NSJSONSerialization dataWithJSONObject:json options:0 error:NULL];
}

- (instancetype)xzh_modelToJSONString {
    id data = [self xzh_modelToJSONData];
    if (!data) {return nil;}
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end

#pragma mark - c func

static xzh_force_inline NSDictionary* XZHJSONStringToDic(__unsafe_unretained NSString *jsonString) {
//    jsonString = XZHConvertNullNSString(jsonString);
    NSData* data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (error) {
        return nil;
    } else {
        return result;
    }
}

static xzh_force_inline NSNumber* XZHNumberWithValue(__unsafe_unretained id value) {
    static NSCharacterSet *dot = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dot = [NSCharacterSet characterSetWithRange:NSMakeRange('.', 1)];
    });
    
    if ([value isKindOfClass:[NSNumber class]]) {
        return (NSNumber*)value;
    } else if ([value isKindOfClass:[NSString class]]) {
        static NSDictionary *defaultDic = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            defaultDic = @{
                           @"true" : @(1),
                           @"TRUE" : @(1),
                           @"True" : @(1),
                           @"false" : @(0),
                           @"FALSE" : @(0),
                           @"False" : @(0),
                           @"YES" : @(1),
                           @"yes" : @(1),
                           @"Yes" : @(1),
                           @"NO" : @(0),
                           @"no" : @(0),
                           @"No" : @(0),
                           };
        });
        id tmp = [defaultDic objectForKey:value];
        if (tmp) {return tmp;}
        if ([(NSString *)value rangeOfCharacterFromSet:dot].location != NSNotFound) {
            // 带小数的
            const char *cstring = ((NSString *)value).UTF8String;
            if (!cstring) return @(0);
            double num = atof(cstring);
            if (isnan(num) || isinf(num)) return @(0);//NaN、Inf默认返回0
            return @(num);
        } else {
            // 整数
            return @([value integerValue]);
        }
    } else if (value == (id)kCFNull) {
        return nil;
    }
    return nil;
}

static xzh_force_inline NSNumber* XZHNumberWithModelProperty(__unsafe_unretained id object, __unsafe_unretained XZHPropertyMapper *mapper) {
    if (!object || !mapper) return nil;
    SEL getter = mapper->_property.getter;
    if (!getter) return nil;
    
    if (mapper->_isCNumber) {
        switch (mapper->_typeEncoding & XZHTypeEncodingDataTypeMask) {
            case XZHTypeEncodingChar: {//char、int8_t
                char num = ((char (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                return [NSNumber numberWithChar:num];
            }
                break;
            case XZHTypeEncodingUnsignedChar: {//unsigned char、uint8_t
                unsigned char num = ((unsigned char (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                return [NSNumber numberWithUnsignedChar:num];
            }
                break;
            case XZHTypeEncodingBOOL: {
                BOOL num = ((BOOL (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                return [NSNumber numberWithBool:num];
            }
                break;
            case XZHTypeEncodingShort: {//short、int16_t、
                short num = ((short (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                return [NSNumber numberWithShort:num];
            }
                break;
            case XZHTypeEncodingUnsignedShort: {//unsigned short、uint16_t、
                unsigned short num = ((unsigned short (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                return [NSNumber numberWithUnsignedShort:num];
            }
                break;
            case XZHTypeEncodingInt: {//int、int32_t、
                int num = ((int (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                return [NSNumber numberWithInt:num];
            }
                break;
            case XZHTypeEncodingUnsignedInt: {//unsigned int、uint32_t
                unsigned int num = ((unsigned int (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                return [NSNumber numberWithUnsignedInt:num];
            }
                break;
            case XZHTypeEncodingFloat: {
                float num = ((float (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                return [NSNumber numberWithFloat:num];
            }
                break;
            case XZHTypeEncodingLong32: {
                long num = ((long (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                if (isnan(num) || isinf(num)) return nil;
                return [NSNumber numberWithLong:num];
            }
                break;
            case XZHTypeEncodingLongLong: {
                long long num = ((long long (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                if (isnan(num) || isinf(num)) return nil;
                return [NSNumber numberWithLongLong:num];
            }
                break;
            case XZHTypeEncodingLongDouble: {
//                long double num = ((long double (*)(id, SEL))(void *) objc_msgSend)(object, getter); 使用double类型接收
                double num = ((long double (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                if (isnan(num) || isinf(num)) return nil;
                return @(num);
            }
                break;
            case XZHTypeEncodingUnsignedLong: {
                unsigned long num = ((unsigned long (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                if (isnan(num) || isinf(num)) return nil;
                return [NSNumber numberWithUnsignedLong:num];
            }
                break;
            case XZHTypeEncodingUnsignedLongLong: {
                unsigned long long num = ((unsigned long long (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                if (isnan(num) || isinf(num)) return nil;
                return [NSNumber numberWithUnsignedLongLong:num];
            }
                break;
            case XZHTypeEncodingDouble: {
                double num = ((double (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                if (isnan(num) || isinf(num)) return nil;
                return [NSNumber numberWithDouble:num];
            }
                break;
        }
    } else if (mapper->_foundationType == XZHFoundationTypeNSNumber || mapper->_foundationType == XZHFoundationTypeNSDecimalNumber) {
        return ((NSNumber* (*)(id, SEL))(void *) objc_msgSend)(object, getter);
    } else if (mapper->_foundationType == XZHFoundationTypeNSString || mapper->_foundationType == XZHFoundationTypeNSMutableString) {
        NSString *value = ((NSString* (*)(id, SEL))(void *) objc_msgSend)(object, getter);
        return XZHNumberWithValue(value);
    }
    return nil;
}

static xzh_force_inline id XZHGetValueFromDictionaryWithMultiJSONKeyArray(__unsafe_unretained NSDictionary *dic, __unsafe_unretained NSArray *keyArray) {
    if (!keyArray) {return nil;}
    if (![keyArray isKindOfClass:[NSArray class]]) {return nil;}
    id value = nil;
    for (id itemKey in keyArray) {
        if ([itemKey isKindOfClass:[NSString class]]) {
            //simple key
            if ([itemKey rangeOfString:@"."].location != NSNotFound) {
                @try {
                    value = [dic valueForKeyPath:itemKey];
                }
                @catch (NSException *exception) {
                    value = nil;
                }
            } else {
                value = [dic valueForKey:itemKey];
            }
        } else if ([itemKey isKindOfClass:[NSArray class]]) {
            //keypath没必要解析成数组形式，KVC可以valueForKeyPath:
        }
        
        if (value) {return value;}
    }
    return nil;
}


static xzh_force_inline id XZHGetValueFromDictionaryWithKeyPath(__unsafe_unretained NSDictionary *dic, __unsafe_unretained NSString *keyPath) {
    if (!dic || ![dic isKindOfClass:[NSDictionary class]] || !keyPath || ![keyPath isKindOfClass:[NSString class]]) return nil;
    id value = nil;
    @try {
        value = [dic valueForKeyPath:keyPath];
    } @catch (NSException *exception) {
        value = nil;
    }
    return value;
}

static void XZHSetFoundationObjectToProperty(__unsafe_unretained id jsonItemValue, __unsafe_unretained id model, __unsafe_unretained XZHPropertyMapper *propertyMapper) {
    if (!jsonItemValue || !model || !propertyMapper) {return;}
    if (!propertyMapper->_isSetterAccess) {return;}
    SEL setter = propertyMapper->_property.setter;
    
    if (XZHFoundationTypeNone != propertyMapper->_foundationType){
        switch (propertyMapper->_foundationType) {//start switch mapper->_foundationType
            case XZHFoundationTypeNSString:
            case XZHFoundationTypeNSMutableString: {
                if ((id)kCFNull == jsonItemValue) {return;}
                if ([jsonItemValue isKindOfClass:[NSString class]]) {
                    ((void (*)(id, SEL, NSString*))(void *) objc_msgSend)(model, setter, (propertyMapper->_foundationType == XZHFoundationTypeNSString) ? jsonItemValue : [jsonItemValue mutableCopy]);
                } else if ([jsonItemValue isKindOfClass:[NSDate class]]) {
                    if (XZHClassRespondsToSelector(propertyMapper->_generacCls, @selector(xzh_dateFormat))) {
                        NSString *dateFormat = [propertyMapper->_generacCls xzh_dateFormat];
                        if (dateFormat) {
                            NSDateFormatter *fomatter = XZHDateFormatter(dateFormat);
                            NSString *dateStr = [fomatter stringFromDate:jsonItemValue];
                            if (dateStr) {
                                ((void (*)(id, SEL, NSString*))(void *) objc_msgSend)(model, setter, (propertyMapper->_foundationType == XZHFoundationTypeNSString) ? dateStr : [dateStr mutableCopy]);
                            }
                        }
                    }
                } else if ([jsonItemValue isKindOfClass:[NSNumber class]]) {
                    NSString *valueString = [(NSNumber*)jsonItemValue stringValue];
                    if (valueString) {
                        ((void (*)(id, SEL, NSString*))(void *) objc_msgSend)(model, setter, (propertyMapper->_foundationType == XZHFoundationTypeNSString) ? valueString : [valueString mutableCopy]);
                    }
                } else if ([jsonItemValue isKindOfClass:[NSURL class]]) {
                    NSString *valueString = [(NSURL*)jsonItemValue absoluteString];
                    if (valueString) {
                        ((void (*)(id, SEL, NSString*))(void *) objc_msgSend)(model, setter, (propertyMapper->_foundationType == XZHFoundationTypeNSString) ? valueString : [valueString mutableCopy]);
                    }
                } else if ([jsonItemValue isKindOfClass:[NSData class]]) {
                    NSString *valueString = [[NSString alloc] initWithData:jsonItemValue encoding:NSUTF8StringEncoding];
                    if (valueString) {
                        ((void (*)(id, SEL, NSString*))(void *) objc_msgSend)(model, setter, (propertyMapper->_foundationType == XZHFoundationTypeNSString) ? valueString : [valueString mutableCopy]);
                    }
                }
            }
                break;
            case XZHFoundationTypeNSNumber:
            case XZHFoundationTypeNSDecimalNumber: {
                // jsonValue.class ==> 1)NSNumber 2)NSString（数值字符串/日期字符串） 3)NSDate
                if ([jsonItemValue isKindOfClass:[NSNumber class]]) {
                    ((void (*)(id, SEL, NSNumber*))(void *) objc_msgSend)(model, setter, jsonItemValue);
                } else if ([jsonItemValue isKindOfClass:[NSString class]]) {
//                    jsonItemValue = XZHConvertNullNSString(jsonItemValue);
                    if (!jsonItemValue)return;
                    NSDate *date  = nil;
                    if (XZHClassRespondsToSelector(propertyMapper->_generacCls, @selector(xzh_dateFormat))) {
                        NSString *dateFormat = [propertyMapper->_generacCls xzh_dateFormat];
                        if (dateFormat) {
                            NSDateFormatter *fomatter = XZHDateFormatter(dateFormat);
                            date = [fomatter dateFromString:jsonItemValue];
                        }
                    }
                    NSNumber *number = nil;
                    if (date) {
                        number = [NSNumber numberWithDouble:[date timeIntervalSinceReferenceDate]];
                    } else {
                        number = XZHNumberWithValue(jsonItemValue);
                    }
                    if (number) {
                        ((void (*)(id, SEL, NSNumber*))(void *) objc_msgSend)(model, setter, number);
                    }
                } else if ([jsonItemValue isKindOfClass:[NSDate class]]) {
                    NSNumber *number = [NSNumber numberWithDouble:[(NSDate*)jsonItemValue timeIntervalSinceReferenceDate]];
                    if (number) {
                        ((void (*)(id, SEL, NSNumber*))(void *) objc_msgSend)(model, setter, number);
                    }
                } else if ([jsonItemValue isKindOfClass:[NSValue class]]) {
                    ((void (*)(id, SEL, NSNumber*))(void *) objc_msgSend)(model, setter, jsonItemValue);
                }
            }
                break;
            case XZHFoundationTypeNSURL: {
                // jsonValue.class ==> 1)NSURL 2)NSString
                if ([jsonItemValue isKindOfClass:[NSURL class]]) {
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)(model, setter, jsonItemValue);
                } else if ([jsonItemValue isKindOfClass:[NSString class]]) {
//                    jsonItemValue = XZHConvertNullNSString(jsonItemValue);
                    if (jsonItemValue) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)(model, setter, [[NSURL alloc] initWithString:jsonItemValue]);
                    }
                }
            }
                break;
            case XZHFoundationTypeNSArray :
            case XZHFoundationTypeNSMutableArray: {
                // jsonValue.class ==> 1) NSArray 2)NSMutableArray 3) NSSet
                NSArray *valueArray = nil;
                if ([jsonItemValue isKindOfClass:[NSArray class]]) {valueArray = jsonItemValue;}
                else if ([jsonItemValue isKindOfClass:[NSSet class]]) {valueArray = [jsonItemValue allObjects];}
                if (!valueArray) {return;}
                
                if (propertyMapper->_containerCls) {
                    /**
                     *  解析array中每一个元素为实体对象，然后将解析的对象设置到model
                     */
                    NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithCapacity:valueArray.count];
                    for (id item in valueArray) {
                        if ([item isKindOfClass:propertyMapper->_containerCls]) {
                            //jsonItemValue 已经是指定类型的对象
                            [mutableArray addObject:item];
                        } else if ([item isKindOfClass:[NSDictionary class]]) {
                            /**
                             *  item value 是 NSDictionary类型的对象，继续解析按照Class进行解析:
                             *  - (1)_containerCls指定的Class
                             *  - (2)实现`+[NSObject xzh_classForDictionary:]`方法返回的Class
                             */
                            Class cls = propertyMapper->_containerCls;
                            if (XZHClassRespondsToSelector(propertyMapper->_generacCls, @selector(xzh_classForDictionary:))) {
                                cls = [(id<XZHJSONModelMappingRules>)propertyMapper->_generacCls xzh_classForDictionary:item];
                            }
                            
                            id newItem = [cls xzh_modelFromJSONDictionary:item];
                            if (newItem)  {[mutableArray addObject:newItem];}
                        }
                    }
                    ((void (*)(id, SEL, NSArray*))(void *) objc_msgSend)(model, setter, (propertyMapper->_foundationType == XZHFoundationTypeNSArray) ? mutableArray.copy : mutableArray);
                } else {
                    ((void (*)(id, SEL, NSArray*))(void *) objc_msgSend)(model, setter, (propertyMapper->_foundationType == XZHFoundationTypeNSArray) ? valueArray : valueArray.mutableCopy);
                }
            }
                break;
            case XZHFoundationTypeNSDictionary:
            case XZHFoundationTypeNSMutableDictionary: {
                // jsonValue.class ==> 1)NSDictionary 2)NSMutableDictionary
                NSDictionary *valueDic = nil;
                if ([jsonItemValue isKindOfClass:[NSDictionary class]]) {valueDic = jsonItemValue;}
                else if ([jsonItemValue isKindOfClass:[NSString class]]) {valueDic = XZHJSONStringToDic(jsonItemValue);}// 支持JSON字符串
                if (!valueDic){return;}
                
                if (propertyMapper->_containerCls) {
                    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] initWithCapacity:valueDic.count];
                    [valueDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                        if ([obj isKindOfClass:propertyMapper->_containerCls]) {
                            [mutableDic setObject:obj forKey:key];
                        } else if ([obj isKindOfClass:[NSDictionary class]]){
                            Class cls = propertyMapper->_containerCls;
                            if (XZHClassRespondsToSelector(propertyMapper->_generacCls, @selector(xzh_classForDictionary:))) {
                                cls = [(id<XZHJSONModelMappingRules>)propertyMapper->_generacCls xzh_classForDictionary:obj];
                            }
                            id newItem = [propertyMapper->_containerCls xzh_modelFromJSONDictionary:obj];
                            if (newItem) {[mutableDic setObject:newItem forKey:key];}
                        }
                    }];
                    ((void (*)(id, SEL, NSDictionary*))(void *) objc_msgSend)(model, setter, (propertyMapper->_foundationType == XZHFoundationTypeNSDictionary) ? mutableDic.copy : mutableDic);
                } else {
                    ((void (*)(id, SEL, NSDictionary*))(void *) objc_msgSend)(model, setter, (propertyMapper->_foundationType == XZHFoundationTypeNSDictionary) ? valueDic : valueDic.mutableCopy);
                }
            }
                break;
            case XZHFoundationTypeNSSet:
            case XZHFoundationTypeNSMutableSet: {
                // jsonValue.class ==> 1) NSSet 2)NSMutableSet 3) NSArray
                NSSet *valueSet = nil;
                if ([jsonItemValue isKindOfClass:[NSSet class]]) {valueSet = jsonItemValue;}
                else if ([jsonItemValue isKindOfClass:[NSArray class]]) {valueSet = [NSSet setWithArray:jsonItemValue];}
                if (!valueSet) return;
                
                if (propertyMapper->_containerCls) {
                    NSMutableSet *mutableSet = [[NSMutableSet alloc] initWithCapacity:valueSet.count];
                    for (id item in valueSet) {
                        if ([item isKindOfClass:propertyMapper->_containerCls]) {
                            [mutableSet addObject:item];
                        } else if ([item isKindOfClass:[NSDictionary class]]) {
                            Class cls = propertyMapper->_containerCls;
                            if (XZHClassRespondsToSelector(propertyMapper->_generacCls, @selector(xzh_classForDictionary:))) {
                                cls = [(id<XZHJSONModelMappingRules>)propertyMapper->_generacCls xzh_classForDictionary:item];
                            }
                            
                            id newItem = [propertyMapper->_containerCls xzh_modelFromJSONDictionary:item];
                            if (newItem) {[mutableSet addObject:newItem];}
                        }
                        ((void (*)(id, SEL, NSSet*))(void *) objc_msgSend)(model, setter, (propertyMapper->_foundationType == XZHFoundationTypeNSDictionary) ? mutableSet.copy : mutableSet);
                    }
                } else {
                    ((void (*)(id, SEL, NSSet*))(void *) objc_msgSend)(model, setter, (propertyMapper->_foundationType == XZHFoundationTypeNSDictionary) ? valueSet : valueSet.mutableCopy);
                }
            }
                break;
            case XZHFoundationTypeCustomer: {
                // jsonValue.class ==> 1)自定义NSObject类型 2)NSDictionary 3)NSString
                if ([jsonItemValue isKindOfClass:propertyMapper->_ivarClass]) {
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)(model, setter, jsonItemValue);
                } else if ([jsonItemValue isKindOfClass:[NSDictionary class]] || [jsonItemValue isKindOfClass:[NSString class]]) {
                    if ([jsonItemValue isKindOfClass:[NSString class]]) {
//                        value = XZHConvertNullNSString(value);
                        jsonItemValue = XZHJSONStringToDic(jsonItemValue);
                    }
                    if (!jsonItemValue)return;
                    
                    Class cls = propertyMapper->_ivarClass;
                    if (XZHClassRespondsToSelector(propertyMapper->_generacCls, @selector(xzh_classForDictionary:))) {
                        cls = [propertyMapper->_generacCls xzh_classForDictionary:jsonItemValue];
                    }
                    id newItem = [cls xzh_modelFromJSONDictionary:jsonItemValue];
                    if (newItem) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)(model, setter, newItem);
                    }
                }
            }
                break;
            case XZHFoundationTypeNSDate: {
                // jsonValue.class ==> 1)NSString（日期字符串） 2)NSDate 3) NSNumber
                if ([jsonItemValue isKindOfClass:[NSDate class]]) {
                    ((void (*)(id, SEL, NSDate*))(void *) objc_msgSend)(model, setter, jsonItemValue);
                } else if ([jsonItemValue isKindOfClass:[NSNumber class]]) {
                    NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:[(NSNumber*)jsonItemValue doubleValue]];
                    if (date) {
                        ((void (*)(id, SEL, NSDate*))(void *) objc_msgSend)(model, setter, date);
                    }
                } else if ([jsonItemValue isKindOfClass:[NSString class]]) {
//                    value = XZHConvertNullNSString(value);
                    if (!jsonItemValue)return;
                    if (XZHClassRespondsToSelector(propertyMapper->_generacCls, @selector(xzh_dateFormat))) {
                        NSString *dateFormat = [propertyMapper->_generacCls xzh_dateFormat];
                        if (dateFormat) {
                            NSDateFormatter *fomatter = XZHDateFormatter(dateFormat);
                            NSDate *date = [fomatter dateFromString:jsonItemValue];
                            if (date) {
                                ((void (*)(id, SEL, NSDate*))(void *) objc_msgSend)(model, setter, date);
                            }
                        }
                    }
                }
            }
                break;
            case XZHFoundationTypeNSData:
            case XZHFoundationTypeNSMutableData: {
                // 1)NSData 2)NSString
                if ([jsonItemValue isKindOfClass:[NSData class]]) {
                    ((void (*)(id, SEL, NSData*))(void *) objc_msgSend)(model, setter, (propertyMapper->_foundationType == XZHFoundationTypeNSData) ? jsonItemValue : [jsonItemValue mutableCopy]);
                } else if ([jsonItemValue isKindOfClass:[NSString class]]) {
                    //                    value = XZHConvertNullNSString(value);
                    if (!jsonItemValue)return;
                    
                    NSData *data = [(NSString*)jsonItemValue dataUsingEncoding:NSUTF8StringEncoding];
                    if (data) {
                        ((void (*)(id, SEL, NSData*))(void *) objc_msgSend)(model, setter, (propertyMapper->_foundationType == XZHFoundationTypeNSData) ? data : [data mutableCopy]);
                    }
                }
            }
                break;
            case XZHFoundationTypeNSValue: {
                if ([jsonItemValue isKindOfClass:[NSValue class]]) {
                    ((void (*)(id, SEL, NSValue*))(void *) objc_msgSend)(model, setter, jsonItemValue);
                }
            }
                break;
            case XZHFoundationTypeNSBlock: {
                if ([jsonItemValue isKindOfClass:XZHGetNSBlockClass()]) {
                    /**
                     *  NSBlock的任意类: void(^)()，任意参数类型的block都可以设置进去，但是取出来执行的时候需要看参数类型
                     *  否则会程序崩溃
                     */
                    ((void (*)(id, SEL, void(^)()))(void *) objc_msgSend)(model, setter, jsonItemValue);
                }
            }
                break;
            case XZHFoundationTypeNSNull: {
                if ([jsonItemValue isKindOfClass:[NSNull class]]) {
                    ((void (*)(id, SEL, NSNull*))(void *) objc_msgSend)(model, setter, (id)kCFNull);
                }
            }
                break;
            case  XZHFoundationTypeNone:
                break;
                
        }//end switch mapper->_foundationType
        
    } else if (propertyMapper->_isCNumber) {
        NSNumber *number = XZHNumberWithValue(jsonItemValue);
        if (!number) return;
        switch (propertyMapper->_typeEncoding & XZHTypeEncodingDataTypeMask) {
            case XZHTypeEncodingChar: {
                char num = [number charValue];
                ((void (*)(id, SEL, char))(void *) objc_msgSend)(model, setter, num);
            }
                break;
            case XZHTypeEncodingUnsignedChar: {
                unsigned char num = [number unsignedCharValue];
                ((void (*)(id, SEL, unsigned char))(void *) objc_msgSend)(model, setter, num);
            }
                break;
            case XZHTypeEncodingBOOL: {
                BOOL num = [number boolValue];
                ((void (*)(id, SEL, BOOL))(void *) objc_msgSend)(model, setter, num);
            }
                break;
            case XZHTypeEncodingShort: {
                short num = [number shortValue];
                ((void (*)(id, SEL, short))(void *) objc_msgSend)(model, setter, num);
            }
                break;
            case XZHTypeEncodingUnsignedShort: {
                unsigned short num = [number shortValue];
                ((void (*)(id, SEL, unsigned short))(void *) objc_msgSend)(model, setter, num);
            }
                break;
            case XZHTypeEncodingInt: {
                int num = [number intValue];
                ((void (*)(id, SEL, int))(void *) objc_msgSend)(model, setter, num);
            }
                break;
            case XZHTypeEncodingUnsignedInt: {
                unsigned int num = [number unsignedIntValue];
                ((void (*)(id, SEL, unsigned int))(void *) objc_msgSend)(model, setter, num);
            }
                break;
            case XZHTypeEncodingFloat: {
                float num = [number floatValue];
                ((void (*)(id, SEL, float))(void *) objc_msgSend)(model, setter, num);
            }
                break;
            case XZHTypeEncodingLong32: {
                long num = [number longValue];
                ((void (*)(id, SEL, long))(void *) objc_msgSend)(model, setter, num);
            }
                break;
            case XZHTypeEncodingLongLong: {
                long long num = [number longLongValue];
                ((void (*)(id, SEL, long long))(void *) objc_msgSend)(model, setter, num);
            }
                break;
            case XZHTypeEncodingLongDouble: {
                long double num = [number doubleValue];
                ((void (*)(id, SEL, long double))(void *) objc_msgSend)(model, setter, num);
            }
                break;
            case XZHTypeEncodingUnsignedLong: {
                unsigned long num = [number unsignedLongValue];
                ((void (*)(id, SEL, unsigned long))(void *) objc_msgSend)(model, setter, num);
            }
                break;
            case XZHTypeEncodingUnsignedLongLong: {
                unsigned long long num = [number unsignedLongLongValue];
                ((void (*)(id, SEL, unsigned long long))(void *) objc_msgSend)(model, setter, num);
            }
                break;
            case XZHTypeEncodingDouble: {
                double num = [number doubleValue];
                ((void (*)(id, SEL, double))(void *) objc_msgSend)(model, setter, num);
            }
                break;
            default:
                break;
        }
    } else {
        /**
         *  C指针类型的变量，统一使用NSValue进行包装
         *  且使用NSValue包装c指针变量，会默认都转换成 `void*` 类型，其type encoding >>>> `^v`
         *
         *  - (1) c指针变量、CoreFoundation部分结构体实例
         *      - NSValue >>>> c指针变量
         *      - c指针变量 >>>> void*
         *      - c指针变量 >>>> Class/SEL
         *
         *  - (2) c数组、自定义c结构体实例、c共用体实例
         *      - 只能当做NSValue存取
         *      - 目前没有看到过 @property 声明c数组的形式
         *      - @property 声明 c结构体实例指针 ，自定义的c结构体实例 可能是不能支持 KVC、Achiver
         */
        switch (propertyMapper->_typeEncoding & XZHTypeEncodingDataTypeMask) {
            case XZHTypeEncodingCString:
            case XZHTypeEncodingCPointer: {
                if (jsonItemValue == (id)kCFNull) {
                    ((void (*)(id, SEL, void*))(void *) objc_msgSend)(model, setter, (void*)NULL);
                } else if ([jsonItemValue isKindOfClass:[NSValue class]]) {
                    NSValue *nsvalue = (NSValue *)jsonItemValue;
                    if (nsvalue.objCType && 0 == strcmp(nsvalue.objCType, "^v")) {
                        ((void (*)(id, SEL, void*))(void *) objc_msgSend)(model, setter, nsvalue.pointerValue);
                    }
                }
            }
                break;
            case XZHTypeEncodingObjcClass: {
                if (jsonItemValue == (id)kCFNull) {
                    ((void (*)(id, SEL, Class))(void *) objc_msgSend)(model, setter, (Class)NULL);
                } else {
                    if ([jsonItemValue isKindOfClass:[NSString class]]) {
                        Class cls = NSClassFromString(jsonItemValue);
                        if (Nil != cls) {
                            ((void (*)(id, SEL, Class))(void *) objc_msgSend)(model, setter, cls);
                        }
                    } else if ([jsonItemValue isKindOfClass:[NSValue class]]) {
                        NSValue *nsvalue = (NSValue *)jsonItemValue;
                        if (nsvalue.objCType && 0 == strcmp(nsvalue.objCType, "^v")) {
                            char *clsName = (char *)nsvalue.pointerValue;
                            if (NULL != clsName) {
                                Class cls = objc_getClass(clsName);//一、objc_getClass()
                                if (cls) {
                                    ((void (*)(id, SEL, Class))(void *) objc_msgSend)(model, setter, cls);
                                }
                            }
                        }
                    } else {
                        Class cls = object_getClass(jsonItemValue);//二、object_getClass()读取obj->_isa
                        if (cls) {
                            ((void (*)(id, SEL, Class))(void *) objc_msgSend)(model, setter, cls);
                        }
                    }
                }
            }
                break;
            case XZHTypeEncodingSEL: {
                if (jsonItemValue == (id)kCFNull) {
                    ((void (*)(id, SEL, SEL))(void *) objc_msgSend)(model, setter, (SEL)NULL);
                } else if ([jsonItemValue isKindOfClass:[NSString class]]){
                    SEL sel = NSSelectorFromString(jsonItemValue);
                    if (sel) {
                        ((void (*)(id, SEL, SEL))(void *) objc_msgSend)(model, setter, sel);
                    }
                } else if ([jsonItemValue isKindOfClass:[NSValue class]]) {
                    NSValue *nsvalue = (NSValue *)jsonItemValue;
                    if (nsvalue.objCType && strcmp(nsvalue.objCType, "^v")) {
                        char *selC = (char *)nsvalue.pointerValue;
                        if (selC) {
                            NSString *selF = [NSString stringWithUTF8String:selC];
                            SEL sel = NSSelectorFromString(selF);
                            if (sel) {
                                ((void (*)(id, SEL, SEL))(void *) objc_msgSend)(model, setter, sel);
                            }
                        }
                    }
                }
            }
                break;
            case XZHTypeEncodingCArray:
            case XZHTypeEncodingCStruct:
            case XZHTypeEncodingCUnion: {
                if (jsonItemValue == (id)kCFNull) {
                    ((void (*)(id, SEL, SEL))(void *) objc_msgSend)(model, setter, (SEL)NULL);
                } else if ([jsonItemValue isKindOfClass:[NSValue class]]) {
                    NSValue *nsvalue = (NSValue *)jsonItemValue;
                    const char *nsvalueCoding = nsvalue.objCType;
                    const char *propertyModelCoding = propertyMapper->_typeEncodingString.UTF8String;
                    if (nsvalueCoding && propertyModelCoding && 0 == strcmp(nsvalueCoding, propertyModelCoding)) {
                        ((void (*)(id, SEL, NSValue*))(void *) objc_msgSend)(model, setter, nsvalue);
                    }
                }
            }
                break;
        }
    }
}

static void XZHSetDictioanryWithKeyPath(__unsafe_unretained NSArray *keypathArray, __unsafe_unretained NSMutableDictionary *desDic, __unsafe_unretained id value) {
    NSMutableDictionary *superDic = desDic;
    NSMutableDictionary *subDic = nil;
    for (NSUInteger i = 0, max = keypathArray.count; i < max; i++) {
        NSString *key = keypathArray[i];
        if (i + 1 == max) { // end
            if (!superDic[key]) superDic[key] = value;
            break;
        }
        
        subDic = superDic[key];
        if (subDic) {
            if ([subDic isKindOfClass:[NSDictionary class]]) {
                subDic = subDic.mutableCopy;
                superDic[key] = subDic;
            } else {
                break;
            }
        } else {
            subDic = [NSMutableDictionary new];
            superDic[key] = subDic;
        }
        superDic = subDic;
        subDic = nil;
    }
}

static void XZHConvertModelToJSONApplierFunction(const void *mappedToKey, const void *propertyMapper, void *context) {
    if (!mappedToKey || !propertyMapper) return;
    XZHPropertyMapper *_propertyMapper = (__bridge XZHPropertyMapper *)(propertyMapper);
    XZHModelToJsonContext *ctx = (XZHModelToJsonContext *)context;
    __unsafe_unretained id object = (__bridge id)(ctx->model);
    if (!object || (id)kCFNull == object) return;
    __unsafe_unretained NSMutableDictionary *objectDic = (__bridge NSMutableDictionary*)(ctx->objectDic);
    if (!objectDic) return;
    
    /**
     *  拿到属性变量的值
     *  - (1) 属性值: NSString、NSNumber直接设置到dic
     *  - (2) 属性值: NSArray, NSDictionary, NSNull需要再进行转换
     */
    id dic_value = nil;
    if (_propertyMapper->_isCNumber) {
        // 基本数值类型
        dic_value = XZHNumberWithModelProperty(object, _propertyMapper);
    } else if (XZHFoundationTypeNone != _propertyMapper->_foundationType) {
        // Foundation类型（1.NSNumber 2.其他Foundation类 3.自定义NSObject子类）
        dic_value = ((id (*)(id, SEL))(void *) objc_msgSend)(object, _propertyMapper->_property.getter);
        dic_value = XZHConvertModelToAbleJSONSerialization(dic_value);
    } else {
        // Class、SEL
        if (XZHTypeEncodingObjcClass == (_propertyMapper->_typeEncoding & XZHTypeEncodingDataTypeMask)) {
            Class cls = ((Class (*)(id, SEL))(void *) objc_msgSend)(object, _propertyMapper->_property.getter);
            dic_value = (NULL != cls) ? NSStringFromClass(cls) : nil;
        } else if (XZHTypeEncodingSEL == (_propertyMapper->_typeEncoding & XZHTypeEncodingDataTypeMask)) {
            SEL sel = ((SEL (*)(id, SEL))(void *) objc_msgSend)(object, _propertyMapper->_property.getter);
            dic_value = (NULL != sel) ? NSStringFromSelector(sel) : nil;
        }
    }
    if (!dic_value || (id)kCFNull == dic_value) {return ;}
    
    /**
     *  将可以json化的属性值，按照映射的jsonkey类型，设置到dic
     */
    if (_propertyMapper->_mappedToKeyPath) {
        NSArray *keyArray = [_propertyMapper->_mappedToSimpleKey componentsSeparatedByString:@"."];
        XZHSetDictioanryWithKeyPath(keyArray, objectDic, dic_value);
    } else if (_propertyMapper->_mappedToKeyArray) {
        for (NSString *keyItem in _propertyMapper->_mappedToKeyArray) {
            if (NSNotFound != [keyItem rangeOfString:@"."].location) {
                NSArray *keyArray = [keyItem componentsSeparatedByString:@"."];
                XZHSetDictioanryWithKeyPath(keyArray, objectDic, dic_value);
            } else {
                [objectDic setObject:dic_value forKey:keyItem];
            }
        }
    } else {
        [objectDic setObject:dic_value forKey:_propertyMapper->_mappedToSimpleKey];
    }
}

static id XZHConvertModelToAbleJSONSerialization(__unsafe_unretained id object) {
    if (!object || ((id)kCFNull == object)) {return nil;}
    
    /**
     *  符合json化的基本foundation类型 >>> NSString、NSNumber
     */
    if ([object isKindOfClass:[NSString class]]) {return object;}
    if ([object isKindOfClass:[NSNumber class]]) {return object;}
    if ([object isKindOfClass:[NSAttributedString class]]) {return [(NSAttributedString*)object string];}
    if ([object isKindOfClass:[NSURL class]]) {return [(NSURL*)object absoluteString];}
    if ([object isKindOfClass:[NSDate class]]) {return [XZHDateFormatter(nil) stringFromDate:object];}
    
    /**
     *  不符合json化的基本foundation类型 >>> NSData（后续如果需要转NSString再说）
     */
    if ([object isKindOfClass:[NSData class]]) return nil;
    
    /**
     *  容器类型一、NSDictionry的json化处理
     */
    if ([object isKindOfClass:[NSDictionary class]]) {
        if ([NSJSONSerialization isValidJSONObject:object]) {return object;}
        /**
         *  - (1) All objects are instances of NSString, NSNumber, NSArray, NSDictionary, or NSNull.
         *  - (2) All dictionary keys are instances of NSString.
         */
        NSMutableDictionary *newDic = [NSMutableDictionary new];
        [newDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
            NSString *dic_key = ([key isKindOfClass:[NSString class]]) ? key : [key description];
            if (!dic_key) {return ;}
            id dic_value = XZHConvertModelToAbleJSONSerialization(value);
            if (!dic_value || ((id)kCFNull == dic_value)) {return ;}
            newDic[dic_key] = dic_value;
        }];
        return newDic;
    }
    
    /**
     *  容器类型二、NSSet的json化处理
     *  容器类型三、NSArray的json化处理
     */
    if ([object isKindOfClass:[NSSet class]] || [object isKindOfClass:[NSArray class]]) {
        if ([NSJSONSerialization isValidJSONObject:object]) {return object;}
        /**
         *  - (1) NSSet >>> NSArray
         *  - (2) All objects are instances of NSString, NSNumber, NSArray, NSDictionary, NSNull.
         */
        NSArray *arrayObj = object;
        if ([object isKindOfClass:[NSSet class]]) {
            arrayObj = [(NSSet*)object allObjects];
        }
        NSMutableArray *newArray = [[NSMutableArray alloc] initWithCapacity:arrayObj.count];
        [(NSSet*)arrayObj enumerateObjectsUsingBlock:^(id  _Nonnull value, BOOL * _Nonnull stop) {
            if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]) {
                [newArray addObject:value];
            } else {
                id arr_value = XZHConvertModelToAbleJSONSerialization(value);
                if (!arr_value || ((id)kCFNull == arr_value)) {return ;}
                [newArray addObject:arr_value];
            }
        }];
        return newArray;
    }
    
    /**
     *  自定义NSObject实体类json化处理、组装成一个Dic对象
     *  - dic.key >>> propertyName or mappedToJsonKey
     *  - dic.value >>> propertyValue json处理后的对象
     */
    __unsafe_unretained XZHClassMapper *classMapper = [XZHClassMapper classMapperWithClass:[object class]];
    if (!classMapper || (0 == classMapper->_totalMappedCount)) {return nil;}
    NSMutableDictionary *objectDic = [[NSMutableDictionary alloc] initWithCapacity:64];
    XZHModelToJsonContext ctx = {0};
    ctx.model = (__bridge void*)object;
    ctx.objectDic = (__bridge void*)objectDic;
    CFDictionaryApplyFunction(classMapper->_jsonKeyPropertyMapperDic, XZHConvertModelToJSONApplierFunction, &ctx);
    return objectDic;
}

static void XZHJsonToModelApplierFunctionWithJSONDict(const void *jsonKey, const void *jsonItemValue, void *context) {
    if (NULL == jsonKey || NULL == jsonItemValue || NULL == context) {return;}
    
    /**
     *  使用 __unsafe_unretained 修饰OC对象指针，减少runtime system自动进行retain操作影响代码运行速度
     *  因为jsonDic、classMapper、propertyMapper、model都是由Context结构体实例持有
     *  所以不必担心jsonDic、classMapper、propertyMapper、model 这些对象会被废弃的问题
     */
    XZHJsonToModelContext *ctx = (XZHJsonToModelContext *)context;
    __unsafe_unretained id model = (__bridge id)(ctx->model);
    if (!model) {return;}
    
    __unsafe_unretained XZHClassMapper *clsMapper = (__bridge XZHClassMapper*)(ctx->classMapper);
    if (!clsMapper || clsMapper->_totalMappedCount < 1) {return;}
    
    /**
     *  统一按照n:1的方式，将jsonItemValue设置给property
     */
    __unsafe_unretained XZHPropertyMapper *propertyMapper = CFDictionaryGetValue(clsMapper->_jsonKeyPropertyMapperDic, jsonKey);
    while (propertyMapper) {
        if (propertyMapper->_isSetterAccess) {
            /**
             *  直接遍历jsonDic.key与jsonDic.value设置到model.property
             */
            XZHSetFoundationObjectToProperty((__bridge __unsafe_unretained id)jsonItemValue, model, propertyMapper);
        }
        propertyMapper = propertyMapper->_next;
    }
}

static void XZHJsonToModelApplierFunctionWithPropertyMappers(const void *value, void *context) {
    if (NULL == value || NULL == context) {return;}
    XZHJsonToModelContext *ctx = (XZHJsonToModelContext *)context;
    __unsafe_unretained NSDictionary *jsonDic = (__bridge NSDictionary *)(ctx->jsonDic);
    if (!jsonDic || ![jsonDic isKindOfClass:[NSDictionary class]]) return;

    __unsafe_unretained XZHPropertyMapper *propertyMapper = (__bridge XZHPropertyMapper*)(value);
    while (propertyMapper) {
        id jsonValue = nil;
        
        /**
         *  按照property映射的jsonkey类型，从jsonDic中取出jsonItemValue
         */
        if (XZHPropertyMappedToJsonKeyTypeKeyPath == propertyMapper->_mappedType) {
            // property mapped to JsonKeyPath
            jsonValue = [jsonDic valueForKeyPath:propertyMapper->_mappedToKeyPath];
        } else if (XZHPropertyMappedToJsonKeyTypeKeyArray == propertyMapper->_mappedType) {
            // property mapped to JsonKeyArray
            jsonValue = XZHGetValueFromDictionaryWithMultiJSONKeyArray(jsonDic, propertyMapper->_mappedToKeyArray);
        } else {
            // property mapped to JsonKey
            jsonValue = [jsonDic objectForKey:propertyMapper->_mappedToSimpleKey];
        }
        
        /**
         *  统一按照n:1的方式，将jsonItemValue设置给property
         */
        if (jsonValue && ((id)kCFNull) != jsonValue) {
            __unsafe_unretained id model = (__bridge __unsafe_unretained id)(ctx->model);
            if (!model || (id)kCFNull == model) {return;}
            XZHSetFoundationObjectToProperty(jsonValue, model, propertyMapper);
        }
        propertyMapper = propertyMapper->_next;
    }
}

static xzh_force_inline NSDateFormatter* XZHDateFormatter(__unsafe_unretained NSString *dateFormat) {
    if (!dateFormat) return nil;
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    });
    if (dateFormat) {
        formatter.dateFormat = dateFormat;
    } else {
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    }
    return formatter;
}
