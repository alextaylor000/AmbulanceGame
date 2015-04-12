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
@property BOOL updateCameraRotation;

@end


@implementation AMBCamera




- (instancetype)initWithTargetSprite:(SKSpriteNode *)targetSprite {
    
    if (self = [super init]) {
        _targetSprite = targetSprite;
        _player = (AMBPlayer *)_targetSprite; // cast the target sprite as a player so we can access its isMoving property
        
        // set properties
        _rotation = 0;
        _boundingBox = CGSizeMake(200, 200);
        _reorientsToTargetSpriteDirection = YES;
        _idleOffset = 0;
        _activeOffset = 0; // previously 200
        _state = CameraIsIdle;
        _miniMap = nil;
        
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
    
    switch (_state) {
        case CameraIsIdle:
            [self checkBounds];
            break;
            
        case CameraIsReframing:
            _currentOffset = (_player.isMoving) ? _activeOffset : _idleOffset;
            [self reframeCameraToOffset:_currentOffset];
            break;
            
        case CameraIsFollowing:
            if (!_player.isMoving) {
                [self changeState:CameraIsReframing];
            }
            
            [self lockCameraToOffset:_currentOffset];
            break;
            
        default:
            break;
    }
    
    
    if (_updateCameraRotation) {
        _rotation = self.parent.parent.zRotation; // the world node's zRotation
        //NSLog(@"camera rotation = %1.5f", _rotation);
    }

}



- (void)changeState:(CameraState)newState {
    _state = newState;

#if DEBUG
    NSString *stateStr;
    
    switch (_state) {
        case CameraIsIdle:
            stateStr = @"CameraIsIdle";
            break;
            
        case CameraIsReframing:
            stateStr = @"CameraIsReframing";
            break;
            
        case CameraIsFollowing:
            stateStr = @"CameraIsFollowing";
            break;
    }
    
    NSLog(@"Changed camera state to: %@", stateStr);
#endif
    
}

- (void)checkBounds {
    if (_player.isMoving) {
        _spritePosInBoundingBox = [_targetSprite.scene convertPoint:_targetSprite.position fromNode:_targetSprite.parent];
        if (fabsf(_spritePosInBoundingBox.x) > (_boundingBox.width/2) || fabsf(_spritePosInBoundingBox.y) > (_boundingBox.height/2)) {
            _currentOffset = _activeOffset; // reframe to ACTIVE OFFSET
            [self changeState:CameraIsReframing];
        }
    }
    
}

- (void)reframeCameraToOffset:(CGFloat)offset {
    
    _targetPosition = CGPointMultiplyScalar(_player.direction, -1 * offset);
    _targetPosition = CGPointSubtract(_player.position, _targetPosition);
    
    CGPoint targetOffset = CGPointSubtract(_targetPosition, self.position);

#if DEBUG
   // NSLog(@"targetOffset=%1.0f,%1.0f",targetOffset.x,targetOffset.y);
#endif
    
    if (fabsf(targetOffset.x) > 10 || fabsf(targetOffset.y) > 10) { // lock the camera if the camera is within 5 points of the target position
        self.position = CGPointMake(self.position.x + (targetOffset.x*0.35), self.position.y + (targetOffset.y*0.35));
    } else {
        self.position = _targetPosition;
        
        if (_player.isMoving) {
            [self changeState:CameraIsFollowing];
        } else {
            [self changeState:CameraIsIdle];
        }
    }
}

- (void)lockCameraToOffset:(CGFloat)offset {
    _targetPosition = CGPointMultiplyScalar(_player.direction, -1 * offset);
    _targetPosition = CGPointSubtract(_player.position, _targetPosition);
    self.position = _targetPosition;
}


- (void)rotateByAngle:(CGFloat)degrees {
    
    SKNode *parentNode = self.parent.parent; // should be world node
    
    SKAction *rotate = [SKAction rotateByAngle:DegreesToRadians(degrees*-1) duration:0.65];
    rotate.timingMode = SKActionTimingEaseOut;
    
    
    _updateCameraRotation = YES;
    [parentNode runAction:rotate completion:^(void){ _updateCameraRotation = NO; }];
     [_miniMap runAction:rotate];

    
}

@end
