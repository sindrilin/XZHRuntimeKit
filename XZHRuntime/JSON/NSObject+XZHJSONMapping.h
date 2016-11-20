//
//  NSObject+XZHJSONMapping.h
//  XZHRuntimeDemo
//
//  Created by XiongZenghui on 16/9/11.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (XZHJSONModelMapping)

/**
 *  json to model:
 *  - (1) @param JSON NSDictioanry
 *  - (2) @param JSON NSString
 *  - (3) @param JSON NSData
 *  - (4) @param JSON Array
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
 *  配置字典格式、@{属性名 : jsonKey}
 *
 *  支持属性映射jsonkey的类型:
 *  - (1) 简单的jsonkey或默认不配置的情况 >>> @{@"name" : @"name"}
 *  - (2) 属性映射另外一个不同的简单的jsonkey >>> @{@"name" : @"user_name"}
 *  - (3) 属性映射一个json keyPath >>> @{@"name" : @"user.account.name"}
 *  - (4) 属性映射多个json key，即映射一个json keyArray，情况如下:
 *      - @{@"name" : @[@"name1", @"name2", @"name3"]}
 *      - @{@"name" : @[@"name_1", @"user_name", @"u_name"]}
 *
 *  支持属性与jsonkey的映射关系:
 *  - (1) <1 属性 : 1 jsonkey>
 *  - (2) <1 属性 : n jsonkey>
 *  - (3) <n 属性 : 1 jsonkey>
 *
 *  注意: key值只支持NSString类型来表示属性名
 */
+ (NSDictionary *)xzh_customerMappings;

/**
 *  配置忽略被映射的json key
 */
+ (NSArray *)xzh_ignoreMappingJSONKeys;

/**
 *  如果属性类型是Array/Set/Dictionary时，实现此方法指定内部子对象的Class
 *  eg1、@{@"属性名" : @"Dog"}
 *  eg2、@{@"属性名" : Dog.class}
 *
 *  注意: key值只支持NSString类型来表示属性名
 */
+ (NSDictionary *)xzh_containerClass;

/**
 *  手动指定对应的json dictionary映射某个Class
 */
+ (Class)xzh_classForDictionary:(NSDictionary *)dic;

/**
 *  返回解析日期字符串的格式
 */
+ (NSString *)xzh_dateFormat;

@end