//
//  KcMenuContainerButton.h
//  LookinClient
//
//  Created by 张杰 on 2024/11/10.
//  Copyright © 2024 hughkli. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface KcMenuContainerButton : NSButton

@property(nonatomic, weak) id clickTarget;
@property(nonatomic, assign) SEL clickAction;

@end

NS_ASSUME_NONNULL_END
