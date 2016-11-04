//
//  NSObject+XZHJSONMapping.h
//  XZHRuntimeDemo
//
//  Created by XiongZenghui on 16/9/11.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  是否需要使用默认值处理
 *
 *  @return YES会给属性Ivar填充默认值，NO则不会。
 */
void xzh_setNoNeedDefaultJSONValueHandle();

@interface NSObject (XZHJSONMappingTools)

// JSON String/JSON Data/JSON Dictionary/Array JSON
- (instancetype)xzh_modelFromObject:(id)obj;
+ (instancetype)xzh_modelFromObject:(id)obj;
+ (instancetype)_xzh_modelFromJSONDictionary:(NSDictionary *)jsonDic;

- (instancetype)xzh_modelToJSONObject;
- (NSDictionary *)xzh_modelToJSONDictionary;
- (instancetype)xzh_modelToJSONString;
- (instancetype)xzh_modelToJSONData;

@end

/**
 *  选择性实现该协议的方法
 */
@protocol XZHJSONMappingConfig
@optional
/**
 *  定制属性名与json key的映射
 *  eg、{属性名 : jsonKey}
 */
+ (NSDictionary *)xzh_customerPropertyNameMappingJSONKey;

/**
 *  不被映射的json key
 */
+ (NSArray *)xzh_ignoreMappingJSONKeys;

/**
 *  指定对应的dictionary映射某个类型class
 */
+ (Class)xzh_classForDictionary:(NSDictionary *)dic;

/**
 *  返回数组元素中对象的类型
 *  eg1、@{@"属性名" : @"Dog"}
 *  eg2、@{@"属性名" : Dog.class}
 */
+ (NSDictionary *)xzh_classInArray;

/**
 *  解析日期字符串的格式
 */
+ (NSString *)xzh_dateFormat;

@end

