//
//  XZHProtocolObserverCenter.h
//  XZHRuntimeDemo
//
//  Created by fenqile on 16/12/1.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  递归遍历获取Protocol中定义的所有的objc_method
 *
 *  NSObejct(过滤掉)
 *      - Protocol1
 *          - Protocol2
 *              - Protocol3
 *
 *  Protocol1的method
 *      - method1
 *      - method2
 *
 *  Protocol2的method
 *      - method3
 *
 *  Protocol3的method
 *      - method4
 *      - method5
 *
 *  该方法最后输出得到methods = @[method1, method2, method3, method4, method5];
 */
NSArray *XZHGetMethodListForProtocol(Protocol *protocol);

@interface XZHProtocolObserverCenter : NSObject

+ (instancetype)observerCenter;

/**
 *  给对象注册要关注的Protocol
 *  【注意】该对象的所属类必须要显示的声明要实现的Protocol，否则不会注册。因为内部调用 conformsToProtocol: 。 
 */
- (void)addObserver:(id)observer forProtocol:(Protocol *)protocol;

/**
 *  因为主要是用来通知关注Protocol的`所有对象`执行回调，所以这里不处理返回值的情况
 */
- (void)notifyObserversForProtocol:(Protocol *)protocol selector:(SEL)sel arguments:(NSArray*)args;

- (void)removeObserver:(id)observer forProtocol:(Protocol *)protocol;

- (void)removeObserverForProtocol:(Protocol *)protocol;

- (void)clean;

@end
