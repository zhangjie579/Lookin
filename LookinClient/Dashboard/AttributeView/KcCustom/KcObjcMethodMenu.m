//
//  KcObjcMethodMenu.m
//  LookinClient
//
//  Created by 张杰 on 2024/11/14.
//  Copyright © 2024 hughkli. All rights reserved.
//

#import "KcObjcMethodMenu.h"
#import "LKAppsManager.h"

@implementation KcObjcMethodSuperMenu

- (instancetype)init {
    if (self = [super init]) {
        [self initializeDefaultParam];
        
        [self addDefaultMethods];
        [self didUpdateApp];
    }
    return self;
}

- (void)initializeDefaultParam {
    NSAssert(NO, @"子类必须重写");
}

- (NSMenuItem *)itemWithTitle:(NSString *)title {
    for (NSMenuItem *item in self.menu.itemArray) {
        if ([item.title isEqualToString:title]) {
            return item;
        }
    }
    
    NSAssert(NO, @"title不对");
    
    return nil;
}

- (void)addDefaultMethods {
    [self.defaultMethodInfos enumerateObjectsUsingBlock:^(NSDictionary<NSString *,id> * _Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.menu addItem:({
            NSMenuItem *menuItem = [NSMenuItem new];
            menuItem.image = [[NSImage alloc] initWithSize:NSMakeSize(1, 22)];
            menuItem.title = dict[@"title"];
            menuItem.tag = idx;
            menuItem.representedObject = @{
                @"method": dict,
            };
            
            menuItem;
        })];
    }];
}

- (void)didUpdateApp {
    NSInteger numberOfItems = self.menu.numberOfItems;
    
    if (numberOfItems > self.defaultMethodInfos.count) {
        for (NSInteger i = numberOfItems - 1; i >= self.defaultMethodInfos.count; i--) {
            [self.menu removeItemAtIndex:i];
        }
    }
    
    if (!LKAppsManager.sharedInstance.inspectingApp) {
        return;
    }
    
    // 添加外部注入的方法
    if (self.injectedCustomMethods.count == 0) {
        return;
    }
    
    @weakify(self);
    
    RACSignal *signal = [LKAppsManager.sharedInstance.inspectingApp performSelectorWithText:self.injectedCustomMethods[0] oid:0];
    
    for (NSInteger i = 1; i < self.injectedCustomMethods.count; i++) {
        signal = [signal flattenMap:^__kindof RACSignal * _Nullable(NSDictionary * _Nullable dict) {
            @strongify(self);
            NSString *_Nullable returnDescription = dict[@"description"];
            
            [self _addCustomMenuItem:returnDescription];
            
            return [LKAppsManager.sharedInstance.inspectingApp performSelectorWithText:self.injectedCustomMethods[i] oid:0];
        }];
    }
    
    [signal subscribeNext:^(NSDictionary * _Nullable dict) {
        @strongify(self);
        NSString *_Nullable returnDescription = dict[@"description"];
        
        [self _addCustomMenuItem:returnDescription];
    }];
    
//    [[[[[LKAppsManager.sharedInstance.inspectingApp performSelectorWithText:self.injectedCustomMethods[0] oid:0]
//        flattenMap:^__kindof RACSignal * _Nullable(NSDictionary * _Nullable dict) {
//            @strongify(self);
//            NSString *_Nullable returnDescription = dict[@"description"];
//            
//            [self _addCustomMenuItem:returnDescription];
//            
//            return [LKAppsManager.sharedInstance.inspectingApp performSelectorWithText:self.injectedCustomMethods[1] oid:0];
//    }] flattenMap:^__kindof RACSignal * _Nullable(NSDictionary * _Nullable dict) {
//        @strongify(self);
//        NSString *_Nullable returnDescription = dict[@"description"];
//        
//        [self _addCustomMenuItem:returnDescription];
//        
//        return [LKAppsManager.sharedInstance.inspectingApp performSelectorWithText:self.injectedCustomMethods[2] oid:0];
//    }] flattenMap:^__kindof RACSignal * _Nullable(NSDictionary * _Nullable dict) {
//        @strongify(self);
//        NSString *_Nullable returnDescription = dict[@"description"];
//        
//        [self _addCustomMenuItem:returnDescription];
//        
//        return [LKAppsManager.sharedInstance.inspectingApp performSelectorWithText:self.injectedCustomMethods[3] oid:0];
//    }] subscribeNext:^(NSDictionary * _Nullable dict) {
//        @strongify(self);
//        NSString *_Nullable returnDescription = dict[@"description"];
//        
//        [self _addCustomMenuItem:returnDescription];
//    }];
}

- (void)_addCustomMenuItem:(nullable NSString *)jsonString {
    if (!jsonString.length) {
        return;
    }
    
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
    if (data) {
        NSError *error = nil;
        NSArray *jsons = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (jsons && !error) {
            for (NSDictionary *dict in jsons) {
                [self.menu addItem:({
                    NSMenuItem *menuItem = [NSMenuItem new];
                    menuItem.image = [[NSImage alloc] initWithSize:NSMakeSize(1, 22)];
                    menuItem.title = dict[@"title"];
                    menuItem.tag = self.menu.itemArray.count - 1;
                    menuItem.representedObject = @{
                        @"method": dict,
                    };
                    
                    menuItem;
                })];
            }
        }
    }
}

#pragma mark - 懒加载

- (NSMenu *)menu {
    if (!_menu) {
        NSMenu *menu = [NSMenu new];
//        [menu addItem:[NSMenuItem separatorItem]];
//        [menu addItem:({
//            NSMenuItem *menuItem = [NSMenuItem new];
//            menuItem.image = [[NSImage alloc] initWithSize:NSMakeSize(1, 22)];
//            menuItem.title = @"获取属性列表";
//            menuItem.tag = 1;
//            menuItem;
//        })];
        
        _menu = menu;
    }
    return _menu;
}

@end

@implementation KcNoParamObjcMethodMenu

- (void)initializeDefaultParam {
    self.defaultMethodInfos = @[
        @{
            @"methodName": @"[KcFindPropertyTooler propertyListWithValue:self]",
            @"isUIViewMethod": @NO,
            @"title": @"获取属性列表",
        },
        @{
            @"methodName":  @"[self kc_debug_findUIPropertyName]",
            @"isUIViewMethod": @NO,
            @"title": @"查询对象属性名",
        },
        @{
            @"methodName": @"[self kc_dump_allIvarDescription]",
            @"isUIViewMethod": @NO,
            @"title": @"所有成员变量",
        },
        @{
            @"methodName": @"[self kc_dumpSwift]",
            @"isUIViewMethod": @NO,
            @"title": @"dumpSwift",
        },
        @{
            @"methodName": @"[@Class kc_dump_allMethodDescription]",
            @"isUIViewMethod": @NO,
            @"title": @"dump所有方法",
        },
        @{
            @"methodName": @"[@Class kc_dump_allCustomMethodDescription]",
            @"isUIViewMethod": @NO,
            @"title": @"dump所有自定义方法",
        },
        @{
            @"methodName": @"[@Class kc_dump_allPropertyDescription]",
            @"isUIViewMethod": @NO,
            @"title": @"dump所有属性",
        },
        @{
            @"methodName": @"[NSObject kc_dump_propertyDescriptionForClass:@Class]",
            @"isUIViewMethod": @NO,
            @"title": @"dump当前class属性",
        },
        @{
            @"methodName": @"[self kc_dump_autoLayoutHierarchy]",
            @"isUIViewMethod": @YES,
            @"title": @"自动布局",
        },
        @{
            @"methodName": @"[self kc_dump_viewControllerHierarchy]",
            @"isUIViewMethod": @NO,
            @"title": @"ViewController的层级"
        },
        @{
            @"methodName": @"[self matchSubviewsWithPropertyName:backgroundColor]",
            @"isUIViewMethod": @YES,
            @"title": @"查询all子树背景色",
        },
        @{
            @"methodName": @"[self matchSubviewsWithPropertyName:cornerRadius]",
            @"isUIViewMethod": @YES,
            @"title": @"查询all子树圆角",
        },
        @{
            @"methodName": @"[self matchSubviewsWithPropertyName:borderColor]",
            @"isUIViewMethod": @YES,
            @"title": @"查询all子树边框",
        },
    ];
    
    self.injectedCustomMethods = @[
        @"[NSObject kc_injectedCustomFeature]",
        @"[NSObject kc_injectedCustomFeature_0]",
        @"[NSObject kc_injectedCustomFeature_1]",
        @"[NSObject kc_injectedCustomFeature_2]",
    ];
}

@end

@implementation KcKeyPathObjcMethodMenu

- (void)initializeDefaultParam {
    self.defaultMethodInfos = @[
        @{
            @"methodName": @"[KcFindPropertyTooler searchPropertyWithValue:self keyPath: %@]",
            @"isUIViewMethod": @NO,
            @"title": @"查询属性value",
        },
        @{
            @"methodName": @"[self matchSubviewsWithPropertyName: %@]",
            @"isUIViewMethod": @YES,
            @"title": @"all子树下属性",
        },
        @{
            @"methodName": @"[self matchSuperviewsWithPropertyName: %@]",
            @"isUIViewMethod": @YES,
            @"title": @"superview属性",
        },
    ];
    
    self.injectedCustomMethods = @[
        @"[NSObject kc_injectedCustomKeyPathMethod]",
        @"[NSObject kc_injectedCustomKeyPathMethod_0]",
        @"[NSObject kc_injectedCustomKeyPathMethod_1]",
        @"[NSObject kc_injectedCustomKeyPathMethod_2]",
    ];
}

- (NSDictionary<NSString *, id> *)evalMethodStringWithItem:(NSMenuItem *)item keyPath:(NSString *)keyPath {
    NSMutableDictionary<NSString *, id> *methodInfo = [NSMutableDictionary dictionaryWithDictionary:item.representedObject[@"method"]];
    
    NSString *name = [methodInfo[@"methodName"] stringByReplacingOccurrencesOfString:@"%@" withString:keyPath];
    methodInfo[@"methodName"] = name;

    return methodInfo;
}

@end
