//
//  CIELabColor.m
//  Agifier
//
//  Created by Chad Armstrong on 12/4/22.
//  Copyright © 2022 Edenwaith. All rights reserved.
//
// References:
// - https://github.com/pshihn/cielab-dither/blob/master/src/colors.ts
// - https://patrickwu.space/2016/06/12/csharp-color/#rgb2lab
// - http://www.easyrgb.com/en/math.php#text2
// - https://www.colormine.org/convert/rgb-to-xyz
// - https://www.colormine.org/convert/xyz-to-lab
// - https://www.beliefmedia.com.au/convert-xyz-cielab
// - https://en.wikipedia.org/wiki/Illuminant_D65

#import "CIELabColor.h"

@implementation CIELabColor

- (nonnull instancetype)initWithLuminance:(CGFloat)l a:(CGFloat)a b:(CGFloat)b {
	
	if (self = [super init]) {
		self.lComponent = l;
		self.aComponent = a;
		self.bComponent = b;
	}
	
	return self;
}

+ (nonnull instancetype)colorWithLuminance:(CGFloat)l a:(CGFloat)a b:(CGFloat)b {
	return [[self alloc] initWithLuminance:l a:a b:b];
}

/// Create a CIELabColor object which uses the CIE Lab color space instead of RGB
/// There is a two step process to convert RGB to CIE Lab.  First, convert from
/// RGB to CIE XYZ, then convert the XYZ to CIE Lab
/// - Parameter color: The equivalent RGB color
- (nonnull instancetype)initWithNSColor:(NSColor *)color {
	
	if (self = [super init]) {
		
		// Convert from RGB to XYZ -----
		
		CGFloat r = [color redComponent];
		CGFloat g = [color greenComponent];
		CGFloat b = [color blueComponent];
		
		// The sRGB component values R, G, B are in the range 0 to 1. When represented digitally
		// as 8-bit numbers, these color component values are in the range of 0 to 255, and should
		// be divided (in a floating point representation) by 255 to convert to the range of 0 to 1.
		
		// The https://www.colormine.org/convert/rgb-to-xyz seems to prefer the 2.4 value, as do most
		// other examples for the exponential value, but some examples might use 2.2
		CGFloat sRGBExp = 2.4;
		
		r = (r > 0.04045) ? pow((r + 0.055) / 1.055, sRGBExp) : r / 12.92;
		g = (g > 0.04045) ? pow((g + 0.055) / 1.055, sRGBExp) : g / 12.92;
		b = (b > 0.04045) ? pow((b + 0.055) / 1.055, sRGBExp) : b / 12.92;
			
		CGFloat x = (r * 0.4124 + g * 0.3576 + b * 0.1805);
		CGFloat y = (r * 0.2126 + g * 0.7152 + b * 0.0722);
		CGFloat z = (r * 0.0193 + g * 0.1192 + b * 0.9505);
		
		// Convert from XYZ to Lab -----

		// Reference-X, Y and Z refer to specific illuminants and observers.
		// D65 ("white") is 1.0 (X = 0.95047, Y = 1.0000, Z = 1.08883).
		// D65: https://en.wikipedia.org/wiki/Illuminant_D65
		// Observer = 2°, Illuminant = D65
		// Normalizing for relative luminance (i.e. set Y = 100), the XYZ tristimulus values are
		// X=95.047, Y=100, Z=108.883
		CGFloat referenceX = 0.95047;
		CGFloat referenceY = 1.00000;
		CGFloat referenceZ = 1.08883;
		
		x = x / referenceX;
		y = y / referenceY;
		z = z / referenceZ;
		
		CGFloat thirdExponent = 1.0 / 3.0; // Explicitly calculate this CGFloat value and avoid integer division error
		
		x = (x > 0.008856) ? pow(x, thirdExponent) : (7.787 * x) + (16.0 / 116.0);
		y = (y > 0.008856) ? pow(y, thirdExponent) : (7.787 * y) + (16.0 / 116.0);
		z = (z > 0.008856) ? pow(z, thirdExponent) : (7.787 * z) + (16.0 / 116.0);

		self.lComponent = (116 * y) - 16;
		self.aComponent = 500 * (x - y);
		self.bComponent = 200 * (y - z);
	}
	
	return self;
}

+ (nonnull instancetype)colorWithNSColor:(NSColor *)color {
	return [[self alloc] initWithNSColor:color];
}

@end
