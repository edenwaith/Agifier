/*
 *	agi_image_converter.m
 *
 *	Description: Convert an image to have the appearance of an AGI-era Sierra On-line
 *				 computer game (a la an early King's Quest or Space Quest game)
 * 	Author: Chad Armstrong (chad@edenwaith.com)
 *	Date: 5- July 2020
 *	To compile: gcc -w -framework Foundation -framework AppKit -framework QuartzCore agi_image_converter.m -o agi_image_converter
 *	To run: ./agi_image_converter path/to/image.png
 *
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h> // Used for images
#import <QuartzCore/CIFilter.h> // Used for CIFilter


NSImage * resizedImage(NSImage *sourceImage, NSSize newSize)
{
    if (! sourceImage.isValid) return nil;

    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
              initWithBitmapDataPlanes:NULL
                            pixelsWide:newSize.width
                            pixelsHigh:newSize.height
                         bitsPerSample:8
                       samplesPerPixel:4
                              hasAlpha:YES
                              isPlanar:NO
                        colorSpaceName:NSCalibratedRGBColorSpace
                           bytesPerRow:0
                          bitsPerPixel:0];
    rep.size = newSize;

    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *currentContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:rep];
    [currentContext setImageInterpolation: NSImageInterpolationNone]; // This generates a nearest neighbor resizing for glorious pixelated images
    [NSGraphicsContext setCurrentContext:currentContext];
    [sourceImage drawInRect:NSMakeRect(0, 0, newSize.width, newSize.height) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
    [NSGraphicsContext restoreGraphicsState];

    NSImage *newImage = [[NSImage alloc] initWithSize:newSize];
    [newImage addRepresentation:rep];
    return newImage;
}

NSColor * closestEGAColor(NSColor *pixelColor)
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
    
    int indexOfClosestColor = 0;
    double shortestDistance = 255 * sqrt(3.0);
    
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
    for (int i = 0; i < 16; i++)
    {
    	NSColor *currentColor = colorPalette[i];
    	
    	CGFloat r2 = [pixelColor redComponent];
    	CGFloat g2 = [pixelColor greenComponent];
    	CGFloat b2 = [pixelColor blueComponent];
    	
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

int main(int argc, char *argv[]) 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	
	// Specify the path to the WORDS.TOK file
	if (argc < 2) {
		printf("usage: %s path/to/image\n", argv[0]);
		exit(EXIT_FAILURE);
	}
	
	// Get the specified image path
	NSString *imagePath = [NSString stringWithUTF8String:argv[1]];
	NSLog(@"imagePath is %@", imagePath);
	
	// Import into an NSData object or NSImage
	NSImage *image = [[NSImage alloc] initWithContentsOfFile: imagePath];
	
	if (image == NULL)
	{
		NSLog(@"The image failed to load");
		return EXIT_FAILURE;
	}
	
	NSSize originalImageSize = [image size];
	double aspectRatio = 1.0;
	CGFloat newImageHeight = originalImageSize.height;
	CGFloat newImageWidth = originalImageSize.width;
	
	NSLog(@"Original width x height: %f x %f", newImageWidth, newImageHeight);
	
	// Resize the image to be no taller than 200 pixels in height (keep aspect ratio)
	if (originalImageSize.height > 200)
	{
		// Get the aspect ratio of the image
		aspectRatio = 200.0/originalImageSize.height;
		newImageHeight = 200.0;
		newImageWidth = newImageWidth * aspectRatio;
	}

	NSLog(@"New width x height: %f x %f", newImageWidth, newImageHeight);
	
	CGFloat halfImageWidth = newImageWidth / 2.0;	
	NSSize halfSize = NSMakeSize(halfImageWidth, newImageHeight);	
	NSSize previousSize = NSMakeSize(newImageWidth, newImageHeight);
	
	// Resize the image to half its original width (do not maintain the aspect ratio)
	NSImage *tempImage = resizedImage(image, halfSize);
	NSBitmapImageRep *posterizedBitmap = [[tempImage representations] objectAtIndex: 0];
	CIImage *inputImage = [[CIImage alloc] initWithBitmapImageRep: posterizedBitmap];
	
	// Convert bitmap into a CIImage and perform a CIColorPosterize CIFilter on it.
	// https://stackoverflow.com/questions/8738416/8-bitify-image-in-ios
	CIFilter* posterize = [CIFilter filterWithName:@"CIColorPosterize"];
	[posterize setDefaults];
	[posterize setValue:[NSNumber numberWithDouble:4.0] forKey:@"inputLevels"];
	[posterize setValue:inputImage forKey:@"inputImage"];
	
	CIImage *posterizeResult = [posterize valueForKey:@"outputImage"];
	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithCIImage: posterizeResult]; // (NSBitmapImageRep *)[[posterizedImage representations] objectAtIndex: 0];
		
	// Cycle through each pixel and find the nearest color and replace it in the standard EGA palette
	for (int x = 0; x < (int)halfImageWidth; x++)
	{
		for (int y = 0; y < (int)newImageHeight; y++)
		{
			NSColor *originalPixelColor = [bitmap colorAtX:x y:y];
			NSColor *newPixelColor = closestEGAColor(originalPixelColor);
			[bitmap setColor: newPixelColor atX: x y: y];
		}
	}
	
	// Convert bitmap back into an NSImage
	NSImage *colorizedImage = [[NSImage alloc] initWithSize:[bitmap size]];
	[colorizedImage addRepresentation: bitmap];
	
	// Resize the image's width back to normal so each pixel is now double-width
	NSImage *finalImage = resizedImage(colorizedImage, previousSize);

	// Save NSBitmapImageRep to an image and save to disk
	NSString *fileName = [imagePath stringByDeletingPathExtension];
	NSString *agiImagePath = [NSString stringWithFormat:@"%@_agi.png", fileName];
	
 	NSBitmapImageRep *imgRep = [[finalImage representations] objectAtIndex: 0];
 	NSData *data = [imgRep representationUsingType: NSPNGFileType properties: nil];
 	[data writeToFile: agiImagePath atomically: NO];
	
	[pool release];
	return 0;
}