//
//  JRCollectionView.m
//  IconFinder
//
//  Created by Joe on 7/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "JRCollectionView.h"

@implementation JRCollectionView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
    }
    
    return self;
}

- (void)mouseDown:(NSEvent *)theEvent
{
	[super mouseDown:theEvent];
	
	if (theEvent.clickCount == 2)
	{
		NSIndexSet *selections = [self selectionIndexes];
		NSUInteger firstIndex = [selections firstIndex];
		
		if( firstIndex == NSNotFound )
			return;

		NSCollectionViewItem *item = [self itemAtIndex:firstIndex];
		NSString *imagePath = [item representedObject];
		
		[[NSWorkspace sharedWorkspace] openFile:imagePath];
	}
}

@end
