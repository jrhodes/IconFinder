//
//  JRImageCollectionItemView.m
//  IconFinder
//
//  Created by Joe on 6/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "JRImageCollectionItemView.h"

@interface JRImageCollectionItemView ()

@end

@implementation JRImageCollectionItemView

static NSColor *gray;

+ (void)initialize
{
	gray = [NSColor colorWithCalibratedWhite:0.85 alpha:1.0f];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{	
	[super drawRect:dirtyRect];
	
	NSRect bounds = [self bounds];
	
	bounds = NSInsetRect(bounds, -1, -1);
	bounds = NSOffsetRect(bounds, -1, 1);
	
	[gray setFill];
	NSFrameRect(bounds);
}

@end
