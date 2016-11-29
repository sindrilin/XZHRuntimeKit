//
//  NSObject+XZHAssociate.h
//  XZHRuntimeDemo
//
//  Created by fenqile on 16/11/29.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (XZHAssociate)

// 绑定一个对象
-(void)xzh_attachObject:(id)obj forKey:(NSString *)nsKey;

// 获取绑定的对象
-(id)xzh_getAttachedObjectForKey:(NSString *)nsKey;

// 将绑定的对象设置nil进行清空
-(void)xzh_detachObjectForKey:(NSString *)nsKey;

// 移除绑定的所有对象
-(void)xzh_removeAssociatedObjects;

@end
