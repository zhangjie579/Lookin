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

@end

NS_ASSUME_NONNULL_END
