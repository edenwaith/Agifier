//
//  AgifierPlugin.m
//  Agifier
//
//  Created by Chad Armstrong on 7/15/20.
//  Copyright © 2020 Edenwaith. All rights reserved.
//

#import "AgifierPlugin.h"

@implementation AgifierPlugin

+ (id) plugin {
    return [[self alloc] init];
}

- (void) willRegister:(id<ACPluginManager>)pluginManager {
    
    [pluginManager addFilterMenuTitle:@"Agifier"
                   withSuperMenuTitle:@"Stylize"
                               target:self
                               action:@selector(convert:userObject:)
                        keyEquivalent:@""
            keyEquivalentModifierMask:0
                           userObject:nil];
}

- (void)didRegister {
    
}

- (CIImage*) convert:(CIImage*)image userObject:(id)userObject {
	
	
	
	return nil;
}

- (NSNumber*) worksOnShapeLayers:(id)userObject {
    return [NSNumber numberWithBool:NO];
}

- (NSNumber*) validateForLayer:(id<ACLayer>)layer {
    
    if ([layer layerType] == ACBitmapLayer) {
        return [NSNumber numberWithBool:YES];
    }
    
    return [NSNumber numberWithBool:NO];
}

@end
