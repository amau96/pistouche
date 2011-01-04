//
//  imageHelper.h
//  test
//
//  Pi

@interface  AlphaMask : NSObject
{ 
@private
	uint8_t alphaThreshold;
	size_t imageWidth;
	NSData* _bitArray;
}


- (id) initWithThreshold: (uint8_t) t;

- (void) feedImage: (CGImageRef) img;

- (bool) hitTest: (CGPoint) p;

// Private methods and properties defined in the .m

@end
