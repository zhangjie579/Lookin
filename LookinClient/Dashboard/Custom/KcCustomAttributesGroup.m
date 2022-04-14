//
//  KcCustomAttributesGroup.m
//  LookinClient
//
//  Created by 张杰 on 2022/4/14.
//  Copyright © 2022 hughkli. All rights reserved.
//

#import "KcCustomAttributesGroup.h"
#import "LookinAttributesGroup.h"
#import "LookinAttributesSection.h"
#import "LookinAttribute.h"

@implementation KcCustomAttributesGroup

/// 添加自定义的attributesGroup
+ (NSArray<LookinAttributesGroup *> *)addCustomAttributesGroup {
    NSMutableArray<LookinAttributesGroup *> *attributesGroup = [[NSMutableArray alloc] init];
    
    { // debugMethodAttribute
        LookinAttributesGroup *debugMethodGroup = [[LookinAttributesGroup alloc] init];
        debugMethodGroup.identifier = LookinAttrGroup_KcDebugMethod;
        
        LookinAttributesSection *debugMethodSection = [[LookinAttributesSection alloc] init];
        debugMethodSection.identifier = LookinAttrSec_KcDebugMethod_Class;
        
        LookinAttribute *debugMethodAttribute = [[LookinAttribute alloc] init];
        debugMethodAttribute.identifier = LookinAttr_Kc_Debug_methodDesc;
        debugMethodAttribute.attrType = LookinAttrTypeCustomObj;
        debugMethodAttribute.value = @[
            @"查找属性name: kc_debug_findUIPropertyName",
            @"dump对象: kc_dumpSwift",
            @"获取所有成员变量: kc_dump_allIvarDescription",
            @"view层级: kc_dump_viewHierarchy",
            @"ViewController的层级: kc_dump_viewControllerHierarchy",
            @"自动布局层级: kc_dump_autoLayoutHierarchy",
        ];
        
        debugMethodSection.attributes = @[
            debugMethodAttribute,
        ];
        
        debugMethodGroup.attrSections = @[debugMethodSection];
        
        [attributesGroup addObject:debugMethodGroup];
    }
    
    return attributesGroup.copy;
}

@end
