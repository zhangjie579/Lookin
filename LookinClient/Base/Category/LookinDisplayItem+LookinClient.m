//
//  LookinDisplayItem+LookinClient.m
//  LookinClient
//
//  Created by likaimacbookhome on 2023/11/1.
//  Copyright © 2023 hughkli. All rights reserved.
//

#import "LookinDisplayItem+LookinClient.h"
#import "LookinIvarTrace.h"

@implementation LookinDisplayItem (LookinClient)

- (NSString *)title {
    if (self.customInfo) {
        return self.customInfo.title;
    } else if (self.customDisplayTitle.length > 0) {
        return self.customDisplayTitle;
    } else if (self.viewObject) {
        return self.viewObject.lk_simpleDemangledClassName;
    } else if (self.layerObject) {
        return self.layerObject.lk_simpleDemangledClassName;
    } else {
        return nil;
    }
}

- (NSString *)subtitle {
    if (self.customInfo) {
        return self.customInfo.subtitle;
    }
    
    NSString *text = self.hostViewControllerObject.lk_simpleDemangledClassName;
    if (text.length) {
        return [NSString stringWithFormat:@"%@.view", text];
    }
    
    LookinObject *representedObject = self.viewObject ? : self.layerObject;
    if (representedObject.specialTrace.length) {
        return representedObject.specialTrace;
        
    }
    if (representedObject.ivarTraces.count) {
        NSArray<NSString *> *ivarNameList = [representedObject.ivarTraces lookin_map:^id(NSUInteger idx, LookinIvarTrace *value) {
            return value.ivarName;
        }];
        return [[[NSSet setWithArray:ivarNameList] allObjects] componentsJoinedByString:@"   "];
    }
    
    return nil;
}

- (BOOL)representedForSystemClass {
    return [self.title hasPrefix:@"UI"] || [self.title hasPrefix:@"CA"] || [self.title hasPrefix:@"_"];
}

- (NSImage *)appropriateScreenshot {
    if (self.isExpandable && self.isExpanded) {
        return self.soloScreenshot;
    }
    return self.groupScreenshot;
}

- (BOOL)isUserCustom {
    return self.customInfo != nil;
}

- (BOOL)hasPreviewBoxAbility {
    if (!self.customInfo) {
        return YES;
    }
    if ([self.customInfo hasValidFrame]) {
        return YES;
    }
    return NO;
}

- (BOOL)hasValidFrameToRoot {
    if (self.customInfo) {
        return [self.customInfo hasValidFrame];
    }
    return [LKHelper validateFrame:self.frame];
}

- (CGRect)calculateFrameToRoot {
    if (self.customInfo) {
        return [self.customInfo.frameInWindow rectValue];
    }
    if (!self.superItem) {
        return self.frame;
    }
    CGRect superFrameToRoot = [self.superItem calculateFrameToRoot];
    CGRect superBounds = self.superItem.bounds;
    CGRect selfFrame = self.frame;
    
    CGFloat x = selfFrame.origin.x - superBounds.origin.x + superFrameToRoot.origin.x;
    CGFloat y = selfFrame.origin.y - superBounds.origin.y + superFrameToRoot.origin.y;
    
    CGFloat width = selfFrame.size.width;
    CGFloat height = selfFrame.size.height;
    return CGRectMake(x, y, width, height);
}

- (BOOL)isPassiveFullScreenLayerWithScreenSize:(CGSize)screenSize {
    // 用户自定义的虚拟图层没有对应的真实 view，不参与判定
    if (self.customInfo) {
        return NO;
    }
    if (screenSize.width <= 0 || screenSize.height <= 0 || ![self hasValidFrameToRoot]) {
        return NO;
    }

    // 1) 铺满全屏：与屏幕的重叠面积至少占 95%。
    //    用「重叠面积」而不是直接比较 frame，是为了兼容起点略有偏移（例如为了覆盖状态栏而把 y 设为 -20）
    //    或尺寸略大于屏幕的 overlay。
    CGRect screenRect = CGRectMake(0, 0, screenSize.width, screenSize.height);
    CGRect frameToRoot = [self calculateFrameToRoot];
    CGRect intersection = CGRectIntersection(frameToRoot, screenRect);
    if (CGRectIsNull(intersection) || CGRectIsEmpty(intersection)) {
        return NO;
    }
    CGFloat screenArea = screenRect.size.width * screenRect.size.height;
    CGFloat coveredArea = intersection.size.width * intersection.size.height;
    if (coveredArea < screenArea * 0.95) {
        return NO;
    }

    // 2) 透明：没有自己的背景色。backgroundColor 为 nil 时等价于 clearColor。
    //    alpha（layer.opacity）单独为 0 的图层本来就属于 inHiddenHierarchy，这里不需要再判断。
    if (self.backgroundColor && self.backgroundColor.alphaComponent > 0.01) {
        return NO;
    }

    // 3) 不响应用户操作：iOS 端上报的 eventHandlers 包含手势识别器和 UIControl 的 target-action。
    //    只要有任何一种，就说明该图层会消费触摸事件，不能屏蔽。
    if (self.eventHandlers.count > 0) {
        return NO;
    }
    //    兜底：控件类即使当前没挂 target / gesture，也仍然具备接收事件的语义（例如可点击态、滚动）。
    static NSSet<NSString *> *interactiveBaseClasses;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        interactiveBaseClasses = [NSSet setWithObjects:@"UIControl", @"UIScrollView", nil];
    });
    if ([self itemIsKindOfClassesWithNames:interactiveBaseClasses]) {
        return NO;
    }

    return YES;
}

- (BOOL)isMatchedWithSearchString:(NSString *)string {
    if (string.length == 0) {
        NSAssert(NO, @"");
        return NO;
    }
    NSString *searchString = string.lowercaseString;
    if ([self.title.lowercaseString containsString:searchString]) {
        return YES;
    }
    if ([self.subtitle.lowercaseString containsString:searchString]) {
        return YES;
    }
    if ([self.viewObject.memoryAddress containsString:searchString]) {
        return YES;
    }
    if ([self.layerObject.memoryAddress containsString:searchString]) {
        return YES;
    }
    return NO;
}

- (void)enumerateSelfAndAncestors:(void (^)(LookinDisplayItem *, BOOL *))block {
    if (!block) {
        return;
    }
    LookinDisplayItem *item = self;
    while (item) {
        BOOL shouldStop = NO;
        block(item, &shouldStop);
        if (shouldStop) {
            break;
        }
        item = item.superItem;
    }
}

- (void)enumerateAncestors:(void (^)(LookinDisplayItem *, BOOL *))block {
    [self.superItem enumerateSelfAndAncestors:block];
}

- (void)enumerateSelfAndChildren:(void (^)(LookinDisplayItem *item))block {
    if (!block) {
        return;
    }
    
    block(self);
    [self.subitems enumerateObjectsUsingBlock:^(LookinDisplayItem * _Nonnull subitem, NSUInteger idx, BOOL * _Nonnull stop) {
        [subitem enumerateSelfAndChildren:block];
    }];
}

- (BOOL)itemIsKindOfClassWithName:(NSString *)className {
    if (!className) {
        NSAssert(NO, @"");
        return NO;
    }
    return [self itemIsKindOfClassesWithNames:[NSSet setWithObject:className]];
}

- (BOOL)itemIsKindOfClassesWithNames:(NSSet<NSString *> *)targetClassNames {
    if (!targetClassNames.count) {
        return NO;
    }
    LookinObject *selfObj = self.viewObject ? : self.layerObject;
    if (!selfObj) {
        return NO;
    }
    
    __block BOOL boolValue = NO;
    [targetClassNames enumerateObjectsUsingBlock:^(NSString * _Nonnull targetClassName, BOOL * _Nonnull stop_outer) {
        [selfObj.classChainList enumerateObjectsUsingBlock:^(NSString * _Nonnull selfClass, NSUInteger idx, BOOL * _Nonnull stop_inner) {
            NSString *nonPrefixSelfClass = [selfClass componentsSeparatedByString:@"."].lastObject;
            if ([nonPrefixSelfClass isEqualToString:targetClassName]) {
                boolValue = YES;
                *stop_inner = YES;
            }
        }];
        if (boolValue) {
            *stop_outer = YES;
        }
    }];
    
    return boolValue;
}

@end
