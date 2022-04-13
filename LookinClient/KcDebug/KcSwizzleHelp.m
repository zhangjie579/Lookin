//
//  KcSwizzleHelp.m
//  LookinClient
//
//  Created by 张杰 on 2022/4/13.
//  Copyright © 2022 hughkli. All rights reserved.
//

#import "KcSwizzleHelp.h"
#import <objc/message.h>

@interface NSObject (KcDebug)

+ (void)kc_hookSelectorName:(NSString *)selectorName swizzleSelectorName:(NSString *)swizzleSelectorName;

@end

@implementation KcSwizzleHelp

+ (void)swizzle {
    [NSTextField kc_hookSelectorName:@"setStringValue:" swizzleSelectorName:@"kc_setStringValue:"];
    
    [NSTextField kc_hookSelectorName:@"setAttributedStringValue:" swizzleSelectorName:@"kc_setAttributedStringValue:"];
    
    [NSTextView kc_hookSelectorName:@"setString:" swizzleSelectorName:@"kc_setString:"];
}

@end

@interface NSTextField (KcDebug)

@end

@implementation NSTextField (KcDebug)

- (void)kc_setStringValue:(NSString *)stringValue {
    NSLog(@"kc --- 1 %@", stringValue);
    
    [self kc_setStringValue:stringValue];
}

- (void)kc_setAttributedStringValue:(NSAttributedString *)attributedStringValue {
    NSLog(@"kc --- 2 %@", attributedStringValue);
    
    [self kc_setAttributedStringValue:attributedStringValue];
}

@end

@interface NSTextView (KcDebug)

@end

@implementation NSTextView (KcDebug)

- (void)kc_setString:(NSString *)string {
    NSLog(@"kc --- 3 %@", string);
    
    [self kc_setString:string];
}

@end

@implementation NSObject (KcDebug)

/// hook
+ (void)kc_hookSelectorName:(NSString *)selectorName swizzleSelectorName:(NSString *)swizzleSelectorName {
    Method originMethod = class_getInstanceMethod(self, NSSelectorFromString(selectorName));
    Method swizzleMethod = class_getInstanceMethod(self, NSSelectorFromString(swizzleSelectorName));
    if (!originMethod || !swizzleMethod) {
        return;
    }
    
    if (class_addMethod(self, NSSelectorFromString(selectorName), method_getImplementation(swizzleMethod), method_getTypeEncoding(swizzleMethod))) {
        class_replaceMethod(self, NSSelectorFromString(swizzleSelectorName), method_getImplementation(originMethod), method_getTypeEncoding(originMethod));
    } else {
        method_exchangeImplementations(originMethod, swizzleMethod);
    }
}

@end
