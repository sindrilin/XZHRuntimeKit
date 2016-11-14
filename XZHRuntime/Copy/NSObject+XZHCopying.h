//
//  NSObject+XZHCopying.h
//  XZHRuntimeDemo
//
//  Created by XiongZenghui on 16/10/9.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  深拷贝、不可变版本对象
 */
@protocol XZHDeepCopying <NSObject>
- (instancetype)xzh_deepCopyWithNoZone;
@end

/**
 *  深拷贝、可变版本对象
 */
@protocol XZHDeepMutableCopying <NSObject>
- (instancetype)xzh_deepMutableCopyWithNoZone;
@end

@interface NSObject (XZHCopying)

///////////////////////////////////////////////////////////////////
///// 浅拷贝、可变与不可变
///////////////////////////////////////////////////////////////////
- (instancetype)xzh_copy;
- (instancetype)xzh_mutableCopy;

///////////////////////////////////////////////////////////////////
///// 深拷贝、可变与不可变
///////////////////////////////////////////////////////////////////
- (instancetype)xzh_deepCopy;
- (instancetype)xzh_deepMutablCopy;

@end
