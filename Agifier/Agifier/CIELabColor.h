//
//  CIELabColor.h
//  Agifier
//
//  Created by Chad Armstrong on 12/4/22.
//  Copyright © 2022 Edenwaith. All rights reserved.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CIELabColor : NSObject

/// Luminance component, light-dark axis
@property (assign, nonatomic) CGFloat lComponent;

/// Red-green axis
@property (assign, nonatomic) CGFloat aComponent;

/// Blue-yellow axis
@property (assign, nonatomic) CGFloat bComponent;

- (nonnull instancetype)initWithLuminance:(CGFloat)l a:(CGFloat)a b:(CGFloat)b;
+ (nonnull instancetype)colorWithLuminance:(CGFloat)l a:(CGFloat)a b:(CGFloat)b;

- (nonnull instancetype)initWithNSColor:(NSColor *)color;
+ (nonnull instancetype)colorWithNSColor:(NSColor *)color;

@end

NS_ASSUME_NONNULL_END
