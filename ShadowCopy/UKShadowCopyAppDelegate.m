// -----------------------------------------------------------------------------
//	Headers:
// -----------------------------------------------------------------------------

#import "UKShadowCopyAppDelegate.h"
#import "NDAlias+AliasFile.h"
#import "NSWorkspace+TypeOfVolumeAtPath.h"


@implementation UKShadowCopyAppDelegate

// -----------------------------------------------------------------------------
//	awakeFromNib:
//		Register for volume-mounted notifications and show our menu bar icon for
//		a moment so users get a vague idea that something just launched.
//
//	REVISIONS:
//		2005-08-27	UK	Documented. Commented out wrong workspace notification
//						registration.
// -----------------------------------------------------------------------------

-(void)	awakeFromNib
{
	NSWorkspace*			ws = [NSWorkspace sharedWorkspace];
	NSNotificationCenter*	cent = [ws notificationCenter];
	
	//[cent addObserver: self selector:@selector(volumeMounted:) name: NSWorkspaceDidMountNotification object: cent];
	[cent addObserver: self selector:@selector(volumeMounted:) name: NSWorkspaceDidMountNotification object: ws];
	
	// Set up our status icon and let the user see it for a moment:
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength: 30] retain];
	[statusItem setTarget: self];			// IIRC it refuses to display if I don't set up a target.
	[statusItem setImage: [NSImage imageNamed: @"SCOnBarIcon"]];
	
	[self turnOffStatusItem];
}


// -----------------------------------------------------------------------------
//	* DESTRUCTOR:
//		Unregister our notification and remove our status item.
//		(Never called, as AppKit doesn't dispose of delegates)
//
//	REVISIONS:
//		2005-08-27	UK	Documented.
// -----------------------------------------------------------------------------

-(void)	dealloc
{
	NSNotificationCenter*	cent = [[NSWorkspace sharedWorkspace] notificationCenter];
	[cent removeObserver: self];
	
	[statusItem release];
	
	[super dealloc];
}


// -----------------------------------------------------------------------------
//	volumeMounted:
//		A volume was just mounted. Check whether it's a DVD or CD (can't detect
//		other media types, sadly) and if it is, index that volume.
//
//	REVISIONS:
//		2005-08-27	UK	Documented. Added volume type check to avoid indexing
//						network volumes. You can still index them via drag-
//						and-drop, though.
// -----------------------------------------------------------------------------

-(void)	volumeMounted: (NSNotification*)notif
{
	NSString*	volumeNodePath = [[notif userInfo] objectForKey: @"NSDevicePath"];
	NSString*	type = [[NSWorkspace sharedWorkspace] typeOfVolumeAtPath: volumeNodePath];
	
	if( type == UKVolumeCDMediaType || type == UKVolumeDVDMediaType )
		[self application: NSApp openFile: volumeNodePath];
}


// -----------------------------------------------------------------------------
//	setStatus:
//		Show our menu bar icon, display a string next to it and make sure the
//		item is wide enough to fully show the string.
//
//	REVISIONS:
//		2005-08-27	UK	Documented.
// -----------------------------------------------------------------------------

-(void)	setStatus: (NSString*)str
{
	NSDictionary*		attrs = [NSDictionary dictionaryWithObjectsAndKeys: [NSFont menuBarFontOfSize: 14], NSFontAttributeName, nil];
	[statusItem setTitle: str];
	[statusItem setLength: 30 +[str sizeWithAttributes: attrs].width];
}


// -----------------------------------------------------------------------------
//	turnOffStatusItem:
//		Hide our menu bar icon again so we don't use up valuable menu bar space.
//		This has a built-in delay so user sees it even on fast Macs or with few
//		files on a disk.
//
//	REVISIONS:
//		2005-08-27	UK	Documented.
// -----------------------------------------------------------------------------

-(void)	turnOffStatusItem
{
	[NSTimer scheduledTimerWithTimeInterval: 3.0 target: self selector: @selector(actuallyTurnOffStatusItem:)
			userInfo: nil repeats: NO];
}


// -----------------------------------------------------------------------------
//	actuallyTurnOffStatusItem:
//		Called by turnOffStatusItem's timer to actually perform the hiding of
//		our status item once the delay has passed.
//
//	REVISIONS:
//		2005-08-27	UK	Documented.
// -----------------------------------------------------------------------------

-(void)	actuallyTurnOffStatusItem: (NSTimer*)timer
{
	[statusItem setEnabled: NO];
	[statusItem setLength: 0];
}


// -----------------------------------------------------------------------------
//	application:openFile:
//		Application delegate method. When a user drops a file on our app's icon,
//		this method is called to index it. Note that this is also called by
//		this app itself whenever a DVD or CD is mounted. I.e. we're abusing
//		this as our main bottleneck for processing disks.
//
//	REVISIONS:
//		2005-08-27	UK	Documented.
// -----------------------------------------------------------------------------

-(BOOL)	application: (NSApplication*)sender openFile: (NSString*)filename
{
	// Show status item so user knows we've started using some CPU:
	[statusItem setEnabled: YES];
	[self setStatus: @"0/0"];
	
	// Create disk index folder if there is none:
	NSString*	rootFolder = [@"~/DiskIndex/" stringByExpandingTildeInPath];
	
	[[NSFileManager defaultManager] createDirectoryAtPath: rootFolder attributes: [NSDictionary dictionary]];	// Ignore result. If it failed, we very likely already have a folder. Should probably check whether it's not a file, tho'...
	
	NSString*		newFolder = [rootFolder stringByAppendingPathComponent: [filename lastPathComponent]];
	
	if( [[NSFileManager defaultManager] fileExistsAtPath: newFolder] )	// No need to check if it's a folder, too: If it isn't, we can't just go and replace it.
	{
		[self turnOffStatusItem];
		return YES;		// Already indexed.
	}
	
	// Create list of files so we can give accurate status feedback:
	[filesToCopy release];
	filesToCopy = [[NSMutableArray alloc] init];
	[filesToCopyTo release];
	filesToCopyTo = [[NSMutableArray alloc] init];
	
	NSAutoreleasePool*	pool = [[NSAutoreleasePool alloc] init];
	[self listOneFolder: filename toFolder: newFolder];
	[pool release];
	
	// Now process list:
	NSEnumerator*	srcEnny = [filesToCopy objectEnumerator];
	NSEnumerator*	dstEnny = [filesToCopyTo objectEnumerator];
	NSString*		srcPath = nil;
	NSString*		dstPath = nil;
	int				x = 0, count = [filesToCopy count];
	
	while( (srcPath = [srcEnny nextObject]) && (dstPath = [dstEnny nextObject]) )
	{
		x++;
		
		// Create a new directory for this one, or create an alias if it's a file or package:
		BOOL		isDir = NO;
		[[NSFileManager defaultManager] fileExistsAtPath: srcPath isDirectory: &isDir];
		if( isDir && ![[NSWorkspace sharedWorkspace] isFilePackageAtPath: srcPath] )
			[[NSFileManager defaultManager] createDirectoryAtPath: dstPath attributes: [NSDictionary dictionary]];
		else
		{
			NDAlias*	ali = [[NDAlias alloc] initWithPath: srcPath];
			[ali writeToFile: dstPath];
			[ali release];
		}
		
		// Every 16 files, update status and process some events to avoid beach ball or penalty by OS:
		if( (x & 0x0F) == 0x0F )
		{
			[self setStatus: [NSString stringWithFormat: @"%d/%d", x, count]];
			
			NSEvent* evt = [NSApp nextEventMatchingMask: NSAnyEventMask untilDate: [NSDate distantPast] inMode: NSModalPanelRunLoopMode dequeue: YES];	
			if( evt )
				[NSApp sendEvent: evt];
		}
	}
	
	// Make status look completed (user sees that due to delayed-turn-off):
	//	(Since we only update every 16 items, it may not be current otherwise)
	[self setStatus: [NSString stringWithFormat: @"%d/%d", count, count]];
	[filesToCopy release];
	filesToCopy = nil;
	[filesToCopyTo release];
	filesToCopyTo = nil;
	
	[self turnOffStatusItem];	// Give back precious menu bar space.
	
	return YES;
}


// -----------------------------------------------------------------------------
//	listOneFolder:toFolder:
//		Add a folder and all its files to our list of files to copy, and also
//		create the proper destination path and stuff it in the list of paths to
//		copy to. Recursively calls itself for any subfolders and processes
//		events each time through the loop. Also updates the status icon's count
//		of files to be processed.
//
//	REVISIONS:
//		2005-08-27	UK	Documented.
// -----------------------------------------------------------------------------

-(void)	listOneFolder: (NSString*)selectedFolder toFolder: (NSString*)destFolder
{
	[filesToCopy addObject: selectedFolder];
	[filesToCopyTo addObject: destFolder];
	
	NSDirectoryEnumerator*	enny = [[NSFileManager defaultManager] enumeratorAtPath: selectedFolder];
	NSString*				currName = nil;
	int						x = 0;
	
	while( (currName = [enny nextObject]) )
	{
		[enny skipDescendents];
		x++;
		
		if( [currName characterAtIndex: 0] == '.' )	// Ignore hidden files. TODO: Should check for hidden flag in HFS metadata here, too!
			continue;
		
		NSString*		srcPath = [selectedFolder stringByAppendingPathComponent: currName];
		NSString*		dstPath = [destFolder stringByAppendingPathComponent: currName];
		
		[filesToCopy addObject: srcPath];
		[filesToCopyTo addObject: dstPath];
		
		// Every 16 items, update the count and process events to avoid the beach ball:
		if( (x & 0x0F) == 0x0F )
		{
			[self setStatus: [NSString stringWithFormat: @"0/%d", [filesToCopy count]]];
			
			NSEvent* evt = [NSApp nextEventMatchingMask: NSAnyEventMask untilDate: [NSDate distantPast] inMode: NSModalPanelRunLoopMode dequeue: YES];	
			if( evt )
				[NSApp sendEvent: evt];
		}
		
		// Is subfolder? Process that, too:
		if( [[enny fileAttributes] fileType] == NSFileTypeDirectory )
		{
			if( ![[NSWorkspace sharedWorkspace] isFilePackageAtPath: srcPath] )
			{
				NSAutoreleasePool*	pool = [[NSAutoreleasePool alloc] init];
				[self listOneFolder: srcPath toFolder: dstPath];
				[pool release];
			}
		}
	}
}

@end
