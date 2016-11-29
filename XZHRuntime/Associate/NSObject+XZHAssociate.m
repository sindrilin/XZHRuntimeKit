//
//  NSObject+XZHAssociate.m
//  XZHRuntimeDemo
//
//  Created by fenqile on 16/11/29.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import "NSObject+XZHAssociate.h"
#import <objc/runtime.h>

static const void* _computeKeyFromString(id target, NSString *nsKey) {
    return (char*)((__bridge void *)target) + [nsKey hash] + [nsKey characterAtIndex:0] + [nsKey characterAtIndex:nsKey.length-1];
}

@implementation NSObject (XZHAssociate)

-(void)xzh_attachObject:(id)obj forKey:(NSString *)nsKey {
    if (nsKey.length > 0) {
        const void* computedKey = _computeKeyFromString(self, nsKey);
        objc_setAssociatedObject(self, computedKey, obj, OBJC_ASSOCIATION_RETAIN);
    }
}

-(id)xzh_getAttachedObjectForKey:(NSString *)nsKey {
    if (nsKey.length <= 0) {
        return nil;
    }
    const void* computedKey = _computeKeyFromString(self, nsKey);
    return objc_getAssociatedObject(self, computedKey);
}

-(void)xzh_detachObjectForKey:(NSString *)nsKey {
    if (nsKey.length > 0) {
        const void* computedKey = _computeKeyFromString(self, nsKey);
        objc_setAssociatedObject(self, computedKey, nil, OBJC_ASSOCIATION_RETAIN);
    }
}

-(void)xzh_removeAssociatedObjects {
    objc_removeAssociatedObjects(self);
}

@end
