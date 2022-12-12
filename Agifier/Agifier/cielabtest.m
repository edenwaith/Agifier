// To compile:  gcc -w -framework Cocoa cielabtest.m CIELabColor.m -o cielabtest

#import <Cocoa/Cocoa.h>
#import "CIELabColor.h"

int main (int argc, const char * argv[]) 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	CIELabColor *darkBlue = [CIELabColor colorWithNSColor:[NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 170.0/255.0 alpha: 1.0]];
	
	// The CIE Lab values for dark blue should be L: 19.648210815542775, a: 58.448615077311445, b: -79.60541052841837
	NSLog(@"CIE Lab values for dark blue:: L: %f a: %f b: %f", [darkBlue lComponent], [darkBlue aComponent], [darkBlue bComponent]);
	
	[pool drain];
	return 0;
}