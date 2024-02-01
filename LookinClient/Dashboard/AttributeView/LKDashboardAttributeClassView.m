//
//  LKDashboardAttributeClassView.m
//  Lookin
//
//  Created by Li Kai on 2019/6/14.
//  https://lookin.work
//

#import "LKDashboardAttributeClassView.h"
#import "LookinDisplayItem.h"
#import "Lookin-Swift.h"

@implementation LKDashboardAttributeClassView

- (NSArray<NSString *> *)stringListWithAttribute:(LookinAttribute *)attribute {
    NSArray<NSArray<NSString *> *> *lists = attribute.value;
    NSMutableArray<NSString *> *results = [[NSMutableArray alloc] init];
    
    NSArray<NSString *> *result = [lists lookin_map:^id(NSUInteger idx, NSArray<NSString *> *rawClassList) {
        NSArray<NSString *> *demangled = [rawClassList lookin_map:^id(NSUInteger idx, NSString *rawClass) {
            return [LKSwiftDemangler completedParseWithInput:rawClass];
        }];
        return [demangled componentsJoinedByString:@"\n"];
    }];
    
    [results addObjectsFromArray:result];
    
    // 增加内存地址
    if (attribute.targetDisplayItem.hostViewControllerObject) {
        [results addObject:[NSString stringWithFormat:@"<%@: %@>", attribute.targetDisplayItem.hostViewControllerObject.shortSelfClassName, attribute.targetDisplayItem.hostViewControllerObject.memoryAddress]];
    } else if (attribute.targetDisplayItem.displayingObject) {
        LookinObject *displayingObject = attribute.targetDisplayItem.displayingObject;
        [results addObject:[NSString stringWithFormat:@"<%@: %@>", displayingObject.shortSelfClassName, displayingObject.memoryAddress]];
    }
    
    return results;
}

@end
