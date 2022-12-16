//
//  AgifierPlugin.m
//  Agifier
//
//  Created by Chad Armstrong on 7/15/20.
//  Copyright © 2020 Edenwaith. All rights reserved.
//
//	Copy this plug-in to the ~/Library/Application Support/Acorn/Plug-Ins folder

#import "AgifierPlugin.h"
#import "CIELabColor.h"
#import <CoreImage/CoreImage.h>

// The compiler warns that these macros are already defined
//#define MAX(a,b) ((a) > (b) ? (a) : (b))
//#define MIN(a,b) ((a) < (b) ? (a) : (b))

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

- (NSNumber*) worksOnShapeLayers:(id)userObject {
	return [NSNumber numberWithBool:NO];
}

- (NSNumber*) validateForLayer:(id<ACLayer>)layer {
	
	if ([layer layerType] == ACBitmapLayer) {
		return [NSNumber numberWithBool:YES];
	}
	
	return [NSNumber numberWithBool:NO];
}

#pragma mark - Custom AGIfier Methods

// Reduce each color component to the closest EGA-style equivalent value.
// In hex, each component can only be 0x00, 0x55, 0xAA, or 0xFF (0, 85, 170, 255)
// 0x00 = 0 = 0
// 0x55 = 85 = 0.333333
// 0xAA = 170 = 0.6666667
// 0xFF = 255 = 1.0
- (CGFloat) bestColorComponentValue: (CGFloat) colorComponent
{
	if (colorComponent < 0.166666)
	{
		return 0.0; // 0x00
	}
	else if (colorComponent < 0.5)
	{
		return 1.0/3.0; // 0x55
	}
	else if (colorComponent < 0.833333)
	{
		return 2.0/3.0; // 0xAA
	}
	else
	{
		return 1.0; // 0xFF
	}
}

// This comes closer and it adjusts each color to have the proper EGA levels for each color component.
// Each color component is marked at intervals of thirds (0, 1/3, 2/3, 1), which in hex is 0x00, 0x55, 0xAA, 0xFF.
- (NSColor *) closerEGAColor: (NSColor *)pixelColor
{
	CGFloat red = [pixelColor redComponent];
	CGFloat green = [pixelColor greenComponent];
	CGFloat blue = [pixelColor blueComponent];

	// For each color component, need to calculate the closest value
	CGFloat updatedRed = [self bestColorComponentValue: red];
	CGFloat updatedGreen = [self bestColorComponentValue: green];
	CGFloat updatedBlue = [self bestColorComponentValue: blue];
		
	return [NSColor colorWithCalibratedRed: updatedRed green: updatedGreen blue: updatedBlue alpha: 1.0];
}


/// Convert an NSColor and return its hex representation as a string (RRGGBB)
/// @param egaColor The original NSColor to convert into a hex string
- (NSString *) convertNSColorToHex:(NSColor *)egaColor
{
	NSString *hexString = nil;
	
	CGFloat red = [egaColor redComponent];
	CGFloat green = [egaColor greenComponent];
	CGFloat blue = [egaColor blueComponent];
	
	int redInt = (int)(red * 255.0);
	int greenInt = (int)(green * 255.0);
	int blueInt = (int)(blue * 255.0);
	
	hexString = [NSString stringWithFormat:@"%02X%02X%02X", redInt, greenInt, blueInt];
	
	return hexString;
}

/// Calculate and return the closest EGA color to the given pixelColor
/// This uses a predetermined color palette to match any color to the
/// standard 16 color EGA palette.
/// Note: There are still issues with trying to select a proper EGA color
/// Might need to saturate the colors or determine a better algorithm to
/// choose better colors so things like grass and leaves will be some shade
/// of green instead of grey, black, or brown.
/// @param pixelColor The color of the current pixel
- (NSColor *) estimatedEGAColor:(NSColor *)pixelColor
{
	NSArray *colorPalette = @[	[NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.0 alpha: 1.0], // 0: Black
							[NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 170.0/255.0 alpha: 1.0], // 1: Blue
							[NSColor colorWithCalibratedRed: 0.0 green: 170.0/255.0 blue: 0.0 alpha: 1.0], // 2: Green
							[NSColor colorWithCalibratedRed: 0.0 green: 170.0/255.0 blue: 170.0/255.0 alpha: 1.0], // 3: Cyan
							[NSColor colorWithCalibratedRed: 170.0/255.0 green: 0.0 blue: 0.0 alpha: 1.0], // 4: Red
							[NSColor colorWithCalibratedRed: 170.0/255.0 green: 0.0 blue: 170.0/255.0 alpha: 1.0], // 5: Magenta
							[NSColor colorWithCalibratedRed: 170.0/255.0 green: 85.0/255.0 blue: 0.0 alpha: 1.0], // 6: Brown
							[NSColor colorWithCalibratedRed: 170.0/255.0 green: 170.0/255.0 blue: 170.0/255.0 alpha: 1.0], // 7: Light grey
							[NSColor colorWithCalibratedRed: 85.0/255.0 green: 85.0/255.0 blue: 85.0/255.0 alpha: 1.0], // 8: Dark grey
							[NSColor colorWithCalibratedRed: 85.0/255.0 green: 85.0/255.0 blue: 1.0 alpha: 1.0], // 9: Light blue
							[NSColor colorWithCalibratedRed: 85.0/255.0 green: 1.0 blue: 85.0/255.0 alpha: 1.0], // 10: Light green
							[NSColor colorWithCalibratedRed: 85.0/255.0 green: 1.0 blue: 1.0 alpha: 1.0], // 11: Light cyan
							[NSColor colorWithCalibratedRed: 1.0 green: 85.0/255.0 blue: 85.0/255.0 alpha: 1.0], // 12: Light red
							[NSColor colorWithCalibratedRed: 1.0 green: 85.0/255.0 blue: 1.0 alpha: 1.0], // 13: Light magenta
							[NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 85.0/255.0 alpha: 1.0], // 14: Yellow
							[NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 1.0 alpha: 1.0], // 15: White
						];
	
	// All 64 colors of the full EGA color palette.  Each color is paired up with a matching
	// color in the 16 color palette (above).
	NSDictionary *colorMatch = @{
		@"000000": @0,
		@"000055": @1,
		@"0000AA": @1,
		@"0000FF": @1,
		@"005500": @2,
		@"005555": @8,
		@"0055AA": @1,
		@"0055FF": @9,
		@"00AA00": @2,
		@"00AA55": @2,
		@"00AAAA": @3,
		@"00AAFF": @3,
		@"00FF00": @2,
		@"00FF55": @10,
		@"00FFAA": @3,
		@"00FFFF": @11,
		@"550000": @4,
		@"550055": @8,
		@"5500AA": @1,
		@"5500FF": @9,
		@"555500": @8,
		@"555555": @8,
		@"5555AA": @9,
		@"5555FF": @9,
		@"55AA00": @2,
		@"55AA55": @2,
		@"55AAAA": @3,
		@"55AAFF": @11,
		@"55FF00": @10,
		@"55FF55": @10,
		@"55FFAA": @10,
		@"55FFFF": @11,
		@"AA0000": @4,
		@"AA0055": @4,
		@"AA00AA": @5,
		@"AA00FF": @5,
		@"AA5500": @6,
		@"AA5555": @6,
		@"AA55AA": @5,
		@"AA55FF": @9,
		@"AAAA00": @2, // Originally was set to @6, but trees were too brown
		@"AAAA55": @7,
		@"AAAAAA": @7,
		@"AAAAFF": @7,
		@"AAFF00": @10,
		@"AAFF55": @10,
		@"AAFFAA": @7,
		@"AAFFFF": @11,
		@"FF0000": @4,
		@"FF0055": @12,
		@"FF00AA": @5,
		@"FF00FF": @13,
		@"FF5500": @12,
		@"FF5555": @12,
		@"FF55AA": @12,
		@"FF55FF": @13,
		@"FFAA00": @6,
		@"FFAA55": @14, // Was 12, changed to 14
		@"FFAAAA": @7,
		@"FFAAFF": @13,
		@"FFFF00": @14,
		@"FFFF55": @14,
		@"FFFFAA": @14,
		@"FFFFFF": @15
	};
    
	// Get the normalized color where each RGB component is set to either 0x00, 0x55, 0xAA, or 0xFF
	NSColor *updatedPixelColor = [self closerEGAColor:pixelColor];
	NSString *updatedPixelHexValue = [self convertNSColorToHex:updatedPixelColor];
	NSNumber *colorPaletteIndex = colorMatch[updatedPixelHexValue]; // Find the closest matching color in the 16-color palette

	return colorPalette[[colorPaletteIndex intValue]];
}


/// Find the closest EGA color to pixelColor using the CIE Lab color space
/// @param pixelColor RGB color for the current pixel
- (NSColor *) closestCIELabColor:(NSColor *)pixelColor {

	// Use CIE Lab colors to compare colors.
	int indexOfClosestColor = 0;
	double shortestDistance = 99999.0; // 255 * sqrt(3.0); // this probably needs to be updated, or use some MAX value
	NSArray *labColorPalette = @[	[CIELabColor colorWithNSColor:[NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.0 alpha: 1.0]], // 0: Black
								[CIELabColor colorWithNSColor:[NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 170.0/255.0 alpha: 1.0]], // 1: Blue
								[CIELabColor colorWithNSColor:[NSColor colorWithCalibratedRed: 0.0 green: 170.0/255.0 blue: 0.0 alpha: 1.0]], // 2: Green
								[CIELabColor colorWithNSColor:[NSColor colorWithCalibratedRed: 0.0 green: 170.0/255.0 blue: 170.0/255.0 alpha: 1.0]], // 3: Cyan
								[CIELabColor colorWithNSColor:[NSColor colorWithCalibratedRed: 170.0/255.0 green: 0.0 blue: 0.0 alpha: 1.0]], // 4: Red
								[CIELabColor colorWithNSColor:[NSColor colorWithCalibratedRed: 170.0/255.0 green: 0.0 blue: 170.0/255.0 alpha: 1.0]], // 5: Magenta
								[CIELabColor colorWithNSColor:[NSColor colorWithCalibratedRed: 170.0/255.0 green: 85.0/255.0 blue: 0.0 alpha: 1.0]], // 6: Brown
								[CIELabColor colorWithNSColor:[NSColor colorWithCalibratedRed: 170.0/255.0 green: 170.0/255.0 blue: 170.0/255.0 alpha: 1.0]], // 7: Light grey
								[CIELabColor colorWithNSColor:[NSColor colorWithCalibratedRed: 85.0/255.0 green: 85.0/255.0 blue: 85.0/255.0 alpha: 1.0]], // 8: Dark grey
								[CIELabColor colorWithNSColor:[NSColor colorWithCalibratedRed: 85.0/255.0 green: 85.0/255.0 blue: 1.0 alpha: 1.0]], // 9: Light blue
								[CIELabColor colorWithNSColor:[NSColor colorWithCalibratedRed: 85.0/255.0 green: 1.0 blue: 85.0/255.0 alpha: 1.0]], // 10: Light green
								[CIELabColor colorWithNSColor:[NSColor colorWithCalibratedRed: 85.0/255.0 green: 1.0 blue: 1.0 alpha: 1.0]], // 11: Light cyan
								[CIELabColor colorWithNSColor:[NSColor colorWithCalibratedRed: 1.0 green: 85.0/255.0 blue: 85.0/255.0 alpha: 1.0]], // 12: Light red
								[CIELabColor colorWithNSColor:[NSColor colorWithCalibratedRed: 1.0 green: 85.0/255.0 blue: 1.0 alpha: 1.0]], // 13: Light magenta
								[CIELabColor colorWithNSColor:[NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 85.0/255.0 alpha: 1.0]], // 14: Yellow
								[CIELabColor colorWithNSColor:[NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 1.0 alpha: 1.0]] // 15: White
						];
	NSArray *colorPalette = @[	[NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.0 alpha: 1.0], // 0: Black
							[NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 170.0/255.0 alpha: 1.0], // 1: Blue
							[NSColor colorWithCalibratedRed: 0.0 green: 170.0/255.0 blue: 0.0 alpha: 1.0], // 2: Green
							[NSColor colorWithCalibratedRed: 0.0 green: 170.0/255.0 blue: 170.0/255.0 alpha: 1.0], // 3: Cyan
							[NSColor colorWithCalibratedRed: 170.0/255.0 green: 0.0 blue: 0.0 alpha: 1.0], // 4: Red
							[NSColor colorWithCalibratedRed: 170.0/255.0 green: 0.0 blue: 170.0/255.0 alpha: 1.0], // 5: Magenta
							[NSColor colorWithCalibratedRed: 170.0/255.0 green: 85.0/255.0 blue: 0.0 alpha: 1.0], // 6: Brown
							[NSColor colorWithCalibratedRed: 170.0/255.0 green: 170.0/255.0 blue: 170.0/255.0 alpha: 1.0], // 7: Light grey
							[NSColor colorWithCalibratedRed: 85.0/255.0 green: 85.0/255.0 blue: 85.0/255.0 alpha: 1.0], // 8: Dark grey
							[NSColor colorWithCalibratedRed: 85.0/255.0 green: 85.0/255.0 blue: 1.0 alpha: 1.0], // 9: Light blue
							[NSColor colorWithCalibratedRed: 85.0/255.0 green: 1.0 blue: 85.0/255.0 alpha: 1.0], // 10: Light green
							[NSColor colorWithCalibratedRed: 85.0/255.0 green: 1.0 blue: 1.0 alpha: 1.0], // 11: Light cyan
							[NSColor colorWithCalibratedRed: 1.0 green: 85.0/255.0 blue: 85.0/255.0 alpha: 1.0], // 12: Light red
							[NSColor colorWithCalibratedRed: 1.0 green: 85.0/255.0 blue: 1.0 alpha: 1.0], // 13: Light magenta
							[NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 85.0/255.0 alpha: 1.0], // 14: Yellow
							[NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 1.0 alpha: 1.0], // 15: White
						];
	
	NSColor *updatedPixelColor = [self closerEGAColor:pixelColor];
	CIELabColor *labColor = [CIELabColor colorWithNSColor:updatedPixelColor];
	CGFloat l2 = [labColor lComponent];
	CGFloat a2 = [labColor aComponent];
	CGFloat b2 = [labColor bComponent];
	
	for (int i = 0; i < 16; i++)
	{
		CIELabColor *currentLabColor = labColorPalette[i];
		
		CGFloat l1 = [currentLabColor lComponent];
		CGFloat a1 = [currentLabColor aComponent];
		CGFloat b1 = [currentLabColor bComponent];
		CGFloat distance = sqrt(pow((l2 - l1), 2) + pow((a2 - a1), 2) + pow((b2 - b1), 2));
		
		if (distance == 0.0)
		{
			shortestDistance = distance;
			indexOfClosestColor = i;
			break;
		}
		else if (i == 0)
		{
			shortestDistance = distance;
			indexOfClosestColor = i;
		}
		else
		{
			// What if distance == shortestDistance?
			if (distance < shortestDistance)
			{
				shortestDistance = distance;
				indexOfClosestColor = i;
			}
		}
	}

	return colorPalette[indexOfClosestColor];
}

/// Finds the closest EGA color using a standard Euclidian calculation
/// @param pixelColor Original color
- (NSColor *) closestEGAColor:(NSColor *)pixelColor
{
	// Below was the original code that performed a mathematical calculation of the "closest" EGA
	// color, but some colors (especially yellows and greens) need more curation to ensure a more
	// "proper" color is selected.
	int indexOfClosestColor = 0;
	double shortestDistance = 255 * sqrt(3.0);
	NSArray *colorPalette = @[	[NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.0 alpha: 1.0], // 0: Black
							[NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 170.0/255.0 alpha: 1.0], // 1: Blue
							[NSColor colorWithCalibratedRed: 0.0 green: 170.0/255.0 blue: 0.0 alpha: 1.0], // 2: Green
							[NSColor colorWithCalibratedRed: 0.0 green: 170.0/255.0 blue: 170.0/255.0 alpha: 1.0], // 3: Cyan
							[NSColor colorWithCalibratedRed: 170.0/255.0 green: 0.0 blue: 0.0 alpha: 1.0], // 4: Red
							[NSColor colorWithCalibratedRed: 170.0/255.0 green: 0.0 blue: 170.0/255.0 alpha: 1.0], // 5: Magenta
							[NSColor colorWithCalibratedRed: 170.0/255.0 green: 85.0/255.0 blue: 0.0 alpha: 1.0], // 6: Brown
							[NSColor colorWithCalibratedRed: 170.0/255.0 green: 170.0/255.0 blue: 170.0/255.0 alpha: 1.0], // 7: Light grey
							[NSColor colorWithCalibratedRed: 85.0/255.0 green: 85.0/255.0 blue: 85.0/255.0 alpha: 1.0], // 8: Dark grey
							[NSColor colorWithCalibratedRed: 85.0/255.0 green: 85.0/255.0 blue: 1.0 alpha: 1.0], // 9: Light blue
							[NSColor colorWithCalibratedRed: 85.0/255.0 green: 1.0 blue: 85.0/255.0 alpha: 1.0], // 10: Light green
							[NSColor colorWithCalibratedRed: 85.0/255.0 green: 1.0 blue: 1.0 alpha: 1.0], // 11: Light cyan
							[NSColor colorWithCalibratedRed: 1.0 green: 85.0/255.0 blue: 85.0/255.0 alpha: 1.0], // 12: Light red
							[NSColor colorWithCalibratedRed: 1.0 green: 85.0/255.0 blue: 1.0 alpha: 1.0], // 13: Light magenta
							[NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 85.0/255.0 alpha: 1.0], // 14: Yellow
							[NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 1.0 alpha: 1.0], // 15: White
						];
	
	
	// Loop through all 16 possible EGA colors
	// Perform the calculation of how "far" pixelColor is from an EGA color
	// If the distance is 0, then it is a perfect match.  Stop looping.
	// Otherwise, keep looping and just keep track of the color with the "shortest" distance.
	// Side note: if we really wanted to get fancy, just cache each color into a dictionary
	// and initially do a look up to determine the best EGA color for a given color before
	// looping through.  But that would probably be a better solution for really large images.
	
	// Initial results: This seems to do well with greys and golds/browns, but fails
	// when it comes to colors like greens, blues, or yellows.  Perhaps increase the color saturation?
	// Would changing the color then resizing help?  That would be a lot more processing, though.
	// Updated experiments: Even with dithering, the green from trees tends to get washed out to
	// shades of grey and brown.
	
	NSColor *updatedPixelColor = [self closerEGAColor:pixelColor];
	CGFloat r2 = [updatedPixelColor redComponent];
	CGFloat g2 = [updatedPixelColor greenComponent];
	CGFloat b2 = [updatedPixelColor blueComponent];
	
	for (int i = 0; i < 16; i++)
	{
		NSColor *currentColor = colorPalette[i];
		
		CGFloat r1 = [currentColor redComponent];
		CGFloat g1 = [currentColor greenComponent];
		CGFloat b1 = [currentColor blueComponent];
		CGFloat rmean = (r1+r2)/2;
		int rCoefficient, gCoefficient, bCoefficient;
		
		// https://shihn.ca/posts/2020/dithering/
		// https://en.wikipedia.org/wiki/Color_difference
		// The human eye perceives certain colors stronger than others, so some adjustments are made.
		if (rmean < 0.5)
		{
			rCoefficient = 2;
			gCoefficient = 4;
			bCoefficient = 3;
		}
		else
		{
			rCoefficient = 3;
			gCoefficient = 4;
			bCoefficient = 2;
		}
		
		CGFloat r = r2 - r1;
		CGFloat g = g2 - g1;
		CGFloat b = b2 - b1;
		
		// Good old algebra used to calculate the distance between the color components in 3D space
		// Don't need to use sqrt since just need to find the closest, and running sqrt is just an
		// extra, expensive mathematical operation we don't need to use.
		// TODO:  Cache these values to speed up this process.
		// Another way to use things is to convert RGB to CIE Lab colorspace and perform the calculation that way,
		// but the difference might be negligible.

		// Simple Euclidean distance calculation.  The initial sqrt is removed to speed up this calculation
		// CGFloat distance = pow((r2 - r1), 2) + pow((g2 - g1), 2) + pow((b2 - b1), 2);
		
		// Weighted Euclidean distance calculations.
		// CGFloat distance = rCoefficient * pow((r2 - r1), 2) + gCoefficient * pow((g2 - g1), 2) + bCoefficient * pow((b2 - b1), 2);

		// This particular weighted calculation comes from the example at https://www.compuphase.com/cmetric.htm
		CGFloat distance = sqrt( (2 + rmean/256.0)*pow(r,2)) + (4 * pow(g, 2)) + ( (2 + (255 - rmean)/256.0)*pow(b, 2) );
		
		if (distance == 0.0)
		{
			shortestDistance = distance;
			indexOfClosestColor = i;
			break;
		}
		else if (i == 0)
		{
			shortestDistance = distance;
			indexOfClosestColor = i;
		}
		else
		{
			// What if distance == shortestDistance?
			if (distance < shortestDistance)
			{
				shortestDistance = distance;
				indexOfClosestColor = i;
			}
		}
	}

	return colorPalette[indexOfClosestColor];
}

/// Convert CIE Lab to RGB color
/// Note: This is unused and untested, but remains for potential future use
/// @param labColor CIE Lab color object
- (NSColor *) labToRgb:(CIELabColor *)labColor {
	
	CGFloat y = (labColor.lComponent + 16) / 116.0;
	CGFloat x = labColor.aComponent / 500.0 + y;
	CGFloat z = y - labColor.bComponent / 200.0;
	CGFloat r, g, b;

	x = 0.95047 * ((x * x * x > 0.008856) ? x * x * x : (x - 16 / 116.0) / 7.787);
	y = 1.00000 * ((y * y * y > 0.008856) ? y * y * y : (y - 16 / 116.0) / 7.787);
	z = 1.08883 * ((z * z * z > 0.008856) ? z * z * z : (z - 16 / 116.0) / 7.787);

	r = x * 3.2406 + y * -1.5372 + z * -0.4986;
	g = x * -0.9689 + y * 1.8758 + z * 0.0415;
	b = x * 0.0557 + y * -0.2040 + z * 1.0570;

	r = (r > 0.0031308) ? (1.055 * pow(r, 1 / 2.4) - 0.055) : 12.92 * r;
	g = (g > 0.0031308) ? (1.055 * pow(g, 1 / 2.4) - 0.055) : 12.92 * g;
	b = (b > 0.0031308) ? (1.055 * pow(b, 1 / 2.4) - 0.055) : 12.92 * b;
	
	// Verify that each r,g,b value is in the 0.0 to 1.0 range.
	r = MAX(0, MIN(1, r));
	g = MAX(0, MIN(1, g));
	b = MAX(0, MIN(1, b));
	
	NSColor *rgbColor = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0];
	
	return rgbColor;
}

/// Create a filter to resize a CIImage
/// @param widthScale The scale for the intended width
/// @param heightScale The scale for the intended height
/// @param image The original image to resize
- (CIFilter *) resizeFilter: (CGFloat)widthScale heightScale: (CGFloat)heightScale image: (CIImage *)image {
	
	// NOTE: https://boredzo.org/blog/archives/2010-02-06/nearest-neighbor-iu also has other examples
	// of nearest neighbor scaling
	CIFilter *resizeFilter = [CIFilter filterWithName:@"CIAffineTransform"];
	NSAffineTransform *affineTransform = [NSAffineTransform transform];
	[affineTransform scaleXBy: widthScale yBy: heightScale];
	[resizeFilter setValue:affineTransform forKey:@"inputTransform"];
	[resizeFilter setValue:image forKey:@"inputImage"];
	
	return resizeFilter;
}

/// De-make an image so it has the appearance of a computer game from the mid-1980s.
/// @param image The original image to de-make
/// @param userObject The user object
- (CIImage *) convert:(CIImage *)image userObject:(id)userObject {
	
	NSBitmapImageRep *initialBitmap = [[NSBitmapImageRep alloc] initWithCIImage: image];
	NSSize initialImageSize = [initialBitmap size];
	CGFloat scale = 320.0/initialImageSize.width;
	
	// Resize the image (retain the original ratio) to a width of 320 pixels
	CIFilter *initialResizeFilter = [self resizeFilter:scale heightScale:scale image:image];
	CIImage *initialResizedImage =  [initialResizeFilter valueForKey:@"outputImage"];
	
	// Squash the image horizontally so it is only 160 pixels in width, but the height is preserved.
	CIFilter *squashedResizeFilter = [self resizeFilter:0.5 heightScale: 1.0 image: initialResizedImage];
	CIImage *resizedImage = [squashedResizeFilter valueForKey:@"outputImage"];
		
	// NOTE: A couple of these CIFilters were used for experimentation and can easily be used in this plug-in.
			
	// Saturation
//	CIFilter *colorControlsFilter = [CIFilter filterWithName:@"CIColorControls"];
//	[colorControlsFilter setDefaults];
//	[colorControlsFilter setValue: image forKey:@"inputImage"];
//	[colorControlsFilter setValue: [NSNumber numberWithFloat: 2.0] forKey:@"inputSaturation"];
//	[colorControlsFilter setValue: [NSNumber numberWithFloat: 0.0] forKey:@"inputBrightness"];
//	[colorControlsFilter setValue: [NSNumber numberWithFloat: 1.0] forKey:@"inputContrast"];
//	CIImage *saturatedImage = [colorControlsFilter valueForKey:@"outputImage"];
	
	// Apply the Posterize CIFilter to reduce the number of colors
	// Color Posterize
//	CIFilter* posterize = [CIFilter filterWithName:@"CIColorPosterize"];
//	[posterize setDefaults];
//	[posterize setValue:[NSNumber numberWithDouble:4.0] forKey:@"inputLevels"];
//	[posterize setValue:resizedImage forKey:@"inputImage"];
//	CIImage *posterizeResult = [posterize valueForKey:@"outputImage"];
	
	// Cycle through each pixel and find the nearest color and replace it in the standard EGA palette
	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithCIImage: resizedImage];
	NSSize bitmapSize = [bitmap size];  // Get the size of the bitmap
	int height = (int)bitmapSize.height;
	int width = (int)bitmapSize.width;
	
	// Draw out the updated colors to the resizedBitmap to create the pixelated double-wide pixels look
	// This bitmap is twice the width of resizedImage
    NSBitmapImageRep *resizedBitmap = [[NSBitmapImageRep alloc]
              initWithBitmapDataPlanes:NULL
                            pixelsWide:width*2
                            pixelsHigh:height
                         bitsPerSample:8
                       samplesPerPixel:4
                              hasAlpha:YES
                              isPlanar:NO
                        colorSpaceName:NSCalibratedRGBColorSpace
                           bytesPerRow:0
                          bitsPerPixel:0];
    resizedBitmap.size = NSMakeSize(width*2, height);
	
	// Version 1.0
	// This algorithm only selects an estimated EGA color, but does not
	// implement any dithering algorithms to spread out the quantization error.
	// Use GCD to help parallelize this, otherwise this is noticeably slooooow
	// https://oleb.net/blog/2013/07/parallelize-for-loops-gcd-dispatch_apply/
	// https://www.objc.io/issues/2-concurrency/low-level-concurrency-apis/
	/*
	dispatch_apply(width, dispatch_get_global_queue(0, 0), ^(size_t x) {
		for (size_t y = 0; y < height; y++) {
			// https://ua.reonis.com/index.php?topic=3797.msg54893#msg54893
			// The above link mentions a very similar logic, except it then maps each of the possible 64 colors
			// to a 16 color EGA palette.
			NSColor *originalPixelColor = [bitmap colorAtX:x y:y];
			NSColor *newPixelColor = [self estimatedEGAColor: originalPixelColor];
			// NSColor *newPixelColor = [self closestEGAColor: originalPixelColor];
			
			// Draw out the double-wide pixel to resizedBitmap
			[resizedBitmap setColor: newPixelColor atX: (2*x) y: y];
			[resizedBitmap setColor: newPixelColor atX: (2*x)+1 y: y];
		}
	});
	 */
	
	
	// Version 2.0
	// Put new implementation here to get the current color from the image (try both the original and 64-EGA color variant)
	// find the closest 16 EGA color, then perform dithering.  The Floyd-Steinberg (F-S) dither is implemented, but
	// experiment with additional dithering algorithms later, or a serpentine progression
	// Because the dithering is applied, each of these calculations needs to be done sequentially and cannot be done
	// in parallel.
	for (size_t y = 0; y < height; y++) {
		for (size_t x = 0; x < width; x++) {
			// Get the current color, then find the closest EGA color
			NSColor *originalPixelColor = [bitmap colorAtX:x y:y];
			NSColor *newPixelColor = [self estimatedEGAColor: originalPixelColor];
			
			// Alternative methods for color selection
			// NSColor *newPixelColor = [self closestEGAColor: originalPixelColor]; // Euclidian
			// NSColor *newPixelColor = [self closestCIELabColor: originalPixelColor]; // CIE Lab
			
			// Calculate the diffusion error between the two colors
			NSColor *diffColor = [self subtractColors:originalPixelColor newColor:newPixelColor];
			
			// Distribute the error around the current pixel using the Floyd-Steinberg dithering algorithm
			// [x+1, y] -> 7/16
			if (x >= 0 && x < width && y >= 0 && y < height) {
				
				NSColor *nextColor = [bitmap colorAtX:x+1 y:y];
				// Need to multiply the diffusion error by the diffColor, then add the two colors
				CGFloat diffusionError = 7.0/16.0;
				// Need to apply the error fraction
				NSColor *diffColorWithError = [self multiplyColor:diffColor withDiffusionError:diffusionError];
				NSColor *diffusedColor = [self addColors:nextColor newColor:diffColorWithError];
				// Set the updated color in the source bitmap so the error propogates
				[bitmap setColor:diffusedColor atX:x+1 y:y];
			}
			
			// [x+1, y+1] -> 1/16
			if (x >= 0 && x < width && y >= 0 && y < height) {
				NSColor *nextColor = [bitmap colorAtX:x+1 y:y+1];
				// Need to multiply the diffusion error by the diffColor, then add the two colors
				CGFloat diffusionError = 1.0/16.0;
				// Need to apply the error fraction
				NSColor *diffColorWithError = [self multiplyColor:diffColor withDiffusionError:diffusionError];
				NSColor *diffusedColor = [self addColors:nextColor newColor:diffColorWithError];
				// Set the updated color in the source bitmap so the error propogates
				[bitmap setColor:diffusedColor atX:x+1 y:y+1];
			}
			
			// [x, y+1] -> 5/16
			if (x >= 0 && x < width && y >= 0 && y < height) {
				NSColor *nextColor = [bitmap colorAtX:x y:y+1];
				// Need to multiply the diffusion error by the diffColor, then add the two colors
				CGFloat diffusionError = 5.0/16.0;
				// Need to apply the error fraction
				NSColor *diffColorWithError = [self multiplyColor:diffColor withDiffusionError:diffusionError];
				NSColor *diffusedColor = [self addColors:nextColor newColor:diffColorWithError];
				// Set the updated color in the source bitmap so the error propogates
				[bitmap setColor:diffusedColor atX:x y:y+1];
			}
			
			// [x-1, y+1] -> 3/16
			if (x >= 0 && x < width && y >= 0 && y < height) {
				NSColor *nextColor = [bitmap colorAtX:x-1 y:y+1];
				// Need to multiply the diffusion error by the diffColor, then add the two colors
				CGFloat diffusionError = 3.0/16.0;
				// Need to apply the error fraction
				NSColor *diffColorWithError = [self multiplyColor:diffColor withDiffusionError:diffusionError];
				NSColor *diffusedColor = [self addColors:nextColor newColor:diffColorWithError];
				// Set the updated color in the source bitmap so the error propogates
				[bitmap setColor:diffusedColor atX:x-1 y:y+1];
			}
			
			// Draw out the double-wide pixel to resizedBitmap
			[resizedBitmap setColor: newPixelColor atX: (2*x) y: y];
			[resizedBitmap setColor: newPixelColor atX: (2*x)+1 y: y];
			
			// Used for single-width pixels
			// [resizedBitmap setColor: newPixelColor atX: x y: y];
		}
	}
	
	// Resize the canvas
	id <ACDocument> theDoc = [[NSDocumentController sharedDocumentController] currentDocument];
	NSSize newCanvasSize = NSMakeSize(initialImageSize.width*scale, initialImageSize.height*scale);
	[theDoc setCanvasSize: newCanvasSize];
	
	// Return the modified CIImage
	CIImage *outputImage = [[CIImage alloc] initWithBitmapImageRep: resizedBitmap];
		
	return outputImage;
}

- (NSColor *)addColors: (NSColor *)oldColor newColor: (NSColor *) newColor {
	CGFloat redDiff   = [oldColor redComponent] + [newColor redComponent];
	CGFloat greenDiff = [oldColor greenComponent] + [newColor greenComponent];
	CGFloat blueDiff  = [oldColor blueComponent] + [newColor blueComponent];
	NSColor *diffColor = [NSColor colorWithCalibratedRed: redDiff green: greenDiff blue: blueDiff alpha: 1.0];
	
	return diffColor;
}

- (NSColor *)subtractColors: (NSColor *)oldColor newColor: (NSColor *) newColor {
	CGFloat redDiff   = [oldColor redComponent] - [newColor redComponent];
	CGFloat greenDiff = [oldColor greenComponent] - [newColor greenComponent];
	CGFloat blueDiff  = [oldColor blueComponent] - [newColor blueComponent];
	NSColor *diffColor = [NSColor colorWithCalibratedRed: redDiff green: greenDiff blue: blueDiff alpha: 1.0];
	
	return diffColor;
}

- (NSColor *)multiplyColor: (NSColor *)oldColor withDiffusionError:(CGFloat) diffusionError {
	CGFloat redDiff   = [oldColor redComponent] * diffusionError;
	CGFloat greenDiff = [oldColor greenComponent] * diffusionError;
	CGFloat blueDiff  = [oldColor blueComponent] * diffusionError;
	NSColor *diffColor = [NSColor colorWithCalibratedRed: redDiff green: greenDiff blue: blueDiff alpha: 1.0];

	return diffColor;
}

// The next three CIE Lab related methods are not used, but remain here
// for potential future use.

- (CIELabColor *)addLabColors: (CIELabColor *)oldColor newColor: (CIELabColor *) newColor {
	CGFloat lDiff   = [oldColor lComponent] + [newColor lComponent];
	CGFloat aDiff = [oldColor aComponent] + [newColor aComponent];
	CGFloat bDiff  = [oldColor bComponent] + [newColor bComponent];
	CIELabColor *diffLabColor = [CIELabColor colorWithLuminance:lDiff a:aDiff b:bDiff];
	
	return diffLabColor;
}

- (CIELabColor *)subtractLabColors: (CIELabColor *)oldColor newColor: (CIELabColor *) newColor {
	CGFloat lDiff   = [oldColor lComponent] - [newColor lComponent];
	CGFloat aDiff = [oldColor aComponent] - [newColor aComponent];
	CGFloat bDiff  = [oldColor bComponent] - [newColor bComponent];
	CIELabColor *diffLabColor = [CIELabColor colorWithLuminance:lDiff a:aDiff b:bDiff];
	
	return diffLabColor;
}

- (CIELabColor *)multiplyLabColor: (CIELabColor *)oldColor withDiffusionError:(CGFloat) diffusionError {
	CGFloat lDiff   = [oldColor lComponent] * diffusionError;
	CGFloat aDiff = [oldColor aComponent] * diffusionError;
	CGFloat bDiff  = [oldColor bComponent] * diffusionError;
	CIELabColor *diffLabColor = [CIELabColor colorWithLuminance:lDiff a:aDiff b:bDiff];

	return diffLabColor;
}

@end
