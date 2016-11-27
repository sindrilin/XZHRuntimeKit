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

// 浅拷贝对象
- (instancetype)xzh_copy;

// 深拷贝对象
- (instancetype)xzh_deepCopy;

- (BOOL)xzh_isEqulToObject:(id)object;

- (NSUInteger)xzh_hash;

- (NSString *)xzh_description;


@end
