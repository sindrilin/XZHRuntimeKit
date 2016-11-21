//
//  NSObject+XZHCopying.h
//  XZHRuntimeDemo
//
//  Created by XiongZenghui on 16/10/9.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  提供objc对象的浅拷贝、深拷贝的功能
 *  可以不再实现NSCopying协议
 */
@interface NSObject (XZHCopying) 

/**
 *  浅拷贝对象
 */
- (instancetype)xzh_copy;

/**
 *  深拷贝对象
 */
- (instancetype)xzh_deepCopy;

@end
