//
//  KcCallObjcMethodAttributeManager.m
//  LookinClient
//
//  Created by 张杰 on 2024/11/14.
//  Copyright © 2024 hughkli. All rights reserved.
//

#import "KcCallObjcMethodAttributeManager.h"
#import "KcObjcMethodMenu.h"
#import "LKHierarchyDataSource.h"
#import "LKAppsManager.h"

@implementation KcCallObjcMethodAttributeManager

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static KcCallObjcMethodAttributeManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [[KcCallObjcMethodAttributeManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        // 刷新数据源
        // 1、这里要考虑切换app的情况 2、是否这时候太早了app还没连上
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didUpdateApp) name:LKHierarchyDataSourceReloadHierarchyNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

#pragma mark - public

/// 执行对象方法
- (RACSignal *)evalObjcMethodWithItem:(NSMenuItem *)item targetDisplayItem:(LookinDisplayItem *)targetDisplayItem {
    NSDictionary<NSString *, id> *objcMethod = item.representedObject[@"method"];
    
    return [KcCallObjcMethodAttributeManager evalObjcMethod:objcMethod targetDisplayItem:targetDisplayItem];
}

/// 执行对象方法
/// objcMethod { "isUIViewMethod": false, "methodName": [xx xx] }
+ (RACSignal *)evalObjcMethod:(NSDictionary<NSString *, id> *)objcMethod targetDisplayItem:(LookinDisplayItem *)targetDisplayItem {
    if (!targetDisplayItem) {
        return [RACSignal error:[[NSError alloc] init]];;
    }
    
    BOOL isUIViewMethod = [objcMethod[@"isUIViewMethod"] boolValue];
    NSString *methodName = objcMethod[@"methodName"];
    
    if (methodName.length <= 0) {
        NSAssert(NO, @"找不到对应的方法");
        return [RACSignal empty];
    }
    
    LookinObject *searchObjc = targetDisplayItem.viewObject;
    
    if (!isUIViewMethod) {
        LookinObject *_Nullable hostViewControllerObject = targetDisplayItem.hostViewControllerObject;
        
        // 有vc的用vc
        if (hostViewControllerObject) {
            searchObjc = hostViewControllerObject;
        }
    }
    
//    @weakify(self);
//    RACSignal *signal = [LKAppsManager.sharedInstance.inspectingApp performSelectorWithText:objcMethod oid:searchObjc.oid];
    
    // 替换类名
    methodName = [methodName stringByReplacingOccurrencesOfString:@"@Class" withString:searchObjc.rawClassName];
    
    return [[LKAppsManager.sharedInstance.inspectingApp performSelectorWithText:methodName oid:searchObjc.oid] map:^id _Nullable(NSDictionary *dict) {
        NSString *_Nullable returnDescription = dict[@"description"];
        NSString *_Nullable errorLog = dict[@"errorLog"];
        
        if (returnDescription.length) {
            return returnDescription;
        } else if (errorLog.length) {
            return [NSString stringWithFormat:@"%@\n%@", errorLog, @"pod 'KcDebugSwift' 并且版本 >= 0.1.5"];
        } else {
            return @"nil";
        }
    }];
}

#pragma mark - private

- (void)_didUpdateApp {
    [self.noParamMethodMenu didUpdateApp];
    
    [self.keyPathMenu didUpdateApp];
}

#pragma mark - 懒加载

- (KcNoParamObjcMethodMenu *)noParamMethodMenu {
    if (!_noParamMethodMenu) {
        _noParamMethodMenu = [[KcNoParamObjcMethodMenu alloc] init];
    }
    return _noParamMethodMenu;
}

- (KcKeyPathObjcMethodMenu *)keyPathMenu {
    if (!_keyPathMenu) {
        _keyPathMenu = [[KcKeyPathObjcMethodMenu alloc] init];
    }
    return _keyPathMenu;
}

@end
