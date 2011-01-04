//
//  imageHelper.m
//  test
//
//  Pi

#import "AlphaMask.h"

// Private methods discussion here:
// http://stackoverflow.com/questions/172598/best-way-to-define-private-methods-for-a-class-in-objective-c
//Objective-C doesn't directly support private methods. Using an 
// empty category is an acceptably hacky way to achieve this effect.
@interface  AlphaMask () // <-- empty category

// each bit represents 1 pixel: will hold Yes/No for click-thru, 1=hit 0=click-thru
@property (nonatomic, retain) NSData* bitArray;

// note + means STATIC method
+ (NSData *) calcHitGridFromCGImage: (CGImageRef) img
		   alphaThreshold: (uint8_t) alphaThreshold_ ;
@end




@implementation AlphaMask

@synthesize bitArray = _bitArray;


#pragma mark Init stuff
/*
 See below for a more detailed discussion on alphaThreshold.  
 Basically if you set it to 0, the hit tester will only 
 pass through pixels that are 100% transparent
 
 Setting it to 64 would pass through all pixels 
 that are less than 25% transparent
 
 255 is the maximum. Setting to this, the image cannot 
 take a hit -- everything passes through.
 */
- (id) initWithThreshold: (uint8_t) alphaThreshold_
{
	self = [super init];
    if (!self) 
		return nil;	

	alphaThreshold = alphaThreshold_;
	self.bitArray = nil;
	imageWidth = 0;
	
	return [self init];
}

- (void) feedImage: (CGImageRef) img
{
	self.bitArray = [AlphaMask calcHitGridFromCGImage: img
						alphaThreshold: alphaThreshold];
	
	imageWidth = CGImageGetWidth(img);
}


#pragma mark Hit Test!
/*
 Ascertains, through looking up the relevant bit in our bit array 
 that pertains to this pixel, whether the pixel should take the hit
 (bit set to 1) or allow the click to pass through (bit set to 0).
 In order to minimise overhead, I am playing with C pointers directly.
 
 Note: for some reason, iOS seems to be hit testing each object
 three times -- which is bizarre, and another good reason for 
 spending as little time as possible inside this function.
 */
- (bool) hitTest: (CGPoint) p
{
	const uint8_t c_0x01 = 0x01; 
	
	if (!self.bitArray)
		return NO;
	
	// location of first byte
	uint8_t * pBitArray = (uint8_t *) [self.bitArray bytes];
	
	// the N'th pixel will lie in the n'th byte (one byte covers 8 pixels)
	size_t N = p.y * imageWidth + p.x;
	size_t n = N / (size_t) 8;
	uint8_t thisPixel = *(pBitArray + n) ;
	
	// mask with the bit we want
	uint8_t mask = c_0x01 << (N % 8);
	
	// nonzero => Yes absorb HIT, zero => No - click-thru
	return (thisPixel & mask) ? YES : NO;
}


#pragma mark Extract alphaMask from image!
// Constructs a compressed bitmap (one bit per pixel) that stores for each pixel
//     whether that pixel should accept the hit, or pass it through.
// If the pixels alpha value is zero, the pixel is transparent
// if the pixels alpha value > alphaThreshold, the corresponding bit is set to 1, 
//     indicating that this pixel is to receive a hit
//Note that setting alphaThreshold to 0 means that any pixel that is not 
//     100% transparent will receive a hit
+ (NSData *) calcHitGridFromCGImage: (CGImageRef) img
					 alphaThreshold: (uint8_t) alphaThreshold_
{
    CGContextRef    alphaContext = NULL;
    void *          alphaGrid;
	
    size_t w = CGImageGetWidth(img);
    size_t h = CGImageGetHeight(img);
    
	size_t bytesCount = w * h * sizeof(uint8_t);
	
	// allocate AND ZERO (so can't use malloc) memory for alpha-only context
	alphaGrid = calloc (bytesCount, sizeof(uint8_t));
    if (alphaGrid == NULL) 
	{
        fprintf (stderr, "calloc failed!");
        return nil;
    }
	
    // create alpha-only context
	alphaContext = CGBitmapContextCreate (alphaGrid, w, h, 8,   w, NULL, kCGImageAlphaOnly);
	if (alphaContext == NULL)
    {
        free (alphaGrid);
        fprintf (stderr, "Context not created!");
		return nil;
    } 
	
	// blat image onto alpha-only context
    CGRect rect = {{0,0},{w,h}}; 
    CGContextDrawImage(alphaContext, rect, img); 
    
    // grab alpha-only image-data
	void* _alphaData = CGBitmapContextGetData (alphaContext);
    if (!_alphaData)
	{
		CGContextRelease(alphaContext); 
		free (alphaGrid);
        return nil;
    }
	uint8_t *alphaData = (uint8_t *) _alphaData;
	
	// ---------------------------
	// compress to 1 bit per pixel
	// ---------------------------
		
	size_t srcBytes = bytesCount;
	size_t destBytes = srcBytes / (size_t) 8;
	if (srcBytes % 8)
		destBytes++;
	
	// malloc ok here, as we zero each target byte
	uint8_t* dest = malloc (destBytes);
    if (!dest) 
	{
		CGContextRelease(alphaContext); 
		free (alphaGrid);
        fprintf (stderr, "malloc failed!");
        return nil;
    }
	
	size_t iDestByte = 0;
	uint8_t target = 0x00, iBit = 0, c_0x01 = 0x01;
	
	for (size_t i=0; i < srcBytes; i++) 
	{
		uint8_t src = *(alphaData++);
		
		// set bit to 1 for 'takes hit', leave on 0 for 'click-thru'
		// alpha 0x00 is transparent
		// comparison fails famously if not using UNSIGNED data type
		if (src > alphaThreshold_)
			target |= (c_0x01 << iBit);
		
		iBit++;
		if (iBit > 7) 
		{
			dest[iDestByte] = target;
			target = 0x00;
			
			iDestByte++;
			iBit = 0;
		}
	}
	
	// COPIES buffer
	// is AUTORELEASED!
	// http://developer.apple.com/mac/library/documentation/Cocoa/Conceptual/MemoryMgmt/Articles/mmRules.html#//apple_ref/doc/uid/20000994-BAJHFBGH
	NSData* ret = [NSData dataWithBytes: (const void *) dest 
								 length: (NSUInteger) destBytes ];
	
	CGContextRelease (alphaContext);
	free (alphaGrid);
	free (dest);
	
	return ret;
}

@end
