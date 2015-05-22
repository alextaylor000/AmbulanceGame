//
//  AMBGameScene.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-09-13.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBGameScene.h"
#import "JSTileMap.h"

@implementation AMBGameScene

- (JSTileMap *)tileMapFromFile:(NSString *)filename {
    return [JSTileMap mapNamed:filename];
}

- (instancetype)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        // set up properties that will never change from level to level
        
        self.anchorPoint = CGPointMake(0.5, 0.5);
        self.physicsWorld.gravity = CGVectorMake(0, 0);
        
        
        
        
    }
    
    return self;
}

+ (void)loadSceneAssetsWithCompletionHandler:(void (^)(void))callback {

    //NSLog(@"Loading shared assets ...");

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // Load the shared assets in the background.
        [self loadSceneAssets];
        
        if (!callback) {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Call the completion handler back on the main queue.
            callback();
        });
    });
}

+ (void)loadSceneAssets {
  // overridden by subclasses.
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
#if DEBUG_PLAYER_SWIPE
    NSLog(@"[control] simultaneous gesture detected");
#endif
    return YES;    // for pan and long press
    
}

@end
