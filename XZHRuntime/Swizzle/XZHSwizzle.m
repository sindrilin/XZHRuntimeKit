//
//  XZHSwizzle.m
//  XZHRuntimeDemo
//
//  Created by fenqile on 16/11/29.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import "XZHSwizzle.h"
#import <objc/runtime.h>

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