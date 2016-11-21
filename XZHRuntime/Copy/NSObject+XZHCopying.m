//
//  NSObject+XZHCopying.m
//  XZHRuntimeDemo
//
//  Created by XiongZenghui on 16/10/9.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import "NSObject+XZHCopying.h"
#import "XZHRuntime.h"
#import <objc/message.h>

@implementation NSObject (XZHCopying) 

- (instancetype)xzh_copy {
    Class selfClass = [self class];
    
    // basic type
    if ((id)kCFNull == self){return nil;}
    if ([selfClass isSubclassOfClass:[NSMutableString class]]) {return [self mutableCopy];}
    if ([selfClass isSubclassOfClass:[NSString class]]) {return [self copy];}
    if ([selfClass isSubclassOfClass:[NSMutableArray class]]) {return [self mutableCopy];}
    if ([selfClass isSubclassOfClass:[NSArray class]]) {return [self copy];}
    if ([selfClass isSubclassOfClass:[NSMutableDictionary class]]) {return [self mutableCopy];}
    if ([selfClass isSubclassOfClass:[NSDictionary class]]) {return [self copy];}
    if ([selfClass isSubclassOfClass:[NSMutableSet class]]) {return [self mutableCopy];}
    if ([selfClass isSubclassOfClass:[NSSet class]]) {return [self copy];}
    if ([selfClass isSubclassOfClass:[NSNumber class]]) {return [self copy];}
    if ([selfClass isSubclassOfClass:[NSURL class]]) {return [self copy];}
    if ([selfClass isSubclassOfClass:[NSDate class]]) {return [self copy];}
    if ([selfClass isSubclassOfClass:[NSValue class]]) {return [self copy];}
    if ([selfClass isSubclassOfClass:XZHGetNSBlockClass()]) {return [self copy];}
    if ([selfClass isSubclassOfClass:[NSData class]]) {return [self copy];}
    if ([selfClass isSubclassOfClass:[NSMutableData class]]) {return [self mutableCopy];}
    
    // custom Class type
    NSObject *newOne = [[selfClass alloc] init];
    NSMutableArray *propertyModelArray = [[NSMutableArray alloc] initWithCapacity:32];
    __unsafe_unretained XZHClassModel *clsModel = [XZHClassModel instanceWithClass:selfClass];
    while (clsModel) {
        for (__unsafe_unretained XZHPropertyModel *proModel in clsModel.propertyMap.allValues) {
            if (!proModel.name) {continue;}
            if (!proModel.setter || !proModel.getter) {continue;}
            [propertyModelArray addObject:proModel];
            clsModel = clsModel.superClassModel;
        }
    }
    for (XZHPropertyModel *proModel in propertyModelArray) {
        SEL getter = proModel.getter;
        SEL setter = proModel.setter;
        if (proModel.isCNumber) {
            switch (proModel.typeEncoding & XZHTypeEncodingDataTypeMask) {
                case XZHTypeEncodingChar: {//char、int8_t
                    char num = ((char (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    ((void (*)(id, SEL, char))(void *) objc_msgSend)(newOne, setter, num);
                }
                    break;
                case XZHTypeEncodingUnsignedChar: {//unsigned char、uint8_t
                    unsigned char num = ((unsigned char (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    ((void (*)(id, SEL, unsigned char))(void *) objc_msgSend)(newOne, setter, num);
                }
                    break;
                case XZHTypeEncodingBOOL: {
                    BOOL num = ((BOOL (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    ((void (*)(id, SEL, BOOL))(void *) objc_msgSend)(newOne, setter, num);
                }
                    break;
                case XZHTypeEncodingShort: {//short、int16_t、
                    short num = ((short (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    ((void (*)(id, SEL, short))(void *) objc_msgSend)(newOne, setter, num);
                }
                    break;
                case XZHTypeEncodingUnsignedShort: {//unsigned short、uint16_t、
                    unsigned short num = ((unsigned short (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    ((void (*)(id, SEL, unsigned short))(void *) objc_msgSend)(newOne, setter, num);
                }
                    break;
                case XZHTypeEncodingInt: {//int、int32_t、
                    int num = ((int (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    ((void (*)(id, SEL, int))(void *) objc_msgSend)(newOne, setter, num);
                }
                    break;
                case XZHTypeEncodingUnsignedInt: {//unsigned int、uint32_t
                    unsigned int num = ((unsigned int (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    ((void (*)(id, SEL, unsigned int))(void *) objc_msgSend)(newOne, setter, num);
                }
                    break;
                case XZHTypeEncodingFloat: {
                    float num = ((float (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    ((void (*)(id, SEL, float))(void *) objc_msgSend)(newOne, setter, num);
                }
                    break;
                case XZHTypeEncodingLong32: {
                    long num = ((long (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    if (!isnan(num) && !isinf(num)) {
                        ((void (*)(id, SEL, long))(void *) objc_msgSend)(newOne, setter, num);
                    }
                }
                    break;
                case XZHTypeEncodingLongLong: {
                    long long num = ((long long (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    if (!isnan(num) &&  !isinf(num)) {
                        ((void (*)(id, SEL, long long ))(void *) objc_msgSend)(newOne, setter, num);
                    }
                }
                    break;
                case XZHTypeEncodingLongDouble: {
                    double num = ((long double (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    if (!isnan(num) && !isinf(num)) {
                        ((void (*)(id, SEL, double))(void *) objc_msgSend)(newOne, setter, num);
                    }
                }
                    break;
                case XZHTypeEncodingUnsignedLong: {
                    unsigned long num = ((unsigned long (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    if (!isnan(num) && !isinf(num)) {
                        ((void (*)(id, SEL, unsigned long))(void *) objc_msgSend)(newOne, setter, num);
                    }
                }
                    break;
                case XZHTypeEncodingUnsignedLongLong: {
                    unsigned long long num = ((unsigned long long (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    if (!isnan(num) && !isinf(num)) {
                        ((void (*)(id, SEL, unsigned long long))(void *) objc_msgSend)(newOne, setter, num);
                    }
                }
                    break;
                case XZHTypeEncodingDouble: {
                    double num = ((double (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    if (!isnan(num) && !isinf(num)) {
                        ((void (*)(id, SEL, double))(void *) objc_msgSend)(newOne, setter, num);
                    }
                }
                    break;
                default:
                    break;
            }
        } else if (XZHFoundationTypeNone != proModel.foundationType) {
            /**
             *  Foudation对象的浅拷贝处理
             */
            id obj = ((id (*)(id, SEL))(void *) objc_msgSend)(self, getter);
            if (obj) {
                ((void (*)(id, SEL, id))(void *) objc_msgSend)(newOne, setter, obj);
            }
        } else {
            switch (proModel.typeEncoding & XZHTypeEncodingDataTypeMask) {
                case XZHTypeEncodingClass: {
                    Class cls = ((Class (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    if (NULL != cls) {
                        ((void (*)(id, SEL, Class))(void *) objc_msgSend)(newOne, setter, cls);
                    }
                }
                    break;
                case XZHTypeEncodingSEL: {
                    SEL sel = ((SEL (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    if (NULL != sel) {
                        ((void (*)(id, SEL, SEL))(void *) objc_msgSend)(newOne, setter, sel);
                    }
                }
                    break;
                case XZHTypeEncodingCString:
                case XZHTypeEncodingCPointer: {
                    void *pointer = ((void* (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    if (pointer) {
                        ((void (*)(id, SEL, void*))(void *) objc_msgSend)(newOne, setter, pointer);
                    }
                }
                    break;
                case XZHTypeEncodingCStruct:
                case XZHTypeEncodingCUnion: {
                    /**
                     *  这两种类型的属性必须使用NSValue包装
                     */
                    @try {
                        NSValue *value = [self valueForKey:proModel.name];
                        if (value) {
                            [newOne setValue:value forKey:proModel.name];
                        }
                    } @catch (NSException *exception) {}
                }
                    break;
                default:
                    break;
            }
        }
    }
    return newOne;
}

- (instancetype)xzh_deepCopy {
    Class selfClass = [self class];
    
    // basic type
    if ((id)kCFNull == self){return nil;}
    if ([selfClass isSubclassOfClass:[NSMutableString class]]) {return [self mutableCopy];}
    if ([selfClass isSubclassOfClass:[NSString class]]) {return [self copy];}
    if ([selfClass isSubclassOfClass:[NSNumber class]]) {return [self copy];}
    if ([selfClass isSubclassOfClass:[NSURL class]]) {return [self copy];}
    if ([selfClass isSubclassOfClass:[NSDate class]]) {return [self copy];}
    if ([selfClass isSubclassOfClass:[NSValue class]]) {return [self copy];}
    if ([selfClass isSubclassOfClass:XZHGetNSBlockClass()]) {return [self copy];}
    if ([selfClass isSubclassOfClass:[NSData class]]) {return [self copy];}
    if ([selfClass isSubclassOfClass:[NSMutableData class]]) {return [self mutableCopy];}
    
    // Array
    if ([selfClass isSubclassOfClass:[NSArray class]]) {
        NSArray *array = (NSArray *)self;
        NSMutableArray *copyItems = [[NSMutableArray alloc] initWithCapacity:array.count];
        for (id item in array) {
            id copyItem = [item xzh_deepCopy];
            if (copyItem) {[copyItems addObject:copyItem];}
        }
        if ([selfClass isSubclassOfClass:[NSMutableArray class]]) {
            return copyItems;
        }
        return [copyItems copy];
    }
    
    // Dic
    if ([selfClass isSubclassOfClass:[NSDictionary class]]) {
        NSDictionary *dic = (NSDictionary *)self;
        NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] initWithCapacity:dic.count];
        [mutableDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            id copyItem = [obj xzh_deepCopy];
            if (copyItem) {[mutableDic setObject:copyItem forKey:key];}
        }];
        if ([selfClass isSubclassOfClass:[NSMutableDictionary class]]) {
            return mutableDic;
        }
        return [mutableDic copy];
    }
    
    // Set
    if ([selfClass isSubclassOfClass:[NSSet class]]) {
        NSSet *set = (NSSet *)self;
        NSMutableSet *mutableSet = [[NSMutableSet alloc] initWithCapacity:set.count];
        for (id item in set) {
            id copyItem = [item xzh_deepCopy];
            if (copyItem) {[mutableSet addObject:copyItem];}
        }
        if ([selfClass isSubclassOfClass:[NSMutableSet class]]) {
            return mutableSet;
        }
        return [mutableSet copy];
    }
    
    // custom Class type
    NSObject *newOne = [[selfClass alloc] init];
    NSMutableArray *propertyModelArray = [[NSMutableArray alloc] initWithCapacity:32];
    __unsafe_unretained XZHClassModel *clsModel = [XZHClassModel instanceWithClass:selfClass];
    while (clsModel) {
        for (__unsafe_unretained XZHPropertyModel *proModel in clsModel.propertyMap.allValues) {
            if (!proModel.name) {continue;}
            if (!proModel.setter || !proModel.getter) {continue;}
            [propertyModelArray addObject:proModel];
            clsModel = clsModel.superClassModel;
        }
    }
    for (XZHPropertyModel *proModel in propertyModelArray) {
        SEL getter = proModel.getter;
        SEL setter = proModel.setter;
        if (proModel.isCNumber) {
            switch (proModel.typeEncoding & XZHTypeEncodingDataTypeMask) {
                case XZHTypeEncodingChar: {//char、int8_t
                    char num = ((char (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    ((void (*)(id, SEL, char))(void *) objc_msgSend)(newOne, setter, num);
                }
                    break;
                case XZHTypeEncodingUnsignedChar: {//unsigned char、uint8_t
                    unsigned char num = ((unsigned char (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    ((void (*)(id, SEL, unsigned char))(void *) objc_msgSend)(newOne, setter, num);
                }
                    break;
                case XZHTypeEncodingBOOL: {
                    BOOL num = ((BOOL (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    ((void (*)(id, SEL, BOOL))(void *) objc_msgSend)(newOne, setter, num);
                }
                    break;
                case XZHTypeEncodingShort: {//short、int16_t、
                    short num = ((short (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    ((void (*)(id, SEL, short))(void *) objc_msgSend)(newOne, setter, num);
                }
                    break;
                case XZHTypeEncodingUnsignedShort: {//unsigned short、uint16_t、
                    unsigned short num = ((unsigned short (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    ((void (*)(id, SEL, unsigned short))(void *) objc_msgSend)(newOne, setter, num);
                }
                    break;
                case XZHTypeEncodingInt: {//int、int32_t、
                    int num = ((int (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    ((void (*)(id, SEL, int))(void *) objc_msgSend)(newOne, setter, num);
                }
                    break;
                case XZHTypeEncodingUnsignedInt: {//unsigned int、uint32_t
                    unsigned int num = ((unsigned int (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    ((void (*)(id, SEL, unsigned int))(void *) objc_msgSend)(newOne, setter, num);
                }
                    break;
                case XZHTypeEncodingFloat: {
                    float num = ((float (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    ((void (*)(id, SEL, float))(void *) objc_msgSend)(newOne, setter, num);
                }
                    break;
                case XZHTypeEncodingLong32: {
                    long num = ((long (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    if (!isnan(num) && !isinf(num)) {
                        ((void (*)(id, SEL, long))(void *) objc_msgSend)(newOne, setter, num);
                    }
                }
                    break;
                case XZHTypeEncodingLongLong: {
                    long long num = ((long long (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    if (!isnan(num) &&  !isinf(num)) {
                        ((void (*)(id, SEL, long long ))(void *) objc_msgSend)(newOne, setter, num);
                    }
                }
                    break;
                case XZHTypeEncodingLongDouble: {
                    double num = ((long double (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    if (!isnan(num) && !isinf(num)) {
                        ((void (*)(id, SEL, double))(void *) objc_msgSend)(newOne, setter, num);
                    }
                }
                    break;
                case XZHTypeEncodingUnsignedLong: {
                    unsigned long num = ((unsigned long (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    if (!isnan(num) && !isinf(num)) {
                        ((void (*)(id, SEL, unsigned long))(void *) objc_msgSend)(newOne, setter, num);
                    }
                }
                    break;
                case XZHTypeEncodingUnsignedLongLong: {
                    unsigned long long num = ((unsigned long long (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    if (!isnan(num) && !isinf(num)) {
                        ((void (*)(id, SEL, unsigned long long))(void *) objc_msgSend)(newOne, setter, num);
                    }
                }
                    break;
                case XZHTypeEncodingDouble: {
                    double num = ((double (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    if (!isnan(num) && !isinf(num)) {
                        ((void (*)(id, SEL, double))(void *) objc_msgSend)(newOne, setter, num);
                    }
                }
                    break;
                default:
                    break;
            }
        } else if (XZHFoundationTypeNone != proModel.foundationType) {
            /**
             *  Foudation对象的深拷贝处理
             */
            id value = ((id (*)(id, SEL))(void *) objc_msgSend)(self, getter);
            switch (proModel.foundationType) {
                case XZHFoundationTypeNSString: {
                    ((void (*)(id, SEL, NSString*))(void *) objc_msgSend)(newOne, setter, [value copy]);
                }
                    break;
                case XZHFoundationTypeNSMutableString: {
                    ((void (*)(id, SEL, NSMutableString*))(void *) objc_msgSend)(newOne, setter, [value mutableCopy]);
                }
                    break;
                case XZHFoundationTypeNSArray:
                case XZHFoundationTypeNSMutableArray: {
                    id copyItem = [value xzh_deepCopy];
                    if (copyItem) {
                        ((void (*)(id, SEL, NSArray*))(void *) objc_msgSend)(newOne, setter, copyItem);
                    }
                }
                    break;
                case XZHFoundationTypeNSSet:
                case XZHFoundationTypeNSMutableSet: {
                    id copyItem = [value xzh_deepCopy];
                    if (copyItem) {
                        ((void (*)(id, SEL, NSSet*))(void *) objc_msgSend)(newOne, setter, copyItem);
                    }
                }
                    break;
                case XZHFoundationTypeNSDictionary:
                case XZHFoundationTypeNSMutableDictionary: {
                    id copyItem = [value xzh_deepCopy];
                    if (copyItem) {
                        ((void (*)(id, SEL, NSDictionary*))(void *) objc_msgSend)(newOne, setter, copyItem);
                    }
                }
                    break;
                case XZHFoundationTypeCustomer: {
                    id copyItem = [value xzh_deepCopy];
                    if (copyItem) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)(newOne, setter, copyItem);
                    }
                }
                    break;
                case XZHFoundationTypeNSNumber:
                case XZHFoundationTypeNSDecimalNumber: {
                    ((void (*)(id, SEL, NSNumber*))(void *) objc_msgSend)(newOne, setter, [value copy]);
                }
                    break;
                case XZHFoundationTypeNSURL:
                case XZHFoundationTypeNSDate:
                case XZHFoundationTypeNSValue:
                case XZHFoundationTypeNSNull: {
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)(newOne, setter, [value copy]);
                }
                    break;
                case XZHFoundationTypeNSData:
                case XZHFoundationTypeNSMutableData: {
                    ((void (*)(id, SEL, NSData*))(void *) objc_msgSend)(newOne, setter, (XZHFoundationTypeNSData == proModel.foundationType) ? [value copy] : [value mutableCopy]);
                }
                    break;
                default:
                    break;
            }
        } else {
            switch (proModel.typeEncoding & XZHTypeEncodingDataTypeMask) {
                case XZHTypeEncodingClass: {
                    Class cls = ((Class (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    if (NULL != cls) {
                        ((void (*)(id, SEL, Class))(void *) objc_msgSend)(newOne, setter, cls);
                    }
                }
                    break;
                case XZHTypeEncodingSEL: {
                    SEL sel = ((SEL (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    if (NULL != sel) {
                        ((void (*)(id, SEL, SEL))(void *) objc_msgSend)(newOne, setter, sel);
                    }
                }
                    break;
                case XZHTypeEncodingCString:
                case XZHTypeEncodingCPointer: {
                    void *pointer = ((void* (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    if (pointer) {
                        ((void (*)(id, SEL, void*))(void *) objc_msgSend)(newOne, setter, pointer);
                    }
                }
                    break;
                case XZHTypeEncodingCStruct:
                case XZHTypeEncodingCUnion: {
                    /**
                     *  这两种类型的属性必须使用NSValue包装
                     */
                    @try {
                        NSValue *value = [self valueForKey:proModel.name];
                        if (value) {
                            [newOne setValue:value forKey:proModel.name];
                        }
                    } @catch (NSException *exception) {}
                }
                    break;
                default:
                    break;
            }
        }
    }
    return newOne;
}

@end
