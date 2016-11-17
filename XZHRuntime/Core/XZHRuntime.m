//
//  XZHRuntime.m
//  XZHRuntimeDemo
//
//  Created by XiongZenghui on 16/8/26.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//


#import "XZHRuntime.h"
#import <objc/message.h>
#import <objc/runtime.h>

static char* XZHSubstring(char* ch, size_t pos, size_t length) {
    char* pch=ch;
    char* subch=(char*)calloc(sizeof(char),length+1);
    int i;
    pch=pch+pos;
    for(i=0;i<length;i++) {
        subch[i]=*(pch++);
    }
    subch[length]='\0';
    return subch;
}

/**
 *  支持KVC的c结构体类型
 */
static BOOL XZHIsCStructKVCCompatible(const char *typeEncoding) {
    NSString *type = [NSString stringWithUTF8String:typeEncoding];
    if (!type) return NO;
    static NSSet *types = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableSet *set = [NSMutableSet new];
        // 32 bit
        [set addObject:@"{CGSize=ff}"];
        [set addObject:@"{CGPoint=ff}"];
        [set addObject:@"{CGRect={CGPoint=ff}{CGSize=ff}}"];
        [set addObject:@"{CGAffineTransform=ffffff}"];
        [set addObject:@"{UIEdgeInsets=ffff}"];
        [set addObject:@"{UIOffset=ff}"];
        // 64 bit
        [set addObject:@"{CGSize=dd}"];
        [set addObject:@"{CGPoint=dd}"];
        [set addObject:@"{CGRect={CGPoint=dd}{CGSize=dd}}"];
        [set addObject:@"{CGAffineTransform=dddddd}"];
        [set addObject:@"{UIEdgeInsets=dddd}"];
        [set addObject:@"{UIOffset=dd}"];
        types = set;
    });
    if ([types containsObject:type]) {
        return YES;
    }
    return NO;
}

/**
 *  因为Foundation并没有给出NSBlock这个类，所以只能通过Block实例不断向父类查询类型
 *  如下代码找到的是 NSBlock 这个是三种block类型的`类簇类`，而真正使用的三种block内部类型:
 *  >>>>  __NSGlobalBlock__ >>>> objc_getClass("__NSGlobalBlock__");
 *  >>>>  __NSMallocBlock__ >>>> objc_getClass("__NSMallocBlock__");
 *  >>>>  __NSStackBlock__  >>>> objc_getClass("__NSStackBlock__");
 */
Class XZHGetNSBlockClass() {
    static Class NSBlock = Nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void (^block)(void) = ^(){};
        Class cls = [(NSObject*)block class];
        while (cls && (class_getSuperclass(cls) != [NSObject class]) ) {//>>> 一直遍历到NSObject停止
            cls = class_getSuperclass(cls);
        }
        NSBlock = cls;
    });
    return NSBlock;
}

/**
 *  判断一个 objc class 的foundation type
 *  Foundation类基本上都是`类簇类`，我们使用的类并非是真正的类型
 *  真正的私有类型是如上注释的代码中的类型
 *  但是所有的私有内部类都是`继承自类簇类`，也就是`类簇类的子类`
 */
static xzh_force_inline XZHFoundationType XZHGetClassFoundationType(Class cls) {
    if (NULL == cls) {return XZHFoundationTypeNone;}
    if ([cls isSubclassOfClass:[NSArray class]]) {return XZHFoundationTypeNSArray;}
    else if ([cls isSubclassOfClass:[NSURL class]]) {return XZHFoundationTypeNSURL;}
    else if ([cls isSubclassOfClass:[NSMutableArray class]]) {return XZHFoundationTypeNSMutableArray;}
    else if ([cls isSubclassOfClass:[NSSet class]]) {return XZHFoundationTypeNSSet;}
    else if ([cls isSubclassOfClass:[NSMutableSet class]]) {return XZHFoundationTypeNSMutableSet;}
    else if ([cls isSubclassOfClass:[NSDictionary class]]) {return XZHFoundationTypeNSMutableArray;}
    else if ([cls isSubclassOfClass:[NSMutableDictionary class]]) {return XZHFoundationTypeNSMutableDictionary;}
    else if ([cls isSubclassOfClass:[NSDate class]]) {return XZHFoundationTypeNSDate;}
    else if ([cls isSubclassOfClass:[NSData class]]) {return XZHFoundationTypeNSData;}
    else if ([cls isSubclassOfClass:[NSMutableData class]]) {return XZHFoundationTypeNSMutableData;}
    else if ([cls isSubclassOfClass:[NSNumber class]]) {return XZHFoundationTypeNSNumber;}
    else if ([cls isSubclassOfClass:[NSDecimalNumber class]]) {return XZHFoundationTypeNSDecimalNumber;}
    else if ([cls isSubclassOfClass:[NSString class]]) {return XZHFoundationTypeNSString;}
    else if ([cls isSubclassOfClass:[NSMutableString class]]) {return XZHFoundationTypeNSMutableString;}
    else if ([cls isSubclassOfClass:[NSValue class]]) {return XZHFoundationTypeNSValue;}
    else if ([cls isSubclassOfClass:[NSNull class]]) {return XZHFoundationTypeNSNull;}
    else if ([cls isSubclassOfClass:XZHGetNSBlockClass()]) {return XZHFoundationTypeNSBlock;}
    else if ([cls isSubclassOfClass:[NSObject class]]) {return XZHFoundationTypeCustomer;}//last
    else {return XZHFoundationTypeNone;}
}

//static xzh_force_inline XZHFoundationType XZHGetObjectFoundationType(id obj) {
//    if (!obj) {return XZHFoundationTypeNone;}
//    还是不能如下这么写死类型，因为可能随着iOS SDK升级这些类名可能会发生变化、以及集成结构也会变化
//    Class cls = [obj class];
//    if (cls == objc_getClass("__NSArrayI") || cls == objc_getClass("__NSArray0")) {return XZHFoundationTypeNSArray;}
//    else if (cls == objc_getClass("__NSArrayM")) {return XZHFoundationTypeNSMutableArray;}
//    else if (cls == objc_getClass("NSURL")) {return XZHFoundationTypeNSURL;}
//    else if (cls == objc_getClass("__NSSetI") || cls == objc_getClass("__NSSingleObjectSetI")) {return XZHFoundationTypeNSSet;}
//    else if (cls == objc_getClass("__NSSetM")) {return XZHFoundationTypeNSMutableSet;}
//    else if (cls == objc_getClass("__NSDictionary0") || cls == objc_getClass("__NSDictionaryI")) {return XZHFoundationTypeNSDictionary;}
//    else if (cls == objc_getClass("__NSDictionaryM")) {return XZHFoundationTypeNSMutableDictionary;}
//    else if (cls == objc_getClass("__NSDate")) {return XZHFoundationTypeNSDate;}
//    else if (cls == objc_getClass("_NSZeroData") || cls == objc_getClass("NSConcreteData")) {return XZHFoundationTypeNSData;}
//    else if (cls == objc_getClass("NSConcreteMutableData")) {return XZHFoundationTypeNSMutableData;}
//    else if (cls == objc_getClass("__NSCFNumber")) {return XZHFoundationTypeNSNumber;}
//    else if (cls == objc_getClass("NSDecimalNumber")) {return XZHFoundationTypeNSDecimalNumber;}
//    else if (cls == objc_getClass("__NSCFConstantString") || cls == objc_getClass("NSTaggedPointerString")) {return XZHFoundationTypeNSString;}
//    else if (cls == objc_getClass("__NSCFString")) {return XZHFoundationTypeNSMutableString;}
//    else if (cls == objc_getClass("NSConcreteValue")) {return XZHFoundationTypeNSValue;}
//    else if (cls == objc_getClass("__NSGlobalBlock__") || cls == objc_getClass("__NSMallocBlock__") || cls == objc_getClass("__NSStackBlock__")) {return XZHFoundationTypeNSBlock;}
//    else if (obj == (id)kCFNull) {return XZHFoundationTypeNSNull;}
//    else {return XZHFoundationTypeUnKnown;}//未知、自定义类型
//    return XZHGetClassFoundationType([obj class]);
//}

@implementation XZHIvarModel {
    @package
    Ivar _ivar;
}

- (instancetype)initWithIvar:(Ivar)ivar {
    if (!ivar) return nil;
    if (self = [super init]) {
        _ivar = ivar;
        _name = [NSString stringWithUTF8String:ivar_getName(ivar)];
        _type = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivar)];
        _offset = ivar_getOffset(ivar);
    }
    return self;
}

- (BOOL)isEqualToIvar:(XZHIvarModel *)object {
    if (self == object) {return YES;}
    if (_ivar != object->_ivar) {return NO;}
    if (!object.name || ![_name isEqualToString:object.name]) {return NO;}
    if (!object.type || ![_type isEqualToString:object.type]) {return NO;}
    if (_offset != object.offset) return NO;
    return YES;
}

- (BOOL)isEqual:(id)object {
    if ([self class] == [object class]) {return [self isEqualToIvar:object];}
    else {return [super isEqual:object];}
}

- (NSUInteger)hash {
    return (NSUInteger)(void *)_ivar ^ [_name hash] ^ [_type hash] ^ (NSUInteger)_offset;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ - %p> ivar = %p, name = %@, type = %@, offset = %ld", [self class], self, _ivar, _name, _type, _offset];
}

- (NSString *)debugDescription {
    return [self description];
}

@end

@implementation XZHPropertyModel {
    objc_property_t                         _property;
}

- (instancetype)initWithProperty:(objc_property_t)property {
    if (!property) {return nil;}
    if (self = [super init]) {
        _property = property;
        
        const char *c_name = property_getName(property);
        if (NULL != c_name) {_name = [NSString stringWithUTF8String:c_name];}
        
        //eg、"Tq,N,V_price"、T@"NSString",C,N,V_name 属性的整串编码字符串
        const char *c_attributes = property_getAttributes(property);
        if (NULL != c_attributes) {_encodingString = [NSString stringWithUTF8String:c_attributes];}
        
        /**
         *  获取一个@property属性的所有的objc_property_attribute_t实例
         *  - name = T, value = @NSString、@NSArray、c、q、L ...        >>>> Ivar的数据类型
         *  - name = C, value =                                        >>>> copy
         *  - name = N, value =                                        >>>> nonatomic
         *  - name = V, value = _name                                  >>>> Ivar的名字叫做 _name
         */
        unsigned int num = 0;
        objc_property_attribute_t *atts = property_copyAttributeList(property, &num);
        _typeEncoding = XZHTypeEncodingsUnKnown;
        
        for (int i = 0; i < num; i++) {
            objc_property_attribute_t att = atts[i];
            switch (att.name[0]) {
                case 'T': {
                    size_t len = strlen(att.value);
                    if (len < 1) {
                        _foundationType = XZHFoundationTypeNone;
                        _isCNumber = NO;
                        _isKVCCompatible = NO;
                    } else {
                        // len >= 1
                        char *tmpValue = (char *)malloc(sizeof(char) * len);
                        strcpy(tmpValue, att.value);
                        if (len == 1) {
                            switch (tmpValue[0]) {
                                case '?': {
                                    _isKVCCompatible = NO;
                                    _isCNumber = NO;
                                }
                                    break;
                                case 'c': {//char
                                    _typeEncoding |= XZHTypeEncodingChar;
                                    _isKVCCompatible = YES;
                                    _isCNumber = YES;
                                }
                                    break;
                                case 'i': {//int
                                    _typeEncoding |= XZHTypeEncodingInt;
                                    _isKVCCompatible = YES;
                                    _isCNumber = YES;
                                }
                                    break;
                                case 's': {//short
                                    _typeEncoding |= XZHTypeEncodingShort;
                                    _isKVCCompatible = YES;
                                    _isCNumber = YES;
                                }
                                    break;
                                case 'l': {//long
                                    _typeEncoding |= XZHTypeEncodingLong32;
                                    _isKVCCompatible = YES;
                                    _isCNumber = YES;
                                }
                                    break;
                                case 'q': {//long long
                                    _typeEncoding |= XZHTypeEncodingLongLong;
                                    _isKVCCompatible = YES;
                                    _isCNumber = YES;
                                }
                                    break;
                                case 'C': {//unsigned char
                                    _typeEncoding |= XZHTypeEncodingUnsignedChar;
                                    _isKVCCompatible = YES;
                                    _isCNumber = YES;
                                }
                                    break;
                                case 'I': {//unsigned int
                                    _typeEncoding |= XZHTypeEncodingUnsignedInt;
                                    _isKVCCompatible = YES;
                                    _isCNumber = YES;
                                }
                                    break;
                                case 'S': {//unsigned short
                                    _typeEncoding |= XZHTypeEncodingUnsignedShort;
                                    _isKVCCompatible = YES;
                                    _isCNumber = YES;
                                }
                                    break;
                                case 'L': {//unsigned long
                                    _typeEncoding |= XZHTypeEncodingUnsignedLong;
                                    _isKVCCompatible = YES;
                                    _isCNumber = YES;
                                }
                                    break;
                                case 'Q': {//unsigned long long
                                    _typeEncoding |= XZHTypeEncodingUnsignedLongLong;
                                    _isKVCCompatible = YES;
                                    _isCNumber = YES;
                                }
                                    break;
                                case 'f': {//float
                                    _typeEncoding |= XZHTypeEncodingFloat;
                                    _isKVCCompatible = YES;
                                    _isCNumber = YES;
                                }
                                    break;
                                case 'd': {//double
                                    _typeEncoding |= XZHTypeEncodingDouble;
                                    _isKVCCompatible = YES;
                                    _isCNumber = YES;
                                }
                                    break;
                                case 'D': {//long double
                                    _typeEncoding |= XZHTypeEncodingLongDouble;
                                    _isKVCCompatible = NO;
                                    _isCNumber = YES;
                                }
                                    break;
                                case 'B': {//A C++ bool or a C99 _Bool
                                    _typeEncoding |= XZHTypeEncodingBOOL;
                                    _isKVCCompatible = YES;
                                    _isCNumber = YES;
                                }
                                    break;
                                case 'v': {//void
                                    _typeEncoding |= XZHTypeEncodingVoid;
                                    _isKVCCompatible = NO;
                                    _isCNumber = NO;
                                }
                                    break;
                                case '*': {//char *
                                    _typeEncoding |= XZHTypeEncodingCString;
                                    _isKVCCompatible = NO;
                                    _isCNumber = NO;
                                }
                                    break;
                                case '#': {//Class
                                    _typeEncoding |= XZHTypeEncodingObjcClass;
                                    _isKVCCompatible = YES;
                                    _isCNumber = NO;
                                }
                                    break;
                                case ':': {//SEL
                                    _typeEncoding |= XZHTypeEncodingSEL;
                                    _isKVCCompatible = NO;
                                    _isCNumber = NO;
                                }
                                    break;
                            }
                        } else {
                            // len > 1
                            switch (tmpValue[0]) {
                                case '@': {
                                    if (len == 2 && '?' == tmpValue[1]) {
                                        _typeEncoding |= XZHTypeEncodingFoundationObject;
                                        _foundationType = XZHFoundationTypeNSBlock;
                                        _isCNumber = NO;
                                        _isKVCCompatible = YES;
                                    } else {
                                        size_t *startArr = malloc(sizeof(size_t) * len/2.0);
                                        size_t *endArr = malloc(sizeof(size_t) * len/2.0);
                                        size_t idx = 0;
                                        size_t tmp = 0;
                                        while (idx < len) {
                                            if (tmpValue[idx] == '<') {
                                                startArr[tmp] = idx;
                                            } else if (tmpValue[idx] == '>') {
                                                endArr[tmp] = idx;
                                                tmp++;
                                            }
                                            idx++;
                                        }
                                        
                                        char *clsName = NULL;
                                        if (0 == tmp) {
                                            /**
                                             *  NSArray属性类型一、@property (nonatomic, strong) NSArray *arr; >>> @\"NSArray\"
                                             */
                                            clsName = XZHSubstring(tmpValue, 2, len - 3);
                                            _cls = objc_getClass(clsName);
                                        } else {
                                            /**
                                             *  NSArray属性类型二、@property (nonatomic, strong) NSArray<协议1,协议2,协议3...> *arr; >>> type encoding == @\"NSArray<Animal><Animal2><Animal3>"
                                             */
                                            idx = 0;
                                            NSMutableArray *protocols = [[NSMutableArray alloc] initWithCapacity:tmp];
                                            while (idx < tmp) {
                                                size_t start = startArr[idx];
                                                size_t end = endArr[idx];
                                                if (0 == idx) {
                                                    clsName = XZHSubstring(tmpValue, 2, start - 2);
                                                    _cls = objc_getClass(clsName);
                                                }
                                                char *protocol = NULL;
                                                if (end >= start) {
                                                    protocol = XZHSubstring(tmpValue, start + 1, end - start - 1);
                                                    NSString *protocolStr = [NSString stringWithFormat:@"%s", protocol];
                                                    if (protocolStr) {[protocols addObject:protocolStr];}
                                                    free(protocol);protocol = NULL;
                                                }
                                                idx++;
                                            }
                                            _protocols = [protocols copy];
                                        }
                                        
                                        _typeEncoding |= XZHTypeEncodingFoundationObject;
                                        _foundationType = XZHGetClassFoundationType(_cls);
                                        _isCNumber = NO;
                                        _isKVCCompatible = YES;
                                        free(clsName);clsName = NULL;
                                        free(startArr);startArr = NULL;
                                        free(endArr);endArr = NULL;
                                    }
                                }
                                    break;
                                case '[': {//char[6] >>> [array type]
                                    _typeEncoding |= XZHTypeEncodingCArray;
                                    _isKVCCompatible = NO;
                                    _isCNumber = NO;
                                }
                                    break;
                                case '{': {//struct >>> {Node=i^{Node}Bc}
                                    _typeEncoding |= XZHTypeEncodingCStruct;
                                    _isKVCCompatible = XZHIsCStructKVCCompatible(tmpValue);
                                    _isCNumber = NO;
                                }
                                    break;
                                case '(': {//union
                                    _typeEncoding |= XZHTypeEncodingCUnion;
                                    _isKVCCompatible = YES;
                                    _isCNumber = NO;
                                }
                                    break;
                                case 'b': {//bit field 不使用
                                    _typeEncoding |= XZHTypeEncodingCBitFields;
                                    _isKVCCompatible = NO;
                                    _isCNumber = NO;
                                }
                                    break;
                                case '^': {//c 指针变量
                                    _typeEncoding |= XZHTypeEncodingCPointer;
                                    _isKVCCompatible = NO;
                                    _isCNumber = NO;
                                }
                                    break;
                            }
                        }
                        free(tmpValue);tmpValue = NULL;
                    }
                }
                    break;
                case 'V': {
                    if (att.value) {
                        char *head = (char *)att.value;
                        if(!_name) {_name = [NSString stringWithUTF8String:head];}
                        head++;
                        if (head) {_getter = NSSelectorFromString(_name);}
                        char firstChar = head[0] - 32;
                        head++;
                        NSString *setterStr = ([NSString stringWithFormat:@"set%c%s:", firstChar, head]);
                        if (setterStr) {_setter = NSSelectorFromString(setterStr);}
                    }
                }
                    break;
                    
                case 'C': {
                    _typeEncoding |= XZHTypeEncodingPropertyCopy;
                }
                    break;
                case 'G': {
                    _typeEncoding |= XZHTypeEncodingPropertyCustomGetter;
                    if (att.value) {
                        _getter = sel_registerName(att.name);
                    }
                }
                    break;
                case 'S': {
                    _typeEncoding |= XZHTypeEncodingPropertyCustomSetter;
                    if (att.value) {
                        _setter = sel_registerName(att.value);
                    }
                }
                    break;
                case 'D': {
                    _typeEncoding |= XZHTypeEncodingPropertyDynamic;
                }
                    break;
//                case 'P': {
//                }
                    break;
                case 'N': {
                    _typeEncoding |= XZHTypeEncodingPropertyNonatomic;
                }
                    break;
//                case 't': {
//                    typeEncoding |= XZHTypeEncodingPropertyOldStyleCoding;
//                }
                    break;
                case 'R': {
                    _typeEncoding |= XZHTypeEncodingPropertyReadonly;
                }
                    break;
                case '&': {
                    _typeEncoding |= XZHTypeEncodingPropertyStrong;
                }
                    break;
                case 'w': {
                    _typeEncoding |= XZHTypeEncodingPropertyWeak;
                }
                    break;
            }
        }
        free(atts);
    }
    return self;
}

- (BOOL)isEqualToProperty:(XZHPropertyModel *)property {
    if (self == property) {return YES;}
    if (!property.name || ![_name isEqualToString:property.name]) {return NO;}
    if (_typeEncoding != property.typeEncoding) {return NO;}
    if (_foundationType != property.foundationType) {return NO;}
    if (!property.encodingString || ![_encodingString isEqualToString:property.encodingString] ) {return NO;}
    return YES;
}

- (BOOL)isEqual:(id)object {
    if ([self class] == [object class]) {return [self isEqualToProperty:object];}
    else {return [super isEqual:object];}
}

- (NSUInteger)hash {
    return [_name hash] ^ (NSUInteger)(void *)_getter * (NSUInteger)(void *)_setter ^ _typeEncoding ^ _foundationType ^ [_encodingString hash];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ - %p> name = %@, getter = %@, setter = %@, cls = %@", [self class], self, _name, NSStringFromSelector(_getter), NSStringFromSelector(_setter), _cls];
}

- (NSString *)debugDescription {
    return [self description];
}

@end

@implementation XZHMethodModel {
    @package
    Method _method;
}

- (instancetype)initWithMethod:(Method)method {
    if (!method) {return nil;}
    if (self) {
        _method = method;
        _sel = method_getName(method);
        _imp = method_getImplementation(method);
        _selString = NSStringFromSelector(_sel);
        
        /**
         *  retrun type encoding
         *  这里不使用method_getReturnType(method, char *dst, size_t dst_len)，因为需要分配一个固定长度的字符串
         */
        char *c_returnType = method_copyReturnType(method);
        if (NULL != c_returnType) {
            _returnType = [NSString stringWithUTF8String:c_returnType];
            free(c_returnType);
        }
        
        /**
         *  arguments type encoding
         *  依次得到每一个参数的type encodings
         *  第一个参数默认是target >>> id >>> @
         *  第二个参数默认是_cmd >>> SEL >>> :
         */
        unsigned int argumentCount = method_getNumberOfArguments(method);
        if (argumentCount > 0) {
            NSMutableArray *types = [[NSMutableArray alloc] initWithCapacity:argumentCount];
            for (unsigned int num = 0; num < argumentCount; num++) {
                char *c_argumentType = method_copyArgumentType(method, num);
                if (!c_argumentType) {continue;}
                NSString *argumentType = [NSString stringWithUTF8String:c_argumentType];
                argumentType = (argumentType != nil) ? argumentType : @"";
                [types addObject:argumentType];
                free(c_argumentType);
            }
            _argumentTypes = [types copy];
        }
        
        /**
         *  method type encoding
         */
        const char*method_type = method_getTypeEncoding(method);
        _type = [NSString stringWithUTF8String:method_type];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ - %p> sel = %@， returnType = %@, argumentTypes = %@, type = %@", [self class], self, _selString, _returnType, _argumentTypes, _type];
}

- (NSString *)debugDescription {
    return [self description];
}

- (BOOL)isEqualToMethod:(XZHMethodModel *)method {
    if (self == method) {return YES;}
    if (_sel != method.sel) {return NO;}
    if (_imp != method.imp) {return NO;}
    return YES;
}

- (BOOL)isEqual:(id)object {
    if ([self class] == [object class]) {return [self isEqualToMethod:object];}
    else {return [super isEqual:object];}
}

- (NSUInteger)hash {
    return (NSUInteger)(void *)_sel ^ (NSUInteger)_imp;
}

@end

@implementation XZHProtocolModel {
    @package
    Protocol *_protocol;
}


- (instancetype)initWithProtocol:(Protocol *)protocol {
    self = [super init];
    if (self) {
        _protocol = protocol;
        _name = NSStringFromProtocol(_protocol);
    }
    return self;
}

- (instancetype)initWithProtocolName:(NSString *)protocolName {
    if (!protocolName) return nil;
    Protocol *protocol = NSProtocolFromString(protocolName);
    return [self initWithProtocol:protocol];
}

- (NSArray *)methodsRequired: (BOOL)isRequiredMethod instance: (BOOL)isInstanceMethod {
    if (!_protocol) {return nil;}
    
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:32];
    unsigned int count;
    struct objc_method_description *methods = protocol_copyMethodDescriptionList(_protocol, isRequiredMethod, isInstanceMethod, &count);
    for(unsigned i = 0; i < count; i++) {
        NSString *methodName = NSStringFromSelector(methods[i].name);
        NSString *methodTypes = [NSString stringWithCString:methods[i].types encoding:[NSString defaultCStringEncoding]];
        NSDictionary *dic = @{
                              @"methodName" :((methodName != nil) ? methodName : @""),
                              @"methodName" :((methodTypes != nil) ? methodTypes : @""),
                              };
        if (dic) {[array addObject:dic];}
    }
    
    free(methods);
    return array;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ - %p>", [self class], self];
}

- (NSString *)debugDescription {
    return [self description];
}

@end
@implementation XZHCategoryModel
@end

static dispatch_semaphore_t semaphore = NULL;
@implementation XZHClassModel {
    @package
    Class __unsafe_unretained _cls;     //解析的objc_class实例
    BOOL _isNeedUpdate;                 //标记是否需要重新解析
}

+ (instancetype)instanceWithClass:(Class)cls {
    /**
     *  使用缓存来避免重复性解析Class、信号量同步多线程读取缓存
     */
    static CFMutableDictionaryRef classCache;//类本身的解析缓存
    static CFMutableDictionaryRef metaClsCache;//元类的解析缓存
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0,  &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        metaClsCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0,  &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        semaphore = dispatch_semaphore_create(1);
    });

    XZHClassModel *clsModel = nil;
    
    // 区分两种类型方法: 1)对象方法 2)类方法
    BOOL isMeta = class_isMetaClass(cls);
    if (isMeta) {
        // 类方法
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        clsModel = CFDictionaryGetValue(metaClsCache, (__bridge const void *)(cls));
        dispatch_semaphore_signal(semaphore);
    } else {
        // 对象方法
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        clsModel = CFDictionaryGetValue(classCache, (__bridge const void *)(cls));
        dispatch_semaphore_signal(semaphore);
    }
    
    if (clsModel) {// 存在缓存的解析
        if ([clsModel isNeedUpdate]) {
            [clsModel _parse];//重新进行解析
            if (isMeta) {
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                CFDictionarySetValue(classCache, (__bridge const void *)(cls), (__bridge const void *)(clsModel));
                dispatch_semaphore_signal(semaphore);
            } else {
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                CFDictionarySetValue(metaClsCache, (__bridge const void *)(cls), (__bridge const void *)(clsModel));
                dispatch_semaphore_signal(semaphore);
            }
        }
    } else {// 不存在缓存的解析
        clsModel = [[XZHClassModel alloc] initWithClass:cls];
        if (isMeta) {
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            CFDictionarySetValue(classCache, (__bridge const void *)(cls), (__bridge const void *)(clsModel));
            dispatch_semaphore_signal(semaphore);
        } else {
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            CFDictionarySetValue(metaClsCache, (__bridge const void *)(cls), (__bridge const void *)(clsModel));
            dispatch_semaphore_signal(semaphore);
        }

    }
    return clsModel;
}

/**
 *  解析传入的Class
 */
- (instancetype)initWithClass:(Class)cls {
    if (self = [super init]) {
        _cls = cls;
        _isMeta = class_isMetaClass(cls);
        [self _parse];
        
        /**
         *  解析 super_objc_class，但是除去两个根类
         *  - (1) NSObject 
         *  - (2) NSProxy
         */
        _superCls = class_getSuperclass(cls);
        if (!class_isMetaClass(_superCls) && [NSObject class] != _superCls && [NSProxy class] != _superCls ) {
            _superClassModel = [[XZHClassModel alloc] initWithClass:_superCls];
        }
    }
    return self;
}

- (void)_parse {
    
    //clear datas
    _propertyMap = nil;
    _ivarMap = nil;
    _methodMap = nil;
    _protocolMap = nil;
    
    // all property
    unsigned int pNum = 0;
    objc_property_t *properties = class_copyPropertyList(_cls, &pNum);
    NSMutableDictionary *propertyMap = [[NSMutableDictionary alloc] initWithCapacity:pNum];
    for (int i = 0; i < pNum; i++) {
        objc_property_t property = properties[i];
        XZHPropertyModel *proM = [[XZHPropertyModel alloc] initWithProperty:property];
        if (proM) {[propertyMap setObject:proM forKey:proM.name];}
    }
    _propertyMap = [propertyMap copy];
    free(properties);
    properties = NULL;
    
    // all ivar
    unsigned int iNum = 0;
    Ivar *ivars = class_copyIvarList(_cls, &iNum);
    NSMutableDictionary *ivarMap = [[NSMutableDictionary alloc] initWithCapacity:iNum];
    for (int i = 0; i < pNum; i++) {
        XZHIvarModel *ivarM = [[XZHIvarModel alloc] initWithIvar:ivars[i]];
        if (ivarM) {[ivarMap setObject:ivarM forKey:ivarM.name];}
    }
    _ivarMap = [ivarMap copy];
    free(ivars);
    ivars = NULL;
    
    // all method
    unsigned int mNum = 0;
    Method *methods = class_copyMethodList(_cls, &mNum);
    NSMutableDictionary *methodMap = [[NSMutableDictionary alloc] initWithCapacity:mNum];
    for (int i = 0; i < pNum; i++) {
        XZHMethodModel *m = [[XZHMethodModel alloc] initWithMethod:methods[i]];
        if (m) {[methodMap setObject:m forKey:m.selString];}
    }
    _methodMap = [methodMap copy];
    free(methods);
    methods = NULL;
    
    // all protocol
    unsigned int proNum = 0;
    Protocol *__unsafe_unretained*protocols = class_copyProtocolList(_cls, &proNum);
    NSMutableDictionary *protocolMap = [[NSMutableDictionary alloc] initWithCapacity:proNum];
    for (int i = 0; i < proNum; i++) {
        XZHProtocolModel *pM = [[XZHProtocolModel alloc] initWithProtocol:protocols[i]];
        if (pM) {[protocolMap setObject:pM forKey:pM.name];}
    }
    _protocolMap = [protocolMap copy];
    free(protocols);
    protocols = NULL;
    
    //set default value avoid crash
    if (!_propertyMap) {_propertyMap = @{};}
    if (!_ivarMap) {_ivarMap = @{};}
    if (!_methodMap) {_methodMap = @{};}
    if (!_protocolMap) {_protocolMap = @{};}
    
    // has update parse
    _isNeedUpdate = NO;
}

- (void)setNeedUpdate {
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    _isNeedUpdate = YES;
    dispatch_semaphore_signal(semaphore);
}

- (BOOL)isNeedUpdate {
    return _isNeedUpdate;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@-%p>: name = %@, peropertyMap = %@, ivarMap = %@, methodMap = %@, protocolMap = %@", [self class], self, _name, _propertyMap, _ivarMap, _methodMap, _protocolMap];
}

- (NSString *)debugDescription {
    return [self description];
}

- (BOOL)isEqual:(id)object {
    if ([self class] == [object class]) {return [self isEqualToClassModel:object];}
    else {return [super isEqual:object];}
}

- (BOOL)isEqualToClassModel:(XZHClassModel *)clsModel {
    if (self == clsModel) {return YES;}
    if (_isMeta != clsModel.isMeta) {return NO;}
    if (_superCls != clsModel.superCls) {return NO;}
    if (_superClassModel != clsModel.superClassModel) {return NO;}
    if (![_name isEqualToString:clsModel.name]) {return NO;}
    if (_propertyMap.count != clsModel.propertyMap.count) {return NO;}
    if (_ivarMap.count != clsModel.ivarMap.count) {return NO;}
    if (_methodMap.count != clsModel.methodMap.count) {return NO;}
    if (_protocolMap.count != clsModel.protocolMap.count) {return NO;}
    return YES;
}

@end

XZHWeakRefrenceBlock XZHMakeWeakRefrenceWithObject(id obj) {
    id __weak weakObj = obj;
    return ^() {
        id __strong strongObj = weakObj;
        return strongObj;
    };
}

id XZHGetWeakRefrenceObject(XZHWeakRefrenceBlock block) {
    return (nil != block) ? block() : nil;
}