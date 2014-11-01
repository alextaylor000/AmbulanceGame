//
//  AMBCamera.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-10-31.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "SKTUtils.h"
#import "AMBCamera.h"
#import "AMBPlayer.h" // to detect if the patient is moving or not

@interface AMBCamera ()

@property CGPoint spritePosInBoundingBox;
@property CGPoint targetPosition;
@property AMBPlayer *player;

@end


@implementation AMBCamera

- (instancetype)initWithTargetSprite:(SKSpriteNode *)targetSprite {
    
    if (self = [super init]) {
        _targetSprite = targetSprite;
        _player = (AMBPlayer *)_targetSprite; // cast the target sprite as a player so we can access its isMoving property
        
        // set properties
        _boundingBox = CGSizeMake(300, 300);
        _cameraIsActive = NO;
        _reorientsToTargetSpriteDirection = YES;
        _idleOffset = 0;
        _activeOffset = 200;
        
        // set initial position to center on the target sprite
        self.position = _targetSprite.position;
        
#if DEBUG
        SKSpriteNode *boundingBox = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:_boundingBox];
        boundingBox.alpha = 0.15;
        [self addChild:boundingBox];
#endif
    }
    
    return self;
}


- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta {
    
    if (_player.isMoving) {
        
        _spritePosInBoundingBox = [_targetSprite.scene convertPoint:_targetSprite.position fromNode:_targetSprite.parent];
        if (_spritePosInBoundingBox.x > (_boundingBox.width/2) || _spritePosInBoundingBox.y > (_boundingBox.height/2)) {
            [self reframeCameraToOffset:_activeOffset]; // reframe to ACTIVE OFFSET
        }
        
    } else {
        [self reframeCameraToOffset:_idleOffset]; // reframe to IDLE OFFSET
    }


}


- (void)reframeCameraToOffset:(CGFloat)offset {

    _targetPosition = CGPointMultiplyScalar(_player.direction, -1 * offset);
    _targetPosition = CGPointSubtract(_player.position, _targetPosition);
    
    CGPoint targetOffset = CGPointSubtract(_targetPosition, self.position);
    
    if (targetOffset.x > 2 || targetOffset.y > 2) {
        self.position = CGPointMake(self.position.x + targetOffset.x/2, self.position.y + targetOffset.y/2);
    } else {
        self.position = _targetPosition;
    }
    
}

@end
