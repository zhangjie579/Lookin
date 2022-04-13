//
//  LKDashboardAttributeRelationView.m
//  Lookin
//
//  Created by Li Kai on 2019/6/14.
//  https://lookin.work
//

#import "LKDashboardAttributeRelationView.h"
#import "Lookin-Swift.h"

@implementation LKDashboardAttributeRelationView

- (NSArray<NSString *> *)stringListWithAttribute:(LookinAttribute *)attribute {
    NSMutableArray<NSString *> *results = [[NSMutableArray alloc] init];
    
    for (NSString *name in attribute.value) {
        if (![name hasPrefix:@"(_Tt"]) { // _Tt: swift格式化符号, 需要符号化
            [results addObject:name];
            continue;
        }
        
        NSRange range = [name rangeOfString:@" "];
        if (range.location == NSNotFound) {
            [results addObject:name];
            continue;
        }
        
        NSString *systemName = [name substringWithRange:NSMakeRange(1, range.location - 1)];
        NSString *className = [LKDashboardAttributeRelationView demangleNameWithCString:systemName.UTF8String];
        
        [results addObject:[NSString stringWithFormat:@"(%@%@", className, [name substringFromIndex:range.location]]];
    }
    
    return results;
    
//    return attribute.value;
}

/// 解析name
+ (NSString *)demangleNameWithCString:(const char *)cstring {
    return [KcSwiftTool demangleWithSymbol:(const int8_t *)cstring];
}

@end
