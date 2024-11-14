//
//  KcObjcMethodMenu.h
//  LookinClient
//
//  Created by 张杰 on 2024/11/14.
//  Copyright © 2024 hughkli. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KcObjcMethodSuperMenu : NSObject

/// 默认方法信息
/*
 @{
     @"methodName": @"[KcFindPropertyTooler propertyListWithValue:self]",
     @"isUIViewMethod": @NO,
     @"title": @"获取属性列表",
 },
 */
@property(nonatomic, copy) NSArray<NSDictionary<NSString *, id> *> *defaultMethodInfos;

/// 外部app注入的方法
@property(nonatomic, copy) NSArray<NSString *> *injectedCustomMethods;

@property(nonatomic, strong, readwrite) NSMenu *menu;

/// 子类必须重写
- (void)initializeDefaultParam;

/// 添加默认的方法
- (void)addDefaultMethods;

/// 更新menu
- (void)didUpdateApp;

- (NSMenuItem *)itemWithTitle:(NSString *)title;

@end

/// 没有参数
@interface KcNoParamObjcMethodMenu : KcObjcMethodSuperMenu

@end

/// keyPath参数
@interface KcKeyPathObjcMethodMenu : KcObjcMethodSuperMenu

- (NSDictionary<NSString *, id> *)evalMethodStringWithItem:(NSMenuItem *)item keyPath:(NSString *)keyPath;

@end

NS_ASSUME_NONNULL_END
