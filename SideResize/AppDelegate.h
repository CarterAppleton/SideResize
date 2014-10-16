//
//  AppDelegate.h
//  SideResize
//
//  Created by Carter Appleton on 9/14/14.
//  Copyright (c) 2014 Carter Appleton. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    IBOutlet NSMenu *statusMenu;
    
    NSStatusItem * statusItem;
}

- (IBAction)quitApp:(id)sender;


@end

