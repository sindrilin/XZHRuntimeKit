//
//  NSObject+XZHCopying.m
//  XZHRuntimeDemo
//
//  Created by XiongZenghui on 16/10/9.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import "NSObject+XZHModel.h"
#import "XZHRuntime.h"
#import <objc/message.h>

static NSString *const kSpaceString = @"    ";//4个空格，代替\t
static const NSInteger KSpaceStringLen = 4;

/**
 *  处理当前字符串的缩进距离, indent标示缩进的层次
 *  主要控制缩进后换行的最后一个结束符（ }、] ）
 */
static NSMutableString *XZHDescriptionAddIndent(NSMutableString *desc, NSUInteger indent) {
    NSUInteger max = desc.length;
    
    // 在desc中的 \n 后面插入 kSpaceString表示的四个空格符，来代替\t的作用
    for (NSUInteger i = 0; i < max; i++) {
        unichar c = [desc characterAtIndex:i];
        if (c == '\n') {
            for (NSUInteger j = 0; j < indent; j++) {
                [desc insertString:kSpaceString atIndex:i + 1];
            }
            i += indent * KSpaceStringLen;
            max += indent * KSpaceStringLen;
        }
    }
    return desc;
}


static NSString* XZHGetObjectDescription(NSObject *object) {
    if (!object) {return @"<nil>";}
    if ((id)kCFNull == object) {return @"<null>";}
    if (![object isKindOfClass:[NSObject class]]) {return [NSString stringWithFormat:@"%@", object];}
    
    __unsafe_unretained XZHClassModel *clsModel = [XZHClassModel classModelWithClass:[object class]];
    switch (clsModel.foundationType) {
        case XZHFoundationTypeNSString:
        case XZHFoundationTypeNSMutableString: {
            return [NSString stringWithFormat:@"(NSString *)%@", object];
        }
            break;
        case XZHFoundationTypeNSNumber:
        case XZHFoundationTypeNSDecimalNumber: {
            return [NSString stringWithFormat:@"(NSNumber *)%@", object];
        }
            break;
        case XZHFoundationTypeNSDate: {
            return [NSString stringWithFormat:@"(NSDate *)%@", object];
        }
            break;
        case XZHFoundationTypeNSURL: {
            return [NSString stringWithFormat:@"(NSURL *)%@", object];
        }
            break;
        case XZHFoundationTypeNSData:
        case XZHFoundationTypeNSMutableData: {
            return [NSString stringWithFormat:@"(NSData *)%@", [object description]];
        }
            break;
        case XZHFoundationTypeNSValue: {
            return [NSString stringWithFormat:@"(NSValue *)%@", object];
        }
            break;
        case XZHFoundationTypeNSNull: {
            return [NSString stringWithFormat:@"(NSNull *)%@", object];
        }
            break;
        case XZHFoundationTypeNSBlock: {
            return [NSString stringWithFormat:@"(NSBlock *)%@", object];
        }
            break;
        case XZHFoundationTypeNSArray :
        case XZHFoundationTypeNSMutableArray: {
            NSArray *array = (NSArray*)object;
            NSMutableString *desc = [NSMutableString new];
            if (array.count == 0) {
                return [desc stringByAppendingString:@"[]"];
            } else {
                [desc appendFormat:@"[\n"];
                for (NSUInteger i = 0, max = array.count; i < max; i++) {
                    NSObject *obj = array[i];
                    [desc appendFormat:@"%@", kSpaceString];// \t
                    [desc appendString:XZHDescriptionAddIndent(XZHGetObjectDescription(obj).mutableCopy, 1)];
                    [desc appendString:(i + 1 == max) ? @"\n" : @",\n"];
                }
                [desc appendString:@"]"];
                return desc;
            }

        }
            break;
        case XZHFoundationTypeNSSet :
        case XZHFoundationTypeNSMutableSet: {
            NSArray *array = [(NSSet*)object allObjects];
            NSMutableString *desc = [NSMutableString new];
            if (array.count == 0) {
                return [desc stringByAppendingString:@"[]"];
            } else {
                [desc appendFormat:@"[\n"];
                for (NSUInteger i = 0, max = array.count; i < max; i++) {
                    NSObject *obj = array[i];
                    [desc appendFormat:@"%@", kSpaceString];// \t
                    [desc appendString:XZHDescriptionAddIndent(XZHGetObjectDescription(obj).mutableCopy, 1)];
                    [desc appendString:(i + 1 == max) ? @"\n" : @",\n"];
                }
                [desc appendString:@"]"];
                return desc;
            }
            
        }
        case XZHFoundationTypeNSDictionary :
        case XZHFoundationTypeNSMutableDictionary: {
            NSDictionary *dic = (NSDictionary*)object;
            __block NSUInteger count = -1;
            NSUInteger max = dic.count;
            NSMutableString *desc = [NSMutableString new];
            if (dic.count == 0) {
                return [desc stringByAppendingString:@"{}"];
            } else {
                [desc appendFormat:@"{\n"];
                [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    count++;
                    [desc appendFormat:@"%@", kSpaceString];// \t
                    NSString *string = [NSString stringWithFormat:@"%@ = %@", key, XZHDescriptionAddIndent(XZHGetObjectDescription(obj).mutableCopy, 1)];
                    [desc appendString:string];
                    [desc appendString:(count + 1 == max) ? @"\n" : @",\n"];
                }];
                [desc appendString:@"}"];
                return desc;
            }
        }
            break;
        case XZHFoundationTypeCustomer: {
            NSMutableString *desc = [[NSMutableString alloc] initWithCapacity:100];
            if (0 == clsModel.propertyMap.count) {return [NSString stringWithFormat:@"<%@ : %p>   {}", [object class], object];}
            
            [desc appendFormat:@"<%@ : %p>%@{\n", [object class], object, kSpaceString];
            NSMutableArray *propertyModelArray = [[NSMutableArray alloc] initWithCapacity:32];
            while (clsModel && clsModel.superCls != nil) {
                for (__unsafe_unretained XZHPropertyModel *proModel in clsModel.propertyMap.allValues) {
                    if (!proModel.name) {continue;}
                    if (!proModel.setter || !proModel.getter) {continue;}
                    [propertyModelArray addObject:proModel];
                    clsModel = clsModel.superClassModel;
                }
            }
            for (NSInteger i = 0,max = propertyModelArray.count; i < max; i++) {
                __unsafe_unretained XZHPropertyModel *proModel = propertyModelArray[i];
                [desc appendFormat:@"%@", kSpaceString];// \t
                NSString *ivarName = [NSString stringWithFormat:@"%@", proModel.name];
                SEL getter = proModel.getter;
                if (NULL == getter) {continue;}
                id value = nil;
                @try {
                    value = [object valueForKey:ivarName];
                } @catch (NSException *exception) {}
                NSString *valueString = (value != nil) ? XZHDescriptionAddIndent(XZHGetObjectDescription(value).mutableCopy, 1) : @"unknown";
                NSString *string = [NSString stringWithFormat:@"%@ = %@", ivarName, valueString];
                [desc appendString:string];
                [desc appendString:(propertyModelArray.count + 1 == max) ? @"\n" : @",\n"];
            }
            [desc appendString:@"}"];
            return desc.copy;
        }
            break;
        default:
            break;
    }
    return @"";
}

@implementation NSObject (XZHModel) 

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
    
    // Custom Class's all property
    NSObject *newOne = [[selfClass alloc] init];
    NSMutableArray *propertyModelArray = [[NSMutableArray alloc] initWithCapacity:32];
    __unsafe_unretained XZHClassModel *clsModel = [XZHClassModel classModelWithClass:[self class]];
    while (clsModel && clsModel.superCls != nil) {
        for (__unsafe_unretained XZHPropertyModel *proModel in clsModel.propertyMap.allValues) {
            if (!proModel.name) {continue;}
            if (!proModel.setter || !proModel.getter) {continue;}
            [propertyModelArray addObject:proModel];
            clsModel = clsModel.superClassModel;
        }
    }
    
    // 遍历Class's所有的属性，依次赋值所有的Ivar值
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
    
    // Custom Class's all property
    NSObject *newOne = [[selfClass alloc] init];
    NSMutableArray *propertyModelArray = [[NSMutableArray alloc] initWithCapacity:32];
    __unsafe_unretained XZHClassModel *clsModel = [XZHClassModel classModelWithClass:selfClass];
    while (clsModel && clsModel.superCls != nil) {
        for (__unsafe_unretained XZHPropertyModel *proModel in clsModel.propertyMap.allValues) {
            if (!proModel.name) {continue;}
            if (!proModel.setter || !proModel.getter) {continue;}
            [propertyModelArray addObject:proModel];
            clsModel = clsModel.superClassModel;
        }
    }
    
    // 遍历Class's所有的属性，依次继续拷贝所有的Ivar值
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
            id value = ((id (*)(id, SEL))(void *) objc_msgSend)(self, getter);
            if (!value) {break;}
            
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

- (BOOL)xzh_isEqulToObject:(id)object {
    if (!object) {return NO;}
    if ([object class] != [self class]) return NO;
    if ([object xzh_hash] != [self xzh_hash]) return NO;
    
    NSMutableArray *propertyModelArray = [[NSMutableArray alloc] initWithCapacity:32];
    __unsafe_unretained XZHClassModel *clsModel = [XZHClassModel classModelWithClass:[self class]];
    while (clsModel && clsModel.superCls != nil) {
        for (__unsafe_unretained XZHPropertyModel *proModel in clsModel.propertyMap.allValues) {
            if (!proModel.name) {continue;}
            if (!proModel.setter || !proModel.getter) {continue;}
            [propertyModelArray addObject:proModel];
            clsModel = clsModel.superClassModel;
        }
    }
    for (XZHPropertyModel *proM in propertyModelArray) {
        SEL getter = proM.getter;
        if (proM.isCNumber) {
            switch (proM.typeEncoding & XZHTypeEncodingDataTypeMask) {
                case XZHTypeEncodingChar: {//char、int8_t
                    char num1 = ((char (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    char num2 = ((char (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                    if (num1 != num2) return NO;
                }
                    break;
                case XZHTypeEncodingUnsignedChar: {//unsigned char、uint8_t
                    unsigned char num1 = ((unsigned char (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    unsigned char num2 = ((unsigned char (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                    if (num1 != num2) return NO;
                }
                    break;
                case XZHTypeEncodingBOOL: {
                    BOOL num1 = ((BOOL (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    BOOL num2 = ((BOOL (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                    if (num1 != num2) return NO;
                }
                    break;
                case XZHTypeEncodingShort: {//short、int16_t、
                    short num1 = ((short (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    short num2 = ((short (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                    if (num1 != num2) return NO;
                }
                    break;
                case XZHTypeEncodingUnsignedShort: {//unsigned short、uint16_t、
                    unsigned short num1 = ((unsigned short (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    unsigned short num2 = ((unsigned short (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                    if (num1 != num2) return NO;
                }
                    break;
                case XZHTypeEncodingInt: {//int、int32_t、
                    int num1 = ((int (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    int num2 = ((int (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                    if (num1 != num2) return NO;
                }
                    break;
                case XZHTypeEncodingUnsignedInt: {//unsigned int、uint32_t
                    unsigned int num1 = ((unsigned int (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    unsigned int num2 = ((unsigned int (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                    if (num1 != num2) return NO;
                }
                    break;
                case XZHTypeEncodingFloat: {
                    float num1 = ((float (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    float num2 = ((float (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                    if (num1 != num2) return NO;
                }
                    break;
                case XZHTypeEncodingLong32: {
                    long num1 = ((long (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    long num2 = ((long (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                    if (num1 != num2) return NO;
                }
                    break;
                case XZHTypeEncodingLongLong: {
                    long long num1 = ((long long (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    long long num2 = ((long long (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                    if (num1 != num2) return NO;
                }
                    break;
                case XZHTypeEncodingLongDouble: {
                    double num1 = ((long double (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    double num2 = ((long double (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                    if (num1 != num2) return NO;
                }
                    break;
                case XZHTypeEncodingUnsignedLong: {
                    unsigned long num1 = ((unsigned long (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    unsigned long num2 = ((unsigned long (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                    if (num1 != num2) return NO;
                }
                    break;
                case XZHTypeEncodingUnsignedLongLong: {
                    unsigned long long num1 = ((unsigned long long (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    unsigned long long num2 = ((unsigned long long (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                    if (num1 != num2) return NO;
                }
                    break;
                case XZHTypeEncodingDouble: {
                    double num1 = ((double (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    double num2 = ((double (*)(id, SEL))(void *) objc_msgSend)(object, getter);
                    if (num1 != num2) return NO;
                }
                    break;
                default:
                    break;
            }
        } else if (XZHFoundationTypeNone != proM.foundationType) {
            id obj1 = ((id (*)(id, SEL))(void *) objc_msgSend)(self, getter);
            id obj2 = ((id (*)(id, SEL))(void *) objc_msgSend)(object, getter);
            if (XZHFoundationTypeCustomer == proM.foundationType) {
                if (NO == [obj1 xzh_isEqulToObject:obj2]) {
                    return NO;
                }
            } else {
                switch (proM.foundationType) {
                    case XZHFoundationTypeNSString:
                    case XZHFoundationTypeNSMutableString: {
                        if (NO == [obj1 isEqualToString:obj2]) {return NO;}
                        break;
                    }
                    case XZHFoundationTypeNSNumber:
                    case XZHFoundationTypeNSDecimalNumber: {
                        if (NO == [obj1 isEqualToNumber:obj2]) {return NO;}
                        break;
                    }
                    case XZHFoundationTypeNSURL: {
                        if (NO == [[obj1 absoluteString] isEqualToString:[obj2 absoluteString]]) {return NO;}
                        break;
                    }
                    case XZHFoundationTypeNSArray:
                    case XZHFoundationTypeNSMutableArray: {
                        if (NO == [obj1 isEqualToArray:obj2]) {return NO;}
                        break;
                    }
                    case XZHFoundationTypeNSSet:
                    case XZHFoundationTypeNSMutableSet: {
                        if (NO == [obj1 isEqualToSet:obj2]) {return NO;}
                        break;
                    }
                    case XZHFoundationTypeNSDictionary:
                    case XZHFoundationTypeNSMutableDictionary: {
                        if (NO == [obj1 isEqualToDictionary:obj2]) {return NO;}
                        break;
                    }
                    case XZHFoundationTypeNSValue: {
                        if (NO == [obj1 isEqualToValue:obj2]) {return NO;}
                        break;
                    }
                    default:
                        break;
                }
            }
        }
    }
    return YES;
}

- (NSUInteger)xzh_hash {
    if ((id)kCFNull == self) {return [self hash];}
    __unsafe_unretained XZHClassModel *clsModel = [XZHClassModel classModelWithClass:[self class]];
    if (clsModel.foundationType != XZHFoundationTypeNone && clsModel.foundationType != XZHFoundationTypeCustomer) {return [self hash];}
    
    NSUInteger _hash = 0;
    NSMutableArray *propertyModelArray = [[NSMutableArray alloc] initWithCapacity:32];
    while (clsModel && clsModel.superCls != nil) {
        for (__unsafe_unretained XZHPropertyModel *proModel in clsModel.propertyMap.allValues) {
            if (!proModel.name) {continue;}
            if (!proModel.setter || !proModel.getter) {continue;}
            [propertyModelArray addObject:proModel];
            clsModel = clsModel.superClassModel;
        }
    }
    if (0 == propertyModelArray.count) {return (long)((__bridge void *)self);}
    
    for (XZHPropertyModel *proM in propertyModelArray) {
        SEL getter = proM.getter;
        if (proM.isCNumber) {
            switch (proM.typeEncoding & XZHTypeEncodingDataTypeMask) {
                case XZHTypeEncodingChar: {//char、int8_t
                    char num1 = ((char (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    _hash ^= num1;
                }
                    break;
                case XZHTypeEncodingUnsignedChar: {//unsigned char、uint8_t
                    unsigned char num1 = ((unsigned char (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    _hash ^= num1;
                }
                    break;
                case XZHTypeEncodingBOOL: {
                    BOOL num1 = ((BOOL (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    _hash ^= num1;
                }
                    break;
                case XZHTypeEncodingShort: {//short、int16_t、
                    short num1 = ((short (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    _hash ^= num1;
                }
                    break;
                case XZHTypeEncodingUnsignedShort: {//unsigned short、uint16_t、
                    unsigned short num1 = ((unsigned short (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    _hash ^= num1;
                }
                    break;
                case XZHTypeEncodingInt: {//int、int32_t、
                    int num1 = ((int (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    _hash ^= num1;
                }
                    break;
                case XZHTypeEncodingUnsignedInt: {//unsigned int、uint32_t
                    unsigned int num1 = ((unsigned int (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    _hash ^= num1;
                }
                    break;
                case XZHTypeEncodingFloat: {
                    float num1 = ((float (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    _hash ^= (int)num1;
                }
                    break;
                case XZHTypeEncodingLong32: {
                    long num1 = ((long (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    _hash ^= num1;
                }
                    break;
                case XZHTypeEncodingLongLong: {
                    long long num1 = ((long long (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    _hash ^= num1;
                }
                    break;
                case XZHTypeEncodingLongDouble: {
                    double num1 = ((long double (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    _hash ^= (int)num1;
                }
                    break;
                case XZHTypeEncodingUnsignedLong: {
                    unsigned long num1 = ((unsigned long (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    _hash ^= num1;
                }
                    break;
                case XZHTypeEncodingUnsignedLongLong: {
                    unsigned long long num1 = ((unsigned long long (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    _hash ^= num1;
                }
                    break;
                case XZHTypeEncodingDouble: {
                    double num1 = ((double (*)(id, SEL))(void *) objc_msgSend)(self, getter);
                    _hash ^= (int)num1;
                }
                    break;
                default:
                    break;
            }
        } else if (XZHFoundationTypeNone != proM.foundationType) {
            id obj1 = ((id (*)(id, SEL))(void *) objc_msgSend)(self, getter);
            if (XZHFoundationTypeCustomer == proM.foundationType) {
                _hash ^= [obj1 xzh_hash];
            } else {
                _hash ^= [obj1 hash];
            }
        }
    }
    return _hash;
}

- (NSString *)xzh_description {
    return XZHGetObjectDescription(self);
}

@end
