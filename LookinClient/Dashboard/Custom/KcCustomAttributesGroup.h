//
//  KcCustomAttributesGroup.h
//  LookinClient
//
//  Created by 张杰 on 2022/4/14.
//  Copyright © 2022 hughkli. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LookinAttributesGroup;

NS_ASSUME_NONNULL_BEGIN

/// 自定义增加的右边功能栏
@interface KcCustomAttributesGroup : NSObject

/// 添加自定义的attributesGroup
+ (NSArray<LookinAttributesGroup *> *)addCustomAttributesGroup;

@end

NS_ASSUME_NONNULL_END
