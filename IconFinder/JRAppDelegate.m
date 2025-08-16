//
//  JRAppDelegate.m
//  IconFinder
//
//  Created by Joe on 6/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "JRAppDelegate.h"


@interface JRAppDelegate ()

@property (strong) NSMutableArray *imagePaths;
@property (assign) IBOutlet NSSegmentedControl *filterSegment;
@property (strong) NSMutableSet *filters;
@property (strong) NSPredicate *filterPredicate;
@property (readonly) NSMutableArray *filteredImagePaths;
@property (strong) NSTask *findTask;

@end


@implementation JRAppDelegate

@synthesize window = _window;
@synthesize imagePaths;
@synthesize filterSegment;
@synthesize filters;
@synthesize filterPredicate;
@synthesize findTask;
@dynamic filteredImagePaths;

static NSArray *imageTypes;

+ (void)initialize
{
	imageTypes = [NSArray arrayWithObjects:@"jpeg", @"jpg", @"gif", @"png", @"icns", @"tiff", @"pdf", nil];
}

+ (NSSet *)keyPathsForValuesAffectingFilterPredicate
{
	return [NSSet setWithObjects:@"filters", nil];
}

+ (NSSet *)keyPathsForValuesAffectingImagePaths
{
	return [NSSet setWithObjects:@"filterPredicate", nil];
}

+(NSSet *)keyPathsForValuesAffectingFilteredImagePaths
{
	return [NSSet setWithObject:@"filterPredicate"];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSFileManager *fm = [NSFileManager defaultManager];
	self.filters = [NSMutableSet set];
	self.filterPredicate = [NSPredicate predicateWithValue:YES];
	
	if ([fm fileExistsAtPath:[self imagesPlistFilePath]])
	{
		self.imagePaths = [NSMutableArray arrayWithContentsOfFile:[self imagesPlistFilePath]];
	}
	else
	{
		self.imagePaths = [NSMutableArray array];
		[self findImages];
	}
	
	[self filterChanged:self.filterSegment];
}

- (void)findImages
{
	NSAlert *searchingAlert = [NSAlert alertWithMessageText:@"Searching your Mac for images..." 
											  defaultButton:@"Stop"
											alternateButton:nil  
												otherButton:nil 
								  informativeTextWithFormat:@"Please wait a moment."];
	NSProgressIndicator *progIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 200, 32)];
	[progIndicator setIndeterminate:YES];
	[progIndicator setDisplayedWhenStopped:NO];
	
	[searchingAlert setAccessoryView:progIndicator];
	
	[searchingAlert beginSheetModalForWindow:self.window 
							   modalDelegate:self 
							  didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) 
								 contextInfo:NULL];
	
	[progIndicator startAnimation:self];
	
	NSPipe *stdOut = [[NSPipe alloc] init];
	
	NSTask *find = [[NSTask alloc] init];
	[find setLaunchPath:@"/usr/bin/find"];
	NSString *arguments = @"/ -type f -and -name *.icns -or -name *.png -or -name *.tiff -or -name *.gif -or -name *.jpg -or -name *.jpeg -or -name *.pdf";
	[find setArguments:[arguments componentsSeparatedByString:@" "]];
	[find setStandardOutput:stdOut];
	self.findTask = find;
	
	NSFileHandle *fileHandle = [stdOut fileHandleForReading];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	[nc addObserverForName:NSFileHandleReadCompletionNotification object:fileHandle queue:nil usingBlock:^(NSNotification *note) {
		
		NSData *data = [[note userInfo] valueForKey:NSFileHandleNotificationDataItem];
		NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

		NSArray *paths  = [string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
		
		for (NSString *path in paths)
		{
			if ([imageTypes containsObject:[path pathExtension]]) {
				[self.imagePaths addObject:path];
				
				searchingAlert.informativeText = [NSString stringWithFormat:@"%ld images found.", 
												  [self.imagePaths count]];
			}
		}
		
		if ([find isRunning])
			[fileHandle readInBackgroundAndNotify];
		else
		{
			[self writeImagePaths];
		}
		
	}];
	
	[nc addObserverForName:NSTaskDidTerminateNotification 
					object:find 
					 queue:nil 
				usingBlock:^(NSNotification *note) {
					
					[self willChangeValueForKey:@"imagePaths"];
					[self didChangeValueForKey:@"imagePaths"];
					[[searchingAlert window] orderOut:self];
					[self filterChanged:self.filterSegment];
					self.findTask = nil;
		
	}];
	
	[find launch];
	[fileHandle readInBackgroundAndNotify];
}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	// User Canceled the search
	if (returnCode == NSAlertDefaultReturn)
	{
		[alert.window orderOut:self];
		
		if (self.findTask)
			[self.findTask terminate];
	}
}

- (void)writeImagePaths
{
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDirectory = NO;
	NSString *appSupport = [NSHomeDirectory() stringByAppendingFormat:@"/Library/Application Support/IconFinder"];
	
	if ( !([fm fileExistsAtPath:appSupport isDirectory:&isDirectory] && isDirectory) )
	{
		[fm createDirectoryAtPath:appSupport withIntermediateDirectories:YES attributes:nil error:nil];
	}
	
	NSString *imagePathsFile = [appSupport stringByAppendingPathComponent:@"imagePaths.plist"];
	
	[self.imagePaths writeToFile:imagePathsFile atomically:YES];
}

- (NSString*)imagesPlistFilePath
{
	return [NSHomeDirectory() stringByAppendingFormat:@"/Library/Application Support/IconFinder/imagePaths.plist"];
}

- (NSMutableArray*)filteredImagePaths
{
	return [[self.imagePaths filteredArrayUsingPredicate:self.filterPredicate] mutableCopy];
}

- (NSPredicate*)filterPredicate
{
	if ([self.filters count] > 0)
		return [NSPredicate predicateWithFormat:@"SELF.pathExtension IN %@", self.filters];
	else
		return [NSPredicate predicateWithValue:YES];
}

- (void)setFilterPredicate:(NSPredicate *)newFilterPredicate
{
	if (filterPredicate != newFilterPredicate)
	{
		filterPredicate = newFilterPredicate;
	}
}

- (IBAction)filterChanged:(id)sender
{
	[self willChangeValueForKey:@"filters"];
	
	[self.filters removeAllObjects];
	NSInteger numSegments = [self.filterSegment segmentCount];
	
	for (NSInteger index = 0; index < numSegments; index++)
	{
		if ([self.filterSegment isSelectedForSegment:index])
		{
			NSString *filterName = [self.filterSegment labelForSegment:index];
			[self.filters addObject:filterName];
			[self.filters addObject:[filterName uppercaseString]];
		}
	}
	
	[self didChangeValueForKey:@"filters"];
}

- (IBAction)removeImageCache:(id)sender
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *cacheFile = [self imagesPlistFilePath];
	
	if ([fm fileExistsAtPath:cacheFile])
	{
		[fm removeItemAtPath:cacheFile error:nil];
		[self findImages];
		self.imagePaths = [NSMutableArray array];
	}
}

@end
