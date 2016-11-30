//
//  NSObject+XZHArchived.m
//  XZHRuntimeDemo
//
//  Created by XiongZenghui on 16/10/18.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import "NSObject+XZHArchived.h"
#import "XZHRuntime.h"

static NSString *const kXZHAutocodingException = @"XZHAutocodingException";

@implementation NSObject (XZHArchived)

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)xzh_encodeWithCoder:(NSCoder *)aCoder {
    NSMutableArray *propertyModelArray = [[NSMutableArray alloc] initWithCapacity:32];
    __unsafe_unretained XZHClassModel *clsModel = [XZHClassModel classModelWithClass:[self class]];
    while (clsModel && clsModel.superCls != nil) {
        for (__unsafe_unretained XZHPropertyModel *propertyModel in clsModel.propertyMap.allValues) {
            if (!propertyModel.name) {continue;}
            if (!propertyModel.setter || !propertyModel.getter) {continue;}
            [propertyModelArray addObject:propertyModel];
        }
        clsModel = clsModel.superClassModel;
    }
    for (__unsafe_unretained XZHPropertyModel *proM in propertyModelArray) {
        id object = [self valueForKey:proM.name];
        if (object) [aCoder encodeObject:object forKey:proM.name];
    }
}

- (nullable instancetype)xzh_initWithCoder:(NSCoder *)aDecoder {
    BOOL secureAvailable = [aDecoder respondsToSelector:@selector(decodeObjectOfClass:forKey:)];
    BOOL secureSupported = [[self class] supportsSecureCoding];
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

    for (__unsafe_unretained XZHPropertyModel *proM in propertyModelArray) {
        id object = nil;
        Class propertyClass = proM.isCNumber ? [NSNumber class] : proM.cls;
        if (secureAvailable) {
            object = [aDecoder decodeObjectOfClass:propertyClass forKey:proM.name];
        } else {
            object = [aDecoder decodeObjectForKey:proM.name];
        }
        if (object) {
            if (secureSupported && ![object isKindOfClass:propertyClass] && object != [NSNull null]) {
                [NSException raise:kXZHAutocodingException format:@"Expected '%@' to be a %@, but was actually a %@", proM.name, propertyClass, [object class]];
            }
            [self setValue:object forKey:proM.name];
        }
    }
    return self;
}

- (BOOL)xzh_writeToFile:(NSString *)filePath atomically:(BOOL)useAuxiliaryFile {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    return [data writeToFile:filePath atomically:useAuxiliaryFile];
}

+ (instancetype)xzh_loadWithContentsOfFile:(NSString *)filePath {
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    id object = nil;
    if (data) {
        NSPropertyListFormat format;
        object = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:&format error:NULL];
        if (object) {
            //check if object is an NSCoded unarchive
            if ([object respondsToSelector:@selector(objectForKeyedSubscript:)] && ((NSDictionary *)object)[@"$archiver"]) {
                object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            }
        } else {
            //return raw data
            object = data;
        }
    }
    return object;
}

@end
