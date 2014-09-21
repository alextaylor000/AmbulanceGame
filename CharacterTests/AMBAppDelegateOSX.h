//
//  AMBAppDelegateOSX.h
//  CharacterTests
//

//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SpriteKit/SpriteKit.h>

@interface AMBAppDelegateOSX : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet SKView *skView;

@end
