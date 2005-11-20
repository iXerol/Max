/*
 *  $Id$
 *
 *  Copyright (C) 2005 Stephen F. Booth <me@sbooth.org>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import "UpdateChecker.h"

static UpdateChecker *sharedController = nil;

@implementation UpdateChecker

- (id) init
{
	if((self = [super initWithWindowNibName:@"UpdateChecker"])) {
		_socket		= [[MacPADSocket alloc] init];

		[_socket setDelegate:self];

		[self setShouldCascadeWindows:NO];
		[self setWindowFrameAutosaveName:@"UpdateChecker"];	
	}
	return self;
}

+ (UpdateChecker *) sharedController
{
	@synchronized(self) {
		if(nil == sharedController) {
			sharedController = [[self alloc] init];
		}
	}
	return sharedController;
}

+ (id) allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if(nil == sharedController) {
            return [super allocWithZone:zone];
        }
    }
    return sharedController;
}

- (id) copyWithZone:(NSZone *)zone								{ return self; }
- (id) retain													{ return self; }
- (unsigned) retainCount										{ return UINT_MAX;  /* denotes an object that cannot be released */ }
- (void) release												{ /* do nothing */ }
- (id) autorelease												{ return self; }

- (void) dealloc
{
	[_socket release];
	[super dealloc];
}

- (void) checkForUpdate
{
	NSString *bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	[self showWindow:self];
	[_socket performCheck:[NSURL URLWithString:@"http://sbooth.org/Max/Max.plist"] withVersion:bundleVersion];
}

- (void) macPADErrorOccurred:(NSNotification *) aNotification
{
	NSWindow *updateWindow = [self window];

	if(YES == [updateWindow isVisible]) {
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle: @"OK"];
		[alert setMessageText: [[aNotification userInfo] objectForKey:MacPADErrorMessage]];
		[alert setInformativeText: @"MacPAD Error"];
		[alert setAlertStyle: NSWarningAlertStyle];
		
		[alert beginSheetModalForWindow:updateWindow modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
	}
}

- (void) macPADCheckFinished:(NSNotification *) aNotification
{
	NSWindow *updateWindow = [self window];
	
	if(YES == [updateWindow isVisible]) {
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle: @"OK"];
		if(kMacPADResultNoNewVersion == [[[aNotification userInfo] objectForKey:MacPADErrorCode] intValue]) {
			[alert setMessageText: @"Software up-to-date"];
			[alert setInformativeText: @"You are running the most current version of Max."];
		}
		else {
			[alert setMessageText: @"Newer version available"];
			[alert setInformativeText: [NSString stringWithFormat:@"Max %@ is available.", [_socket newVersion]]];
		}
		[alert setAlertStyle: NSWarningAlertStyle];
		
		[alert beginSheetModalForWindow:updateWindow modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
	}
}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	NSWindow *updateWindow = [self window];

	if(YES == [updateWindow isVisible]) {
		[updateWindow orderOut:self];
	}
}

@end