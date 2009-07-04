/* UKShadowCopyAppDelegate */

#import <Cocoa/Cocoa.h>

@interface UKShadowCopyAppDelegate : NSObject
{
	NSStatusItem*					statusItem;
	NSMutableArray*					filesToCopy;
	NSMutableArray*					filesToCopyTo;
}

-(void)	listOneFolder: (NSString*)selectedFolder toFolder: (NSString*)destFolder;

-(void)	setStatus: (NSString*)str;
-(void)	turnOffStatusItem;

@end
