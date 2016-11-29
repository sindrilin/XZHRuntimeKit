//
//  NSObject+XZHCopying.h
//  XZHRuntimeDemo
//
//  Created by XiongZenghui on 16/10/9.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  提供objc对象基础功能
 *  - 浅拷贝、深拷贝
 *  - 对象等同性判断
 *  - hash值
 *  - description
 */
@interface NSObject (XZHModel)

/**
 *  拷贝对象，可以不再需要实现NSCopying协议
 *  - 浅拷贝
 *  - 深拷贝
 */

- (instancetype)xzh_copy;
- (instancetype)xzh_deepCopy;

/**
 *  对象等他性判断
 */
- (BOOL)xzh_isEqulToObject:(id)object;

/**
 *  对象的hash值
 *  hash = ivar1 ^ ivar2 ^ ivar3 ^ ....;
 */
- (NSUInteger)xzh_hash;

/**
 *  对象的desciption描述字符串值
 */
- (NSString *)xzh_description;

@end
