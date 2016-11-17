//
//  NSObject+XZHAdditions.m
//  XZHRuntimeDemo
//
//  Created by xiongzenghui on 16/11/17.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import "NSObject+XZHAdditions.h"
#import <objc/runtime.h>

@implementation NSObject (XZHAdditions)

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

-(const void*)xzh_computeKeyFromString:(NSString*)nsKey {
    return (char*)((__bridge void *)self) + [nsKey hash] + [nsKey characterAtIndex:0] + [nsKey characterAtIndex:nsKey.length-1];
}

-(void)xzh_attachObject:(id)obj forKey:(NSString *)nsKey {
    if (nsKey.length > 0) {
        const void* computedKey = [self xzh_computeKeyFromString:nsKey];
        objc_setAssociatedObject(self, computedKey, obj, OBJC_ASSOCIATION_RETAIN);
    }
}

-(id)xzh_getAttachedObjectForKey:(NSString *)nsKey {
    if (nsKey.length <= 0) {
        return nil;
    }
    const void* computedKey = [self xzh_computeKeyFromString:nsKey];
    return objc_getAssociatedObject(self, computedKey);
}

-(void)xzh_detachObjectForKey:(NSString *)nsKey {
    if (nsKey.length > 0) {
        const void* computedKey = [self xzh_computeKeyFromString:nsKey];
        objc_setAssociatedObject(self, computedKey, nil, OBJC_ASSOCIATION_RETAIN);
    }
}

-(void)xzh_removeAssociatedObjects {
    objc_removeAssociatedObjects(self);
}

@end

BOOL XZHMethodSwizzle(Class cls, SEL origSEL, SEL newSEL)
{
    Method origMethod = class_getInstanceMethod(cls, origSEL);
    Method newMethod = nil;
    if (!origMethod) {
        origMethod = class_getClassMethod(cls, origSEL);
        
        if (!origMethod) {
            return NO;
        }
        
        newMethod = class_getClassMethod(cls, newSEL);
        if (!newMethod) {
            return NO;
        }
        
    }else{
        newMethod = class_getInstanceMethod(cls, newSEL);
        if (!newMethod) {
            return NO;
        }
    }
    
    /**
     * 这里有一个注意的问题 >>> 要交换的方法有两种情况:
     * >>> 情况一、被替换的函数实现，没有出现在当前类/对象，而是出现在当前类的`父类`，也就是当前类中并未重写.（当前类/对象不存在实现）
     * >>> 情况二、被替换的函数实现，是继承自`父类`，但是已经在当前类重写.（当前类/对象存在实现）
     * >>> 情况三、是当前类/对象自己的函数，并不是继承过来的.（当前类/对象存在实现）
     */
    if(class_addMethod(cls, origSEL, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        //情况一
        class_replaceMethod(cls, newSEL, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        //情况二、情况三
        method_exchangeImplementations(origMethod, newMethod);
    }
    return YES;
}