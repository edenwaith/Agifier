//
//  CIELabColor.m
//  Agifier
//
//  Created by Chad Armstrong on 12/4/22.
//  Copyright © 2022 Edenwaith. All rights reserved.
//

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

- (nonnull instancetype)initWithNSColor:(NSColor *)color {
	if (self = [super init]) {
		// TODO: Convert from an NSColor to CIE Lab
		CGFloat r = [color redComponent];
		CGFloat g = [color greenComponent];
		CGFloat b = [color blueComponent];
		
		// The sRGB component values R, G, B are in the range 0 to 1. When represented digitally as 8-bit numbers, these color component values are in the range of 0 to 255, and should be divided (in a floating point representation) by 255 to convert to the range of 0 to 1.
		
		// Normalize the rgb values (but that is dependent on how the RGB components are returned
		// This step is probably not needed since the color components are between 0 and 1, not values 0-255
	//	r = r / 255;
	//	g = g / 255;
	//	b = b / 255;
		
		// Conversion from RGB to XYZ: http://www.easyrgb.com/en/math.php#text2
		r = (r > 0.04045) ? pow((r + 0.055) / 1.055, 2.4) : r / 12.92;
		g = (g > 0.04045) ? pow((g + 0.055) / 1.055, 2.4) : g / 12.92;
		b = (b > 0.04045) ? pow((b + 0.055) / 1.055, 2.4) : b / 12.92;
		
		// D65 ("white") is 1.0 (X = 0.9505, Y = 1.0000, Z = 1.0890).
		// D65: https://en.wikipedia.org/wiki/Illuminant_D65
		// Observer= 2°, Illuminant= D65
		// Normalizing for relative luminance (i.e. set Y = 100), the XYZ tristimulus values are
		// X=95.047, Y=100, Z=108.883
		CGFloat x = (r * 0.4124 + g * 0.3576 + b * 0.1805) / 0.95047;
		CGFloat y = (r * 0.2126 + g * 0.7152 + b * 0.0722) / 1.00000;
		CGFloat z = (r * 0.0193 + g * 0.1192 + b * 0.9505) / 1.08883;
		
		// Verify if that last part is just supposed to be 16/116, or if 116 is supposed to divide against a larger part.
		// https://www.beliefmedia.com.au/convert-xyz-cielab seems to confirm this
		x = (x > 0.008856) ? pow(x, 1 / 3) : (7.787 * x) + (16.0 / 116.0);
		y = (y > 0.008856) ? pow(y, 1 / 3) : (7.787 * y) + (16.0 / 116.0);
		z = (z > 0.008856) ? pow(z, 1 / 3) : (7.787 * z) + (16.0 / 116.0);

		// Need to verify if once normalizing by 255, if any of these are still above 1.0.  If so, then
		// need to use another structure to hold the CIE Lab* value.
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
