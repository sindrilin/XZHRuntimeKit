//
//  Person.h
//  XZHRuntimeDemo
//
//  Created by xiongzenghui on 16/10/7.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Animal <NSObject>
@property (nonatomic, copy) NSString *name;
@end

@protocol Animal2 <NSObject>
@property (nonatomic, copy) NSString *name;
@end

@protocol Animal3 <NSObject>
@property (nonatomic, copy) NSString *name;
@end

@interface Cat : NSObject
@property (nonatomic, assign) NSInteger cid;
@property (nonatomic, copy) NSString *name;
@end

@interface Child : NSObject
@property (nonatomic, assign) NSInteger cid;
@property (nonatomic, copy) NSString *name;
@end

@interface Dog : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, copy) NSString *sex1;
@property (nonatomic, copy) NSString *sex2;
@property (nonatomic, copy) NSString *sex3;
@property (nonatomic, strong) Cat *cat;
@property (nonatomic, strong) NSArray *childs;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, assign) BOOL flag1;
@property (nonatomic, assign) BOOL flag2;
@property (nonatomic, assign) BOOL flag3;
@property (nonatomic, assign) BOOL flag4;
@property (nonatomic, assign) BOOL flag5;
@property (nonatomic, assign) int flag6;
@property (nonatomic, assign) NSInteger flag7;
@property (nonatomic, assign) BOOL flag8;

@property (nonatomic, copy) void (^block)();
//@property (nonatomic, strong) NSArray<Animal, Animal2, Animal3> *animales1;
//@property (nonatomic, strong) NSArray<Child *> *animales2;
@end


