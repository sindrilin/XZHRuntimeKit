//
//  NSObject+XZHInvocation.m
//  XZHRuntimeDemo
//
//  Created by fenqile on 16/11/29.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import "NSObject+XZHInvocation.h"
#import <objc/runtime.h>

@implementation NSObject (XZHInvocation)

- (id)xzh_performSelector:(SEL)aSelector withObjects:(id)object, ... {
    NSMethodSignature *signature = [self methodSignatureForSelector:aSelector];
    if (!signature) {return nil;}
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:self];
    [invocation setSelector:aSelector];
    
    NSInteger index = 2;// self、_cmd
    
    va_list args;
    va_start(args, object);
    [invocation setArgument:&object atIndex:index++];
    
    id arg = nil;
    while ((arg = va_arg(args, id))) {
        [invocation setArgument:&arg atIndex:index++];
        index++;
    }
    
    va_end(args);
    
    [invocation invoke];
    if (signature.methodReturnLength) {
        id anObject;
        [invocation getReturnValue:&anObject];
        return anObject;
    }
    
    return nil;
}

@end
