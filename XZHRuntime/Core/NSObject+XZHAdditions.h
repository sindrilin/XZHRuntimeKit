//
//  NSObject+XZHAdditions.h
//  XZHRuntimeDemo
//
//  Created by xiongzenghui on 16/11/17.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  首先尝试交换对象方法实现，如果失败则再尝试交换类方法实现
 *
 *  @return YES表示交换成功
 */
BOOL XZHMethodSwizzle(Class cls, SEL origSEL, SEL newSEL);

@interface NSObject (XZHAdditions)

/**
 *  可以获取返回值的performSelector
 
 假设有如下OC函数:
 
 @implementation ViewController
 
 - (NSString *)haha:(NSString *)arg1 age:(NSInteger)age {
 return @"hahah";
 }
 
 使用方式:
 NSString *ret = [self xzh_performSelector:@selector(haha:age:) withObjects:@"name", @19, nil];
 
 */
- (id)xzh_performSelector:(SEL)aSelector withObjects:(id)object, ...;

// 绑定一个对象
-(void)xzh_attachObject:(id)obj forKey:(NSString *)nsKey;

// 获取绑定的对象
-(id)xzh_getAttachedObjectForKey:(NSString *)nsKey;

// 将绑定的对象设置nil进行清空
-(void)xzh_detachObjectForKey:(NSString *)nsKey;

// 移除绑定的所有对象
-(void)xzh_removeAssociatedObjects;

@end

