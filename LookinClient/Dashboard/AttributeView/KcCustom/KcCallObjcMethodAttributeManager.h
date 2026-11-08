//
//  KcCallObjcMethodAttributeManager.h
//  LookinClient
//
//  Created by 张杰 on 2024/11/14.
//  Copyright © 2024 hughkli. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KcCallObjcMethodAttributeManager : NSObject

/// 执行对象方法
/// objcMethod { "isUIViewMethod": false, "methodName": [xx xx] }
+ (RACSignal *)evalObjcMethod:(NSDictionary<NSString *, id> *)objcMethod targetDisplayItem:(LookinDisplayItem *)targetDisplayItem;

/// 执行带占位参数的方法。参数由 LookinServer 在解析方法模板后设置，避免参数文本破坏方法语法。
+ (RACSignal *)evalObjcMethod:(NSDictionary<NSString *, id> *)objcMethod parameters:(NSArray<NSString *> *)parameters targetDisplayItem:(LookinDisplayItem *)targetDisplayItem;

@end

NS_ASSUME_NONNULL_END
