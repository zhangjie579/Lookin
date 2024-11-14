//
//  KcMenuContainerButton.m
//  LookinClient
//
//  Created by 张杰 on 2024/11/10.
//  Copyright © 2024 hughkli. All rights reserved.
//

#import "KcMenuContainerButton.h"

@implementation KcMenuContainerButton

- (void)mouseDown:(NSEvent *)event {
    [super mouseDown:event];
    if (self.clickTarget && self.clickAction) {
        [NSApp sendAction:self.clickAction to:self.clickTarget from:event];
    }
}

@end
