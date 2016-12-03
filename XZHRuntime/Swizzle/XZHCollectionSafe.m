//
//  XZHCollectionSafe.m
//  Demo
//
//  Created by xiongzenghui on 16/12/3.
//  Copyright © 2016年 xiongzenghui. All rights reserved.
//

#import "XZHCollectionSafe.h"
#import "XZHSwizzle.h"

@implementation UIView (XZHSafeRuntime)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        XZHMethodSwizzle([UIView class], @selector(addSubview:), @selector(xzh_addSubview:));
    });
}

- (void)xzh_addSubview:(UIView *)view {
    if (!view) {
        return;
    }
    [self xzh_addSubview:view];
}

@end

@implementation NSArray (XZHSafeRuntime)

/**
 *  __NSArray0、__NSArrayI
 */
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //        不要交换 __NSArray0，否则启动崩溃，不知道如何拦截 __NSArray0 实现
        //        id arr1 = [NSArray array];//@[]
        //        Swizzle([arr1 class], @selector(objectAtIndex:), @selector(xzh_objectAtIndex:));
        //        Swizzle([arr1 class], @selector(objectAtIndexedSubscript:), @selector(xzh_objectAtIndexedSubscript:));
        
        id arr2 = [NSArray arrayWithObjects:@"1", nil];
        XZHMethodSwizzle([arr2 class], @selector(objectAtIndex:), @selector(xzh_objectAtIndex:));
        XZHMethodSwizzle([arr2 class], @selector(objectAtIndexedSubscript:), @selector(xzh_objectAtIndexedSubscript:));
    });
}

- (id)xzh_objectAtIndex:(NSUInteger)index {
    if ((index >= self.count) || (self.count < 1)) {
        NSLog(@"XZHSafe: index overflow array count");
        return nil;
    }
    return [self xzh_objectAtIndex:index];
}

- (id)xzh_objectAtIndexedSubscript:(NSUInteger)index {
    if ((index >= self.count) || (self.count < 1)) {
        NSLog(@"XZHSafe: index overflow array count");
        return nil;
    }
    return [self xzh_objectAtIndex:index];
}

@end

@implementation NSMutableArray (XZHSafeRuntime)

/**
 *  __NSArrayM
 */
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        id arr = [NSMutableArray array];
        XZHMethodSwizzle([arr class], @selector(setObject:atIndexedSubscript:), @selector(xzh_setObject:atIndexedSubscript:));
        XZHMethodSwizzle([arr class], @selector(addObject:), @selector(xzh_addObject:));
    });
}

- (void)xzh_setObject:(id)obj atIndexedSubscript:(NSUInteger)idx {
    if (!obj) {
        NSLog(@"XZHSafe: attempt set nil into array");
        return;
    }
    [self xzh_setObject:obj atIndexedSubscript:idx];
}

- (void)xzh_addObject:(id)anObject {
    if (!anObject) {
        NSLog(@"XZHSafe: attempt set nil into array");
        return;
    }
    [self xzh_addObject:anObject];
}

@end

@implementation NSMutableDictionary (XZHSafeRuntime)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        id dic = [NSMutableDictionary dictionary];
        XZHMethodSwizzle([dic class], @selector(setObject:forKey:), @selector(xzh_setObject:forKey:));
        XZHMethodSwizzle([dic class], @selector(setObject:forKeyedSubscript:), @selector(xzh_setObject:forKeyedSubscript:));
    });
}

- (void)xzh_setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    if (!aKey) {
        NSLog(@"XZHSafe: attempt set nil into dic");
        return;
    }
    //    if (!anObject) {
    //        anObject = [NSNull null];
    //    }
    [self xzh_setObject:anObject forKey:aKey];
}

- (void)xzh_setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key {
    if (!key) {
        NSLog(@"XZHSafe: attempt set nil into dic");
        return;
    }
    //    if (!obj) {
    //        obj = [NSNull null];
    //    }
    [self xzh_setObject:obj forKeyedSubscript:key];
}

@end
