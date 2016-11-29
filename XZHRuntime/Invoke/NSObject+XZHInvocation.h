//
//  NSObject+XZHInvocation.h
//  XZHRuntimeDemo
//
//  Created by fenqile on 16/11/29.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (XZHInvocation)

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

@end
