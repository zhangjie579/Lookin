//
//  KcCallObjcMethodAttributeManager.m
//  LookinClient
//
//  Created by 张杰 on 2024/11/14.
//  Copyright © 2024 hughkli. All rights reserved.
//

#import "KcCallObjcMethodAttributeManager.h"
#import "LKAppsManager.h"

@implementation KcCallObjcMethodAttributeManager

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

@end
