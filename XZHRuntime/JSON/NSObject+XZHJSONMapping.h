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

/**
 *  1) JSON String、JSON Data、JSON Dictionary、Array JSON >>> model、model array
 *  2) model >>> json、json字符串、json data、字典
 */
@interface NSObject (XZHJSONModelMapping)

/**
 *  json to model:
 *  - (1) @param JSON NSDictioanry
 *  - (2) @param JSON NSString
 *  - (3) @param JSON NSData
 *  - (4) @param JSON Array
 *
 *  (2)、(3)、(4) >>>> (1)
 */

+ (instancetype)xzh_modelFromObject:(id)obj;
+ (instancetype)xzh_modelFromJSONDictionary:(NSDictionary *)jsonDic;
+ (instancetype)xzh_modelFromJSONString:(NSString *)jsonString;
+ (instancetype)xzh_modelFromJSONData:(NSData *)jsonData;

/**
 *  model to json obejct:
 *  - (1) @return NSDictionary、NSArray
 *  - (2) @return NSData
 *  - (3) @return NSString
 *
 *  (3) >>> (2) >>> (1)
 */

- (instancetype)xzh_modelToJSONObject;
- (instancetype)xzh_modelToJSONString;
- (instancetype)xzh_modelToJSONData;

@end

/**
 *  选择性实现如下方法，个性化配置json与model的映射规则:
 */
@protocol XZHJSONModelMappingRules
@optional
/**
 *  定制属性名与json key的映射
 *  eg、{属性名 : jsonKey}
 */
+ (NSDictionary *)xzh_customerMappings;

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
 *  返回解析日期字符串的格式
 */
+ (NSString *)xzh_dateFormat;

@end

