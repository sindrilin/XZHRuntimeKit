//
//  NSObject+XZHCopying.h
//  XZHRuntimeDemo
//
//  Created by XiongZenghui on 16/10/9.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (XZHCopying)

- (instancetype)xzh_copy;
- (instancetype)xzh_deepCopy;

@end
