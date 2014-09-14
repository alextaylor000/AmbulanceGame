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

@end
