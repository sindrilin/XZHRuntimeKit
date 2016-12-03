//
//  NSObject+XZHInvocation.m
//  XZHRuntimeDemo
//
//  Created by fenqile on 16/11/29.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import "NSObject+XZHInvocation.h"
#import "XZHRuntime.h"

@implementation NSObject (XZHInvocation)

- (id)xzh_performSelector:(SEL)aSelector withArgs:(NSArray*)args {
    if (NULL == aSelector) {return nil;}
    NSMethodSignature *signature = [self methodSignatureForSelector:aSelector];
    if (!signature) {return nil;}
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:self];
    [invocation setSelector:aSelector];
    
    if (args && args.count > 0) {
        NSUInteger numberOfArguments = signature.numberOfArguments;
        NSInteger count = MIN(numberOfArguments, args.count);
        
        for (int i = 0; i < count; i++) {
            const char *typeEncodingChars = [signature getArgumentTypeAtIndex:i+2];
            XZHTypeEncoding type = XZHGetTypeEncoding(typeEncodingChars) & XZHTypeEncodingDataTypeMask;
            if (XZHTypeEncodingsUnKnown == type) {continue;}
            
            id object = [args objectAtIndex:i];
            if ([object isKindOfClass:[NSNull class]]) {continue;}
            
            switch (type) {
                case XZHTypeEncodingFoundationObject: {
                    [invocation setArgument:&object atIndex:i+2];
                }
                    break;
                case XZHTypeEncodingChar: {
                    char value = 0;
                    if ([object isKindOfClass:[NSNumber class]]) {value = [(NSNumber*)object charValue];}
                    [invocation setArgument:&value atIndex:i+2];
                }
                    break;
                case XZHTypeEncodingUnsignedChar: {
                    unsigned char value = 0;
                    if ([object isKindOfClass:[NSNumber class]]) {value = [(NSNumber*)object unsignedCharValue];}
                    [invocation setArgument:&value atIndex:i+2];
                }
                    break;
                case XZHTypeEncodingBOOL: {
                    BOOL value = 0;
                    if ([object isKindOfClass:[NSNumber class]]) {value = [(NSNumber*)object boolValue];}
                    if ([object isKindOfClass:[NSString class]]) {value = [(NSString*)object boolValue];}
                    [invocation setArgument:&value atIndex:i+2];
                }
                    break;
                case XZHTypeEncodingShort: {
                    short value = 0;
                    if ([object isKindOfClass:[NSNumber class]]) {value = [(NSNumber*)object shortValue];}
                    [invocation setArgument:&value atIndex:i+2];
                }
                    break;
                case XZHTypeEncodingUnsignedShort: {
                    unsigned short value = 0;
                    if ([object isKindOfClass:[NSNumber class]]) {value = [(NSNumber*)object unsignedShortValue];}
                    [invocation setArgument:&value atIndex:i+2];
                }
                    break;
                case XZHTypeEncodingInt: {
                    int value = 0;
                    if ([object isKindOfClass:[NSNumber class]]) {value = [(NSNumber*)object intValue];}
                    [invocation setArgument:&value atIndex:i+2];
                }
                    break;
                case XZHTypeEncodingUnsignedInt: {
                    unsigned int value = 0;
                    if ([object isKindOfClass:[NSNumber class]]) {value = [(NSNumber*)object unsignedIntValue];}
                    [invocation setArgument:&value atIndex:i+2];
                }
                    break;
                case XZHTypeEncodingFloat: {
                    float value = 0;
                    if ([object isKindOfClass:[NSNumber class]]) {value = [(NSNumber*)object floatValue];}
                    [invocation setArgument:&value atIndex:i+2];
                }
                    break;
                case XZHTypeEncodingLong32: {
                    long value = 0;
                    if ([object isKindOfClass:[NSNumber class]]) {value = [(NSNumber*)object longValue];}
                    [invocation setArgument:&value atIndex:i+2];
                }
                    break;
                case XZHTypeEncodingLongLong: {
                    long long value = 0;
                    if ([object isKindOfClass:[NSNumber class]]) {value = [(NSNumber*)object longLongValue];}
                    [invocation setArgument:&value atIndex:i+2];
                }
                    break;
                case XZHTypeEncodingUnsignedLong: {
                    unsigned long value = 0;
                    if ([object isKindOfClass:[NSNumber class]]) {value = [(NSNumber*)object unsignedLongValue];}
                    [invocation setArgument:&value atIndex:i+2];
                }
                    break;
                case XZHTypeEncodingUnsignedLongLong: {
                    unsigned long long value = 0;
                    if ([object isKindOfClass:[NSNumber class]]) {value = [(NSNumber*)object unsignedLongLongValue];}
                    [invocation setArgument:&value atIndex:i+2];
                }
                    break;
                case XZHTypeEncodingDouble: {
                    double value = 0;
                    if ([object isKindOfClass:[NSNumber class]]) {value = [(NSNumber*)object doubleValue];}
                    [invocation setArgument:&value atIndex:i+2];
                }
                    break;
                case XZHTypeEncodingLongDouble: {
                    double value = 0;
                    if ([object isKindOfClass:[NSNumber class]]) {value = [(NSNumber*)object doubleValue];}
                    [invocation setArgument:&value atIndex:i+2];
                }
                    break;
                case XZHTypeEncodingClass: {
                    Class cls = NULL;
                    if ([object isKindOfClass:[NSString class]]) {
                        cls = NSClassFromString(object);
                    }
                    if ([object isKindOfClass:[NSValue class]]) {
                        NSValue *nsvalue = object;
                        if (strcmp(nsvalue.objCType, "^v")) {
                            char *clsName = nsvalue.pointerValue;
                            if (NULL == clsName) {continue;}
                            cls = objc_getClass(clsName);
                        }
                    }
                    if (NULL == cls) {
                        cls = object_getClass(object);
                    }
                    [invocation setArgument:&cls atIndex:i+2];
                }
                    break;
                case XZHTypeEncodingSEL: {
                    SEL sel = NULL;
                    if ([object isKindOfClass:[NSString class]]) {
                        sel = NSSelectorFromString(object);
                    }
                    if ([object isKindOfClass:[NSValue class]]) {
                        NSValue *nsvalue = object;
                        if (strcmp(nsvalue.objCType, "^v")) {
                            char *selName = nsvalue.pointerValue;
                            if (NULL == selName) {continue;}
                            sel = sel_registerName(selName);
                        }
                    }
                    [invocation setArgument:&sel atIndex:i+2];
                }
                    break;
                case XZHTypeEncodingCStruct: {
                    //TODO: 暂不实现
                }
                    break;
                default:
                    break;
            }
        }
    }
    
    [invocation invoke];
    if (signature.methodReturnLength) {
        XZHTypeEncoding type = XZHGetTypeEncoding(signature.methodReturnType) & XZHTypeEncodingDataTypeMask;
        switch (type) {
            case XZHTypeEncodingFoundationObject: {
                id retObejct = nil;
                [invocation getReturnValue:&retObejct];
                return retObejct;
            }
                break;
            case XZHTypeEncodingChar: {
                char value = 0;
                [invocation getReturnValue:&value];
                return @(value);
            }
                break;
            case XZHTypeEncodingUnsignedChar: {
                unsigned char value = 0;
                [invocation getReturnValue:&value];
                return @(value);
            }
                break;
            case XZHTypeEncodingBOOL: {
                BOOL value = 0;
                [invocation getReturnValue:&value];
                return @(value);
            }
                break;
            case XZHTypeEncodingShort: {
                short value = 0;
                [invocation getReturnValue:&value];
                return @(value);
            }
                break;
            case XZHTypeEncodingUnsignedShort: {
                unsigned short value = 0;
                [invocation getReturnValue:&value];
                return @(value);
            }
                break;
            case XZHTypeEncodingInt: {
                int value = 0;
                [invocation getReturnValue:&value];
                return @(value);
            }
                break;
            case XZHTypeEncodingUnsignedInt: {
                unsigned int value = 0;
                [invocation getReturnValue:&value];
                return @(value);
            }
                break;
            case XZHTypeEncodingFloat: {
                float value = 0;
                [invocation getReturnValue:&value];
                return @(value);
            }
                break;
            case XZHTypeEncodingLong32: {
                long value = 0;
                [invocation getReturnValue:&value];
                return @(value);
            }
                break;
            case XZHTypeEncodingLongLong: {
                long long value = 0;
                [invocation getReturnValue:&value];
                return @(value);
            }
                break;
            case XZHTypeEncodingUnsignedLong: {
                unsigned long value = 0;
                [invocation getReturnValue:&value];
                return @(value);
            }
                break;
            case XZHTypeEncodingUnsignedLongLong: {
                unsigned long long value = 0;
                [invocation getReturnValue:&value];
                return @(value);
            }
                break;
            case XZHTypeEncodingDouble: {
                double value = 0;
                [invocation getReturnValue:&value];
                return @(value);
            }
                break;
            case XZHTypeEncodingLongDouble: {
                double value = 0;
                [invocation getReturnValue:&value];
                return @(value);
            }
                break;
            case XZHTypeEncodingClass: {
                Class cls = NULL;
                [invocation getReturnValue:&cls];
                return cls;
            }
                break;
            case XZHTypeEncodingSEL: {
                SEL sel = NULL;
                [invocation getReturnValue:&sel];
                return NSStringFromSelector(sel);
            }
                break;
            case XZHTypeEncodingCStruct: {
                //TODO: 暂不实现
            }
                break;
            default:
                break;
        }

    }
    return nil;
}

@end
