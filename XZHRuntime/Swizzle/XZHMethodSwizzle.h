//
//  XZHMethodSwizzle.h
//  XZHRuntimeDemo
//
//  Created by XiongZenghui on 16/10/18.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/**
 *  首先尝试交换对象方法实现，如果失败则再尝试交换类方法实现
 *
 *  @return YES表示交换成功
 */
BOOL XZHMethodSwizzle(Class cls, SEL origSEL, SEL newSEL);