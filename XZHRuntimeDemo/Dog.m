
//
//  Person.m
//  XZHRuntimeDemo
//
//  Created by xiongzenghui on 16/10/7.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import "Dog.h"
#import "NSObject+XZHJSONMapping.h"
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

@implementation Cat
+ (NSDictionary *)xzh_customerMappings {
    return @{
             // 属性 : json key
             @"cid" : @"c_id",
             @"name" : @"c_name",
             };
}
@end

@implementation Child
@end