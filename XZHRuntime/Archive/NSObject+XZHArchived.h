//
//  NSObject+XZHArchived.h
//  XZHRuntimeDemo
//
//  Created by XiongZenghui on 16/10/18.
//  Copyright © 2016年 com.cn.fql. All rights reserved.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

/**
 *  部分代码参考自AutoCoding
 */

@interface NSObject (XZHArchived)

/**
 *  将如下函数放到NSCoding实现函数中调用即可
 *
 *  @implemation Person
 *  - (void)xzh_encodeWithCoder:(NSCoder *)aCoder {
 *      [self xzh_encodeWithCoder:aCoder];
 *  }
 *  - (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
 *      return [self xzh_initWithCoder:aDecoder];
 *  }
 *  @end
 */

- (void)xzh_encodeWithCoder:(NSCoder *)aCoder;
- (nullable instancetype)xzh_initWithCoder:(NSCoder *)aDecoder;

/**
 *  对象归档到指定路径的文件
 *
 *  @param filePath
 *  @param useAuxiliaryFile
 *
 *  @return
 */
- (BOOL)xzh_writeToFile:(NSString *)filePath atomically:(BOOL)useAuxiliaryFile;

/**
 *  从指定路径文件解档成对象
 *
 *  @param path
 *
 *  @return
 */
+ (instancetype)xzh_loadWithContentsOfFile:(NSString *)filePath;

@end
NS_ASSUME_NONNULL_END
