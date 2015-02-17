//
//  AMBPowerup.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-12-04.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBPowerup.h"

@implementation AMBPowerup


- (instancetype)initAsType:(AMBPowerupType)type {

    
    SKTexture *texture;
    
    if (type == AMBPowerupFuel) {
        texture = [SKTexture textureWithImageNamed:@"fuel"];
        self.name = @"fuel";
    } else if (type == AMBPowerupInvincibility) {
        texture = [SKTexture textureWithImageNamed:@"invincibility"];
        self.name = @"invincibility";
    }
    
    if (self = [super initWithTexture:texture]) {
        self.zPosition = 10;
        
        self.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:self.size];
        self.physicsBody.categoryBitMask = categoryPowerup;
        self.physicsBody.collisionBitMask = 0x00000000;
        
        SKSpriteNode *dazzle = [[self powerupDazzle] copy];
        dazzle.zPosition = -1;
        [dazzle setScale:2.0];
        dazzle.color = [SKColor whiteColor];
        dazzle.colorBlendFactor = 1.0;

        
        [self addChild:dazzle];
        [dazzle runAction:sPowerupDazzleAnimation];
        
        
    }
    
    
    return self;
}

+ (void)loadSharedAssets {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        // should we preload this atlas, since we need it a bunch of times? where should we do it?
        SKTextureAtlas *gameObjectSprites = [SKTextureAtlas atlasNamed:@"GameObjectSprites"];
        
        sTextureFuel = [SKTexture textureWithImageNamed:@"fuel"];
        sTextureInvincibility = [SKTexture textureWithImageNamed:@"invincibility"];
        
        sPowerupDazzle = [SKSpriteNode spriteNodeWithTexture:[gameObjectSprites textureNamed:@"dazzle"]];
        sPowerupDazzleAnimation = [SKAction repeatActionForever:[SKAction rotateByAngle:M_PI duration:2.0]];
        
        
    });
}

static SKTexture *sTextureFuel = nil;
static SKTexture *sTextureInvincibility = nil;
static SKSpriteNode *sPowerupDazzle = nil;
static SKAction *sPowerupDazzleAnimation = nil;

- (SKSpriteNode *)powerupDazzle {
    return sPowerupDazzle;
}


@end
