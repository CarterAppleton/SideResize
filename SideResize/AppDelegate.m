//
//  AppDelegate.m
//  SideResize
//
//  Created by Carter Appleton on 9/14/14.
//  Copyright (c) 2014 Carter Appleton. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (nonatomic, retain) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

typedef enum {
    kWindowLocationNone = 0,
    kWindowLocationTop,
    kWindowLocationRight,
    kWindowLocationLeft,
    kWindowLocationTopRight,
    kWindowLocationTopLeft,
} WindowLocation;

static AXUIElementRef _clickedWindow = NULL;

WindowLocation getLocationFromMouseLocation(CGPoint mouseLocation) {
    CGSize screenSize = [[NSScreen mainScreen] frame].size;
    if(mouseLocation.y == 0.0) {
        return kWindowLocationTop;
    }else if(mouseLocation.x == 0.0) {
        return kWindowLocationLeft;
    }else if(mouseLocation.x >= screenSize.width - 1.0) {
        return kWindowLocationRight;
    }
    return kWindowLocationNone;
}

CGRect rectForWindowLocation(WindowLocation windowLocation, CGRect visibleRect) {
    CGSize wndSize = visibleRect.size;
    CGPoint wndLoc = visibleRect.origin;
    switch (windowLocation) {
        case kWindowLocationTop:
            wndSize = visibleRect.size;
            wndLoc = visibleRect.origin;
            break;
        case kWindowLocationRight:
            wndSize = CGSizeMake(visibleRect.size.width/2,visibleRect.size.height);
            wndLoc = CGPointMake(visibleRect.origin.x+visibleRect.size.width/2,visibleRect.origin.y);
            break;
        case kWindowLocationLeft:
            wndSize = CGSizeMake(visibleRect.size.width/2,visibleRect.size.height);
            wndLoc = visibleRect.origin;
            break;
        case kWindowLocationNone:
            return CGRectNull;
            
        default:
            break;
    }
    
    return CGRectMake(wndLoc.x, wndLoc.y, wndSize.width, wndSize.height);
}

AXUIElementRef windowForMouseLocation(CGPoint mouseLocation) {
    AXUIElementRef _systemWideElement;
    _systemWideElement = AXUIElementCreateSystemWide();
    AXUIElementRef _element;
    if ((AXUIElementCopyElementAtPosition(_systemWideElement, (float) mouseLocation.x, (float) mouseLocation.y, &_element) == kAXErrorSuccess) && _element) {
        CFTypeRef _role;
        if (AXUIElementCopyAttributeValue(_element, (__bridge CFStringRef)NSAccessibilityRoleAttribute, &_role) == kAXErrorSuccess) {
            if ([(__bridge NSString *)_role isEqualToString:NSAccessibilityWindowRole]) {
                return _element;
            }
            if (_role != NULL) CFRelease(_role);
        }
        CFTypeRef _window;
        if (AXUIElementCopyAttributeValue(_element, (__bridge CFStringRef)NSAccessibilityWindowAttribute, &_window) == kAXErrorSuccess) {
            if (_element != NULL) CFRelease(_element);
            return (AXUIElementRef)_window;
        }
    }
    return NULL;
}

void windowDidDragToLocation(CGPoint mouseLocation, AXUIElementRef window, AppDelegate *appDelegate) {
    //CGSize screenSize = [[NSScreen mainScreen] frame].size;
    CGRect visibleRect = [[NSScreen mainScreen] visibleFrame];
    
    CGRect rect = rectForWindowLocation(getLocationFromMouseLocation(mouseLocation),visibleRect);
    if(CGRectEqualToRect(rect, CGRectNull)) {
        [appDelegate.window orderOut:appDelegate];
    } else {
        [appDelegate.window makeKeyAndOrderFront:appDelegate];
        [NSApp activateIgnoringOtherApps:YES];
        [appDelegate.window setFrame:rect display:YES];
        [appDelegate.window setLevel:NSPopUpMenuWindowLevel];
        [appDelegate.window orderFront:nil];
    }
}

CGEventRef myCGEventCallback(CGEventTapProxy __unused proxy, CGEventType type, CGEventRef event, void __unused *refcon) {
    
    if (type == kCGEventTapDisabledByTimeout || type == kCGEventTapDisabledByUserInput) {
        // need to re-enable our eventTap (We got disabled.  Usually happens on a slow resizing app)
        //CGEventTapEnable([moveResize eventTap], true);
        NSLog(@"Re-enabling...");
        return event;
    }
    
    AppDelegate *appDelegate = (__bridge AppDelegate *)refcon;
    
    switch (type) {
            
        case kCGEventLeftMouseDown:
        {
            CGPoint mouseLocation = CGEventGetLocation(event);
            _clickedWindow = windowForMouseLocation(mouseLocation);
            break;
        }
            
        case kCGEventLeftMouseDragged:
        {
            if(!_clickedWindow) break;
            
            CGPoint mouseLocation = CGEventGetLocation(event);
            windowDidDragToLocation(mouseLocation,_clickedWindow,appDelegate);

            break;
        }
            
        case kCGEventLeftMouseUp:
        {
            if(!_clickedWindow) break;

            CGPoint mouseLocation = CGEventGetLocation(event);
            CGSize screenSize = [[NSScreen mainScreen] frame].size;
            CGRect visibleRect = [[NSScreen mainScreen] visibleFrame];
            
            if(mouseLocation.y == 0.0) {
                NSSize wndSize = NSSizeFromCGSize(visibleRect.size);
                NSPoint wndLoc = NSPointFromCGPoint(visibleRect.origin);
                CFTypeRef _size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&wndSize));
                CFTypeRef _pos = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&wndLoc));
                
                AXUIElementSetAttributeValue((AXUIElementRef)_clickedWindow, (__bridge CFStringRef)NSAccessibilityPositionAttribute, (CFTypeRef *)_pos);
                AXUIElementSetAttributeValue((AXUIElementRef)_clickedWindow, (__bridge CFStringRef)NSAccessibilitySizeAttribute, (CFTypeRef *)_size);
            }
            
            if(mouseLocation.x == 0.0) {
                NSSize wndSize = NSSizeFromCGSize(CGSizeMake(visibleRect.size.width/2,visibleRect.size.height));
                NSPoint wndLoc = NSPointFromCGPoint(visibleRect.origin);
                CFTypeRef _size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&wndSize));
                CFTypeRef _pos = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&wndLoc));
                
                AXUIElementSetAttributeValue((AXUIElementRef)_clickedWindow, (__bridge CFStringRef)NSAccessibilityPositionAttribute, (CFTypeRef *)_pos);
                AXUIElementSetAttributeValue((AXUIElementRef)_clickedWindow, (__bridge CFStringRef)NSAccessibilitySizeAttribute, (CFTypeRef *)_size);
            }
            
            if(mouseLocation.x >= screenSize.width - 1.0) {
                NSSize wndSize = NSSizeFromCGSize(CGSizeMake(visibleRect.size.width/2,visibleRect.size.height));
                NSPoint wndLoc = NSPointFromCGPoint(CGPointMake(visibleRect.origin.x+visibleRect.size.width/2,visibleRect.origin.y));
                CFTypeRef _size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&wndSize));
                CFTypeRef _pos = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&wndLoc));
                
                AXUIElementSetAttributeValue((AXUIElementRef)_clickedWindow, (__bridge CFStringRef)NSAccessibilityPositionAttribute, (CFTypeRef *)_pos);
                AXUIElementSetAttributeValue((AXUIElementRef)_clickedWindow, (__bridge CFStringRef)NSAccessibilitySizeAttribute, (CFTypeRef *)_size);
            }
            
            //[appDelegate.window orderOut:appDelegate];
            AXUIElementSetAttributeValue((AXUIElementRef)_clickedWindow, kAXFrontmostAttribute, kCFBooleanTrue);
            AXUIElementSetAttributeValue((AXUIElementRef)_clickedWindow, kAXMainWindowAttribute, kCFBooleanTrue);
            [[NSApplication sharedApplication] hide:nil];
            
            _clickedWindow = NULL;
            
            break;
        }
            
        default:
            break;
    }

    // Pass along the event
    return event;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    if (!AXAPIEnabled()) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Cannot start SideResize.\n\nOS X 10.9 (Mavericks): visit\nSystem Preferences->Security & Privacy,\nand check \"Easy Move+Resize\" in the\nPrivacy tab\n\nOS X 10.8 (Mountain Lion): visit\nSystem Preferences->Accessibility\nand check \"Enable access for assistive devices\""];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        exit(1);
    }
    
    CFRunLoopSourceRef runLoopSource;
    
    CGEventMask eventMask = CGEventMaskBit( kCGEventLeftMouseDown ) | CGEventMaskBit( kCGEventLeftMouseDragged ) | CGEventMaskBit( kCGEventLeftMouseUp );
    
    CFMachPortRef eventTap = CGEventTapCreate(kCGHIDEventTap,
                                              kCGHeadInsertEventTap,
                                              kCGEventTapOptionDefault,
                                              eventMask,
                                              myCGEventCallback,
                                              (__bridge void *)(self));
    
    if (!eventTap) {
        NSLog(@"Couldn't create event tap!");
        exit(1);
    }
    
    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

-(void)awakeFromNib {
    
    NSImage *icon = [NSImage imageNamed:@"MenuIcon"];
    NSImage *altIcon = [NSImage imageNamed:@"MenuIconHighlight"];
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:statusMenu];
    [statusItem setImage:icon];
    [statusItem setAlternateImage:altIcon];
    [statusItem setHighlightMode:YES];
    
    CGRect visibleRect = [[NSScreen mainScreen] visibleFrame];
    self.window = [[NSWindow alloc] initWithContentRect:visibleRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreRetained defer:NO];
    [self.window setBackgroundColor:[NSColor whiteColor]];
    [self.window setAlphaValue:0.5];
    [self.window makeKeyAndOrderFront:nil];

    
}

- (IBAction)quitApp:(id)sender
{
    [[NSApplication sharedApplication] terminate:self];
}

@end
