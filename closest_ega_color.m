/*
 *	closest_ega_color.m
 *
 *	Description: Input a 6 character hex color code and get the closest 16-color EGA color
 * 	Author: Chad Armstrong (chad@edenwaith.com)
 *	Date: 12 December 2020
 *	To compile: gcc -w -framework Foundation -framework AppKit closest_ega_color.m -o closest_ega_color
 *	To run: ./closest_ega_color hex_color
 *
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h> // Used for images


NSColor * closestEGAColor(NSColor *pixelColor)
{
	NSArray *colorPalette = @[	[NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.0 alpha: 1.0], // Black - #000000
							[NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 170.0/255.0 alpha: 1.0], // Blue - #0000AA
							[NSColor colorWithCalibratedRed: 0.0 green: 170.0/255.0 blue: 0.0 alpha: 1.0], // Green - #00AA00
							[NSColor colorWithCalibratedRed: 0.0 green: 170.0/255.0 blue: 170.0/255.0 alpha: 1.0], // Cyan - #00AAAA
							[NSColor colorWithCalibratedRed: 170.0/255.0 green: 0.0 blue: 0.0 alpha: 1.0], // Red - #AA0000
							[NSColor colorWithCalibratedRed: 170.0/255.0 green: 0.0 blue: 170.0/255.0 alpha: 1.0], // Magenta - #AA00AA
							[NSColor colorWithCalibratedRed: 170.0/255.0 green: 85.0/255.0 blue: 0.0 alpha: 1.0], // Brown - #AA5500
							[NSColor colorWithCalibratedRed: 170.0/255.0 green: 170.0/255.0 blue: 170.0/255.0 alpha: 1.0], // Light grey - #AAAAAA
							[NSColor colorWithCalibratedRed: 85.0/255.0 green: 85.0/255.0 blue: 85.0/255.0 alpha: 1.0], // Dark grey - #555555
							[NSColor colorWithCalibratedRed: 85.0/255.0 green: 85.0/255.0 blue: 1.0 alpha: 1.0], // Light blue - #5555FF
							[NSColor colorWithCalibratedRed: 85.0/255.0 green: 1.0 blue: 85.0/255.0 alpha: 1.0], // Light green - #55FF55
							[NSColor colorWithCalibratedRed: 85.0/255.0 green: 1.0 blue: 1.0 alpha: 1.0], // Light cyan - #55FFFF
							[NSColor colorWithCalibratedRed: 1.0 green: 85.0/255.0 blue: 85.0/255.0 alpha: 1.0], // Light red - #FF5555
							[NSColor colorWithCalibratedRed: 1.0 green: 85.0/255.0 blue: 1.0 alpha: 1.0], // Light magenta - #FF55FF
							[NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 85.0/255.0 alpha: 1.0], // Yellow - #FFFF55
							[NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 1.0 alpha: 1.0], // White - #FFFFFF
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
    		if (distance <= shortestDistance)
    		{
    			shortestDistance = distance;
    			indexOfClosestColor = i;
    		}
    	}
    	    	
    	NSLog(@"i: %d distance: %f shortestDistance: %f indexOFClosestColor: %d", i, distance, shortestDistance, indexOfClosestColor);

    }
    
    NSLog(@"shortestDistance: %f indexOFClosestColor: %d", shortestDistance, indexOfClosestColor);

	return colorPalette[indexOfClosestColor];
}


NSColor* colorWithHexColorString(NSString *inColorString)
{
    NSColor* result = nil;
    unsigned colorCode = 0;
    unsigned char redByte, greenByte, blueByte;
    
    if (nil != inColorString)
    {
         NSScanner* scanner = [NSScanner scannerWithString:inColorString];
         (void) [scanner scanHexInt:&colorCode]; // ignore error
    }
    
    redByte = (unsigned char)(colorCode >> 16);
    greenByte = (unsigned char)(colorCode >> 8);
    blueByte = (unsigned char)(colorCode); // masks off high bits
    result = [NSColor
				colorWithCalibratedRed:(CGFloat)redByte / 0xff
				green:(CGFloat)greenByte / 0xff
				blue:(CGFloat)blueByte / 0xff
				alpha:1.0];
    
    return result;
}

NSString * convertNSColorToHex(NSColor *egaColor)
{
	NSString *hexString = nil;
	
	CGFloat red = [egaColor redComponent];
	CGFloat green = [egaColor greenComponent];
	CGFloat blue = [egaColor blueComponent];
	// CGFloat alpha = 0.0f;
	
	int redInt = (int)(red * 255.0);
	int greenInt = (int)(green * 255.0);
	int blueInt = (int)(blue * 255.0);
	
	hexString = [NSString stringWithFormat:@"%02X%02X%02X", redInt, greenInt, blueInt];
	
	return hexString;
}

int main(int argc, char *argv[]) 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if (argc < 2) {
		printf("usage: %s hex_color\n", argv[0]);
		exit(EXIT_FAILURE);
	}
	
	NSString *originalHexColor = [NSString stringWithUTF8String:argv[1]];
	NSColor *inputColor = colorWithHexColorString(originalHexColor);
	NSColor *closestEgaColor = closestEGAColor(inputColor);
	NSString *hexColor = convertNSColorToHex(closestEgaColor);
	
	NSLog(@"The closest EGA color to %@ is %@", originalHexColor, hexColor);
	
	[pool release];
	return 0;
}