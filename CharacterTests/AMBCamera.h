//
//  AMBCamera.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-10-31.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>


typedef enum {
    CameraIsIdle,
    CameraIsReframing,
    CameraIsFollowing
} CameraState;


@interface AMBCamera : SKNode

@property (nonatomic) SKSpriteNode *targetSprite; // the sprite that the camera will follow
@property (nonatomic) CGSize boundingBox; // always centered in the screen. the target sprite is allowed to move within this bounding box without triggering a camera follow.
@property (nonatomic) BOOL reorientsToTargetSpriteDirection; // if YES, the camera will rotate to keep the target sprite facing up.
@property (nonatomic) CGFloat idleOffset; // the target sprite's position in the frame, relative to center, when the target sprite is idle
@property (nonatomic) CGFloat activeOffset; // the target sprite's position in the frame, relative to center, when the target sprite is moving. travelling outside of the bounding box triggers the camera to become active.
@property (nonatomic) CGFloat currentOffset; // will be set with either the value of idleOffset or activeOffset when the CameraIsReframing
@property (nonatomic) CameraState state;
@property (readonly, nonatomic) CGFloat rotation; // the effective rotation of the camera; since it's the tilemap that actually rotates, this can be used in situations where you need to calculate coordinates as if the camera has been rotated (e.g. the onscreen indicators)
@property SKSpriteNode *miniMap; // declared here so we can access it to rotate it

- (instancetype)initWithTargetSprite:(SKNode *)targetSprite;
- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta;
- (void)rotateByAngle:(CGFloat)degrees;

@end
