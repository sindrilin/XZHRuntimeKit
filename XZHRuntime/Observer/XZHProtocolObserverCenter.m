//
//  XZHProtocolObserverCenter.m
//  XZHRuntimeDemo
//
//  Created by fenqile on 16/12/1.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import "XZHProtocolObserverCenter.h"
#import <objc/runtime.h>
#import "NSObject+XZHInvocation.h"

static NSString const *kMethodName                  = @"methodName";
static NSString const *kMethodType                  = @"methodType";
//static NSString const *kMethodArgumentType          = @"methodArgumentType";
//static NSString const *kMethodReturnType            = @"methodReturnType";

static dispatch_semaphore_t parse_protocol_semephore;
NSArray *XZHGetMethodListForProtocol(Protocol *protocol) {
    if (!protocol) {return nil;}
    if (protocol_isEqual(protocol, @protocol(NSObject))) {return nil;}//>>>> 过滤掉NSObject根协议的method解析
    
    static dispatch_once_t onceToken;
    static NSMutableDictionary *_cache;
    dispatch_once(&onceToken, ^{
        _cache = [NSMutableDictionary new];
        parse_protocol_semephore = dispatch_semaphore_create(1);
    });
    
    NSMutableArray *methods = nil;
    dispatch_semaphore_wait(parse_protocol_semephore, DISPATCH_TIME_FOREVER);
    methods = [_cache objectForKey:NSStringFromProtocol(protocol)];
    dispatch_semaphore_signal(parse_protocol_semephore);
    if (methods) {
        return methods;
    }
    
    methods = [NSMutableArray new];
    unsigned int count = 0;
    Protocol *__unsafe_unretained *superProtocols = protocol_copyProtocolList(protocol, &count);
    if (superProtocols != NULL && count > 0) {
        for (unsigned int index = 0; index < count; index++) {
            NSArray * superMethods = XZHGetMethodListForProtocol(superProtocols[index]);
            if (superMethods) {[methods addObjectsFromArray:superMethods];}
        }
        free(superProtocols);
    }
    
    unsigned int optionalCount = 0;
    struct objc_method_description* optionalMethods = protocol_copyMethodDescriptionList(protocol, NO, YES, &optionalCount);
    if (optionalMethods != NULL && optionalCount > 0) {
        for(unsigned i = 0; i < optionalCount; i++) {
            NSString *methodName = NSStringFromSelector(optionalMethods[i].name);
            NSString *methodTypes = [NSString stringWithCString:optionalMethods[i].types encoding:[NSString defaultCStringEncoding]];
            NSDictionary *dic = @{
                                  kMethodName : ((methodName != nil) ? methodName : @""),
                                  kMethodType : ((methodTypes != nil) ? methodTypes : @""),
                                  };
            [methods addObject:dic];
        }
        free(optionalMethods);
    }
    
    unsigned int requiredCount = 0;
    struct objc_method_description* requiredMethods = protocol_copyMethodDescriptionList(protocol, YES, YES, &requiredCount);
    if (requiredMethods != NULL && requiredCount > 0) {
        for(unsigned i = 0; i < requiredCount; i++) {
            NSString *methodName = NSStringFromSelector(requiredMethods[i].name);
            NSString *methodTypes = [NSString stringWithCString:requiredMethods[i].types encoding:[NSString defaultCStringEncoding]];
            NSDictionary *dic = @{
                                  kMethodName : ((methodName != nil) ? methodName : @""),
                                  kMethodType : ((methodTypes != nil) ? methodTypes : @""),
                                  };
            [methods addObject:dic];
        }
        free(requiredMethods);
    }
    
    methods = methods.copy;
    dispatch_semaphore_wait(parse_protocol_semephore, DISPATCH_TIME_FOREVER);
    [_cache setObject:methods forKey:NSStringFromProtocol(protocol)];
    dispatch_semaphore_signal(parse_protocol_semephore);
    
    return methods;
}

@interface XZHProtocolObserver : NSObject {
    @package
    id          _observer;
    __unsafe_unretained Protocol    *_protocol;
    
    NSUInteger  _methodCnt;
    NSArray     *_methods;
}
@end
@implementation XZHProtocolObserver
- (instancetype)initWithObserver:(id)observer protocol:(Protocol *)protocol {
    if (!observer || !protocol) {return nil;}
    if (self = [super init]) {
        _observer = observer;
        _protocol = protocol;
        _methods = XZHGetMethodListForProtocol(protocol);
        _methodCnt = _methods.count;
    }
    return self;
}
@end

static dispatch_semaphore_t context_semephore = NULL;
@interface XZHProtocolObserverContext : NSObject {
    /**
     *  key >>>> method.name
     *  value >>>> @[observer1, observer2, observer3, ..., observerN]
     */
    NSMutableDictionary *_cache;
}
@end
@implementation XZHProtocolObserverContext
+ (instancetype)context {
    static XZHProtocolObserverContext *_context = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _context = [XZHProtocolObserverContext new];
        _context->_cache = [NSMutableDictionary new];
        context_semephore = dispatch_semaphore_create(1);
    });
    return _context;
}
- (void)saveObserver:(id)object forProtocol:(Protocol *)protocol {
    if (!object || !protocol) {return;}
    __unsafe_unretained NSArray *methods = XZHGetMethodListForProtocol(protocol);
    dispatch_semaphore_wait(parse_protocol_semephore, DISPATCH_TIME_FOREVER);
    for (NSDictionary *methodDic in methods) {
        NSString *methodName = [methodDic objectForKey:kMethodName];
        NSMutableArray *observers = [_cache objectForKey:methodName];
        if (!observers) {
            observers = [NSMutableArray new];
            [observers addObject:object];
        }
        if (![observers containsObject:object]) {
            [observers addObject:object];
        }
        [_cache setObject:observers forKey:methodName];
    }
    dispatch_semaphore_signal(parse_protocol_semephore);
}
/**
 *  返回的dic结构
 *  @{
 *      method1 : @[observer1, observer2, observer3],
 *      method2 : @[observer1, observer2, observer3];
 *   }
 */
- (NSDictionary *)getObjectForProtocol:(Protocol *)protocol {
    if (!protocol) {return nil;}
    NSMutableDictionary *allObservers = [NSMutableDictionary new];
    __unsafe_unretained NSArray *methods = XZHGetMethodListForProtocol(protocol);
    dispatch_semaphore_wait(parse_protocol_semephore, DISPATCH_TIME_FOREVER);
    for (NSDictionary *methodDic in methods) {
        NSString *methodName = [methodDic objectForKey:kMethodName];
        NSArray *observers = [_cache objectForKey:methodName];
        if (observers) {
            [allObservers setObject:observers forKey:methodName];
        }
    }
    dispatch_semaphore_signal(parse_protocol_semephore);
    return allObservers.copy;
}
- (void)removeObjectForProtocol:(Protocol *)protocol {
    [self removeObject:nil forProtocol:protocol];
}
- (void)removeObject:(id)object forProtocol:(Protocol *)protocol {
    if (!protocol) {return;}
    __unsafe_unretained NSArray *methods = XZHGetMethodListForProtocol(protocol);
    dispatch_semaphore_wait(parse_protocol_semephore, DISPATCH_TIME_FOREVER);
    for (NSDictionary *methodDic in methods) {
        NSString *methodName = [methodDic objectForKey:kMethodName];
        if (!object) {
            [_cache removeObjectForKey:methodName];
        } else {
            NSMutableArray *observers = [_cache objectForKey:methodName];
            [observers removeObject:object];
            [_cache setObject:observers forKey:methodName];
        }
    }
    dispatch_semaphore_signal(parse_protocol_semephore);
}
- (void)clean {
    dispatch_semaphore_wait(parse_protocol_semephore, DISPATCH_TIME_FOREVER);
    [_cache removeAllObjects];
    dispatch_semaphore_signal(parse_protocol_semephore);
}
@end

static XZHProtocolObserverCenter *_centerInstance;
@implementation XZHProtocolObserverCenter

+ (instancetype)observerCenter {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _centerInstance = [[XZHProtocolObserverCenter alloc] init];
    });
    return _centerInstance;
}

- (void)addObserver:(id)observer forProtocol:(Protocol *)protocol {
    if (![observer conformsToProtocol:protocol]) {return;}
    if (protocol_isEqual(protocol, @protocol(NSObject))) {return;}
    [[XZHProtocolObserverContext context] saveObserver:observer forProtocol:protocol];
}

- (void)notifyObserversForProtocol:(Protocol *)protocol selector:(SEL)sel arguments:(NSArray*)args {
    if (!protocol || !sel) {return;}
    NSDictionary *map = [[XZHProtocolObserverContext context] getObjectForProtocol:protocol];
    NSArray *observers = [map objectForKey:NSStringFromSelector(sel)];
    for (id observer in observers) {
        [observer xzh_performSelector:sel withArgs:args];
    }
}

- (void)removeObserver:(id)observer forProtocol:(Protocol *)protocol {
    if (!protocol) {return;}
    [[XZHProtocolObserverContext context] removeObject:observer forProtocol:protocol];
}

- (void)removeObserverForProtocol:(Protocol *)protocol {
    [[XZHProtocolObserverContext context] removeObjectForProtocol:protocol];
}

- (void)clean {
    [[XZHProtocolObserverContext context] clean];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _centerInstance = [super allocWithZone:zone];
    });
    return _centerInstance;
}

- (id)copyWithZone:(NSZone *)zone {
    return _centerInstance;
}

@end
