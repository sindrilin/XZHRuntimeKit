//
//  NSObject+XZHInvocation.h
//  XZHRuntimeDemo
//
//  Created by fenqile on 16/11/29.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (XZHInvocation)

- (id)xzh_performSelector:(SEL)aSelector withArgs:(NSArray*)args;

@end
