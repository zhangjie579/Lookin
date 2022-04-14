//
//  KcDashboardAttributeDebugMethodView.m
//  LookinClient
//
//  Created by 张杰 on 2022/4/14.
//  Copyright © 2022 hughkli. All rights reserved.
//

#import "KcDashboardAttributeDebugMethodView.h"

@implementation KcDashboardAttributeDebugMethodView

- (NSArray<NSString *> *)stringListWithAttribute:(LookinAttribute *)attribute {
    return attribute.value ?: @[];
}

@end
