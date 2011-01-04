//
//  IrregularShapedButton.h
//  Test
//
//  Pi

#import "clickThruButton.h"
#import "AlphaMask.h"

@interface clickThruButton ()

@property (nonatomic, retain) AlphaMask* alphaMask;

- (void) myInit;
- (void) setMask;

@end


@implementation clickThruButton

@synthesize alphaMask = _alphaMask;


/*
 To make this object versatile, we should allow for the possibility 
 that it is being used from IB, or directly from code. 
 By overriding both these functions, we can ensure that 
 however it is created, our custom initialiser gets called.
 */
#pragma mark init
// if irregButtons created from NIB
- (void)awakeFromNib
{
	[super awakeFromNib];
	[self myInit];	
}

// if irregButtons created or modified from code...
- (id) initWithFrame: (CGRect) aRect
{
	self = [super initWithFrame: aRect];
    if (self) 
		[self myInit];	
	return self;	
}

- (void) myInit
{
	// Set so that any alpha > 0x00 (transparent) sinks the click
	uint8_t threshold = 0x00;
	self.alphaMask = [[AlphaMask alloc]  initWithThreshold: threshold]; 
	[self setMask];
}


#pragma mark if image changes...
- (void) setBackgroundImage: (UIImage *) _image 
				   forState: (UIControlState) _state
{
    [super setBackgroundImage: _image 
					 forState: _state];
	[self setMask];
}

- (void) setImage: (UIImage *) _image 
		 forState: (UIControlState) _state
{
    [super setImage: _image 
		   forState: _state];
	[self setMask];
}


#pragma mark Set alphaMask
/*
 Note that we get redirected here from both our custom initialiser 
 and the image setter methods which we have overridden.
 
 We can't just override the setters -- if the object is loading from a 
 NIB these methods don't fire. Clearly it must set the iVars directly.
 
 This method should get invoked every time the buttons image changes.
 Because it needs to extract, process and compress the Alpha data, 
 in a way that our hit tester can access quickly.
 */
-(void) setMask
{
	UIImage *btnImage = [self imageForState: UIControlStateNormal];
	
	// If no image found, try for background image
	if (btnImage == nil) 
		btnImage = [self backgroundImageForState: UIControlStateNormal];
	
	if (btnImage == nil)  
	{
		self.alphaMask = nil;
		return ;
	}
	
	[self.alphaMask  feedImage: btnImage.CGImage];
}


#pragma mark Hit Test!
/* override pointInside:withEvent:
 Notice that we don't directly override hitTest. If you look at the 
 documentation you will see that this button's PARENT's hit tester 
 will check the pointInside methods of one of its children.
 */
- (BOOL) pointInside : (CGPoint) p  
		   withEvent : (UIEvent *) event
{
	// Optimisation check -- bounding box
	if (!CGRectContainsPoint(self.bounds, p))
		return NO;
	
	// Checks the point against alphaMask's precalculated bit array, 
	// to determine whether this point is allowed to register a hit
	bool ret = [self.alphaMask  hitTest: p];
	
	// If yes, send ' yes ' back to the parents hit tester, 
	// which will be one level up the call stack.  
	// So in this example, the parent will be the view, 
	// and it will check through all of its children until 
	// it finds one that responds with ' yes '
	return ret;
}


#pragma mark dealloc
- (void)dealloc
{
	[self.alphaMask release];
    [super dealloc];
}
@end
