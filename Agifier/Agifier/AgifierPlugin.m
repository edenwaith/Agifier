//
//  AgifierPlugin.m
//  Agifier
//
//  Created by Chad Armstrong on 7/15/20.
//  Copyright © 2020 Edenwaith. All rights reserved.
//
//	Copy this plug-in to the ~/Library/Application Support/Acorn/Plug-Ins folder

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

// In hex, each component can only be 00, 55, AA, or FF (0, 85, 170, 255)
// 00 = 0 = 0
// 55 = 85 = 0.333333
// AA = 170 = 0.6666667
// FF = 255 = 1.0
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
// Each color component is marked at internvals of thirds (0, 1/3, 2/3, 1), which in hex is 0x00, 0x55, 0xAA, 0xFF.
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

/// Calculate and return the closest EGA color to the given pixelColor
/// Note: There are still issues with trying to select a proper EGA color
/// Might need to saturate the colors or determine a better algorithm to
/// choose better colors so things like grass and leaves will be some shade
/// of green instead of grey, black, or brown.
/// @param pixelColor The color of the current pixel
- (NSColor *) closestEGAColor:(NSColor *)pixelColor
{
	NSArray *colorPalette = @[	[NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.0 alpha: 1.0], // Black
							[NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 170.0/255.0 alpha: 1.0], // Blue
							[NSColor colorWithCalibratedRed: 0.0 green: 170.0/255.0 blue: 0.0 alpha: 1.0], // Green
							[NSColor colorWithCalibratedRed: 0.0 green: 170.0/255.0 blue: 170.0/255.0 alpha: 1.0], // Cyan
							[NSColor colorWithCalibratedRed: 170.0/255.0 green: 0.0 blue: 0.0 alpha: 1.0], // Red
							[NSColor colorWithCalibratedRed: 170.0/255.0 green: 0.0 blue: 170.0/255.0 alpha: 1.0], // Magenta
							[NSColor colorWithCalibratedRed: 170.0/255.0 green: 85.0/255.0 blue: 0.0 alpha: 1.0], // Brown
							[NSColor colorWithCalibratedRed: 170.0/255.0 green: 170.0/255.0 blue: 170.0/255.0 alpha: 1.0], // Light grey
							[NSColor colorWithCalibratedRed: 85.0/255.0 green: 85.0/255.0 blue: 85.0/255.0 alpha: 1.0], // Dark grey
							[NSColor colorWithCalibratedRed: 85.0/255.0 green: 85.0/255.0 blue: 1.0 alpha: 1.0], // Light blue
							[NSColor colorWithCalibratedRed: 0.0 green: 1.0 blue: 85.0/255.0 alpha: 1.0], // Light green
							[NSColor colorWithCalibratedRed: 85.0/255.0 green: 1.0 blue: 1.0 alpha: 1.0], // Light cyan
							[NSColor colorWithCalibratedRed: 1.0 green: 85.0/255.0 blue: 85.0/255.0 alpha: 1.0], // Light red
							[NSColor colorWithCalibratedRed: 1.0 green: 85.0/255.0 blue: 1.0 alpha: 1.0], // Light magenta
							[NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 85.0/255.0 alpha: 1.0], // Yellow
							[NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 1.0 alpha: 1.0], // White
						];
    
    // Generating a random number just to check that this works and the image isn't one solid color
//     int lowerBound = 0;
//     int upperBound = 15;
//     int rndValue = lowerBound + arc4random() % (upperBound - lowerBound);
    int indexOfClosestColor = 0;
    double shortestDistance = 255 * sqrt(3.0);
    
	NSColor *updatedPixelColor = [self closerEGAColor:pixelColor];
	
    // Loop through all 16 possible EGA colors
    // Perform the calculation of how "far" pixelColor is from an EGA color
    // If the distance is 0, then it is a perfect match.  Stop looping.
    // Otherwise, keep looping and just keep track of the color with the "shortest" distance.
    // Side note: if we really wanted to get fancy, just cache each color into a dictionary
    // and initially do a look up to determine the best EGA color for a given color before
    // looping through.  But that would probably be a better solution for really large images.
    // If I really wanted to get fancy, perform a bunch of parallel computations and then check
    // what is the shortest distance.  There is probably some incredibly computer science-y
    // method of doing that.
    
    // Initial results: This seems to do well with greys and golds/browns, but fails
    // when it comes to colors like greens or blues.  Perhaps increase the color saturation?
    // Would changing the color then resizing help?  That would be a lot more processing, though.
    
	CGFloat r2 = [updatedPixelColor redComponent];
	CGFloat g2 = [updatedPixelColor greenComponent];
	CGFloat b2 = [updatedPixelColor blueComponent];
	
    for (int i = 0; i < 16; i++)
    {
    	NSColor *currentColor = colorPalette[i];
    	
    	CGFloat r1 = [currentColor redComponent];
    	CGFloat g1 = [currentColor greenComponent];
    	CGFloat b1 = [currentColor blueComponent];
    	
    	CGFloat distance = sqrt(pow((r2 - r1), 2) + pow((g2 - g1), 2) + pow((b2 - b1), 2));
    	
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
    // NSLog(@"shortestDistance: %f indexOFClosestColor: %d", shortestDistance, indexOfClosestColor);

	return colorPalette[indexOfClosestColor];
}

- (CIImage*) convert:(CIImage*)image userObject:(id)userObject {
	
	CGFloat scale = 1.0;
	
//	CIFilter *filter = [CIFilter filterWithName:@"CILanczosScaleTransform"]; // NSImageInterpolationNone
//    [filter setValue:image forKey:@"inputImage"];
//    [filter setValue:@(scale) forKey:@"inputScale"];
//    [filter setValue:@1.0 forKey:@"inputAspectRatio"];
//    CIImage *resizedImage = filter.outputImage;
	
	NSBitmapImageRep *initialBitmap = [[NSBitmapImageRep alloc] initWithCIImage: image];
	NSSize initialImageSize = [initialBitmap size];
	
	scale = 200.0/initialImageSize.height;
	
	// https://boredzo.org/blog/archives/2010-02-06/nearest-neighbor-iu
//	CIFilter * scaler = [CIFilter filterWithName:@"CIPixellate"];
//	[scaler setDefaults];
//	[scaler setValue:[NSNumber numberWithFloat:4] forKey:@"inputScale"];
//	[scaler setValue:image forKey:@"inputImage"];
//	CIImage *pixelatedImage = [scaler valueForKey:@"outputImage"];

	// Saturation?
//	CIFilter *colorControlsFilter = [CIFilter filterWithName:@"CIColorControls"];
//	[colorControlsFilter setDefaults];
//	[colorControlsFilter setValue: image forKey:@"inputImage"];
//	[colorControlsFilter setValue: [NSNumber numberWithFloat: 2.0] forKey:@"inputSaturation"];
//	[colorControlsFilter setValue: [NSNumber numberWithFloat: 0.0] forKey:@"inputBrightness"];
//	[colorControlsFilter setValue: [NSNumber numberWithFloat: 1.0] forKey:@"inputContrast"];
//	CIImage *saturatedImage = [colorControlsFilter valueForKey:@"outputImage"];
	
	// Resize the image using a CIAffineTransform filter.  A nearest neighbor approach would be even better
	CIFilter *resizeFilter = [CIFilter filterWithName:@"CIAffineTransform"];
	NSAffineTransform *affineTransform = [NSAffineTransform transform];
	[affineTransform scaleXBy: scale yBy: scale];
	[resizeFilter setValue:affineTransform forKey:@"inputTransform"];
	[resizeFilter setValue:image forKey:@"inputImage"];
	// [resizeFilter setValue:saturatedImage forKey:@"inputImage"];
	CIImage *resizedImage = [resizeFilter valueForKey:@"outputImage"];
	
	// Apply the Posterize CIFilter to reduce the number of colors
//	CIFilter* posterize = [CIFilter filterWithName:@"CIColorPosterize"];
//	[posterize setDefaults];
//	[posterize setValue:[NSNumber numberWithDouble:4.0] forKey:@"inputLevels"];
//	[posterize setValue:resizedImage forKey:@"inputImage"];
//	CIImage *posterizeResult = [posterize valueForKey:@"outputImage"];
	
	// Cycle through each pixel and find the nearest color and replace it in the standard EGA palette
	// The performance of this sucks horribly and really could be optimized and parallellized
	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithCIImage: resizedImage];
	// NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithCIImage: posterizeResult]; // If I want to posterize the image
	NSSize bitmapSize = [bitmap size];  // Get the size of the bitmap
	int height = (int)bitmapSize.height;
	int width = (int)bitmapSize.width;
		
	// https://oleb.net/blog/2013/07/parallelize-for-loops-gcd-dispatch_apply/
	// https://www.objc.io/issues/2-concurrency/low-level-concurrency-apis/
	dispatch_apply(width, dispatch_get_global_queue(0, 0), ^(size_t x) {
		for (size_t y = 0; y < height; y++) {
			NSColor *originalPixelColor = [bitmap colorAtX:x y:y];
			// NSColor *newPixelColor = [self closestEGAColor: originalPixelColor];
			NSColor *newPixelColor = [self closerEGAColor: originalPixelColor];
			[bitmap setColor: newPixelColor atX: x y: y];
		}
	});
	
	// Resize the canvas
	id <ACDocument> theDoc = [[NSDocumentController sharedDocumentController] currentDocument];
	NSSize newCanvasSize = NSMakeSize(initialImageSize.width*scale, initialImageSize.height*scale);
	[theDoc setCanvasSize: newCanvasSize];
	
	// Return the modified CIImage
	CIImage *outputImage = [[CIImage alloc] initWithBitmapImageRep: bitmap];
	
	return outputImage;
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
