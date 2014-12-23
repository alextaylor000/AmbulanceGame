//
//  AMBMovingCharacter.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-20.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBMovingCharacter.h"
#import "SKTUtils.h"

static const int TILE_LANE_WIDTH = 32;



@interface AMBMovingCharacter ()


@property NSTimeInterval sceneDelta;
@property CGFloat characterSpeedMultiplier; // 0-1; velocity gets multiplied by this before the sprite is moved
@property CGFloat originalSpeed; // used as comparison when adjusting speed. there's probably a slicker way to do this.

@end

@implementation AMBMovingCharacter

-(id)init {
    if (self = [super init]) {
        // set parameter defaults; to be overridden by subclasses
        self.speedPointsPerSec = 100.0;
        self.pivotSpeed = 0.25;
        self.direction = CGPointMake(1, 0);
        self.accelTimeSeconds = 0.75;
        self.decelTimeSeconds = 0.35;
    }
    return self;
}

#pragma mark Game Loop
- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta {
    self.sceneDelta = delta;
    
    _currentTileProperties = [self.levelScene.tilemap propertiesForGid:[self.levelScene.mapLayerRoad tileGidAt:self.position]]; // store the current tile properties every frame. this allows us to ask each traffic vehicle if it's on an intersection.
    
    if (self.isMoving) {
        [self moveSprite:self directionNormalized:self.direction];
    }
    

}

#pragma mark (Public) Sprite Controls
-(void)startMoving {
    
    if (self.isMoving == YES) return;
    
    self.isMoving = YES;
    self.speedPointsPerSec = self.nativeSpeed; // reset speedPointsPerSec

    SKAction *startMoving = [SKAction customActionWithDuration:self.accelTimeSeconds actionBlock:^(SKNode *node, CGFloat elapsedTime){
        float t = elapsedTime / self.accelTimeSeconds;
        t = sinf(t * M_PI_2);
        _characterSpeedMultiplier = t;

    }];
    [self runAction:startMoving completion:^(void){
        if ([self.name isEqualToString:@"player"]) {
            _controlState = PlayerIsDrivingStraight;
            #if DEBUG_PLAYER_CONTROL

                NSLog(@"[control] PlayerIsAccelerating -> startMoving -> PlayerIsDrivingStraight");
            }
            #endif
    
    }];
    

    
    
}

-(void)stopMoving {
    //if ([self hasActions]) return; // TODO: commented this out to improve the snappiness of the controls. this results in a jerky motion
    
    SKAction *stopMoving = [SKAction customActionWithDuration:self.decelTimeSeconds actionBlock:^(SKNode *node, CGFloat elapsedTime){
        float t = elapsedTime / self.decelTimeSeconds;
        t = sinf(t * M_PI_2);
        _characterSpeedMultiplier = 1 - t;
    }];
    [self runAction:stopMoving completion:^{
        self.isMoving = NO;
        self.speedPointsPerSec = 0;
        
        if ([self.name isEqualToString:@"player"]) {
            _controlState = PlayerIsStopped;
            #if DEBUG_PLAYER_CONTROL
                    NSLog(@"[control] PlayerIsDecelerating -> stopMoving -> PlayerIsStopped");
            #endif
        }
    
    }];
    
    
}

- (void)adjustSpeedToTarget:(CGFloat)targetSpeed {

    if (![self actionForKey:@"adjustSpeed"]) {
        CGFloat delta = self.speedPointsPerSec - targetSpeed;
        _originalSpeed = self.speedPointsPerSec;
        
        SKAction *adjustSpeed = [SKAction customActionWithDuration:self.decelTimeSeconds actionBlock:^(SKNode *node, CGFloat elapsedTime){
            float t = elapsedTime / self.decelTimeSeconds;
            t = sinf(t * M_PI_2);
            self.speedPointsPerSec = _originalSpeed - delta * t;
            //NSLog(@"[adjustSpeedToTarget] %1.5f-> %1.5f",_originalSpeed, self.speedPointsPerSec);
        }];
        
        [self runAction:adjustSpeed withKey:@"adjustSpeed"];
    }
}


#pragma mark (Private) Sprite Movement

- (void)rotateByAngle:(CGFloat)degrees {
    SKSpriteNode *sprite = self;
    
    // apply the rotation to the sprite
    CGFloat angle = sprite.zRotation + DegreesToRadians(degrees);
    
    // wrap angles larger than +/- 360 degrees
    if (angle >= ( 2 * M_PI )) {
        angle -= (2 * M_PI);
    } else if (angle < -(2 * M_PI)) {
        angle += (2 * M_PI);
    }
    
    //NSLog(@"angle=%f",RadiansToDegrees(angle));
    
    SKAction *rotateSprite = [SKAction rotateToAngle:angle duration:self.pivotSpeed];
    [sprite runAction:rotateSprite completion:^(void) {
        // update the direction of the sprite
        self.direction = CGPointForAngle(sprite.zRotation);
        
        
    }];
    
    SKAction *wait = [SKAction waitForDuration:0.35]; // wait this duration before being allowed to change lanes
    [sprite runAction:wait completion:^(void){
        if ([self.name isEqualToString:@"player"]) {
            _controlState = PlayerIsDrivingStraight;
#if DEBUG_PLAYER_CONTROL
            NSLog(@"[control] PlayerIsTurning -> rotateByAngle -> PlayerIsDrivingStraight");
#endif
        }
        
    }];
    
    
    //Fixes the directions so that you dont end up with a situation where you have -0.00000.  I dont even know how that could happen.  BUT IT DOES
    if (self.direction.x <= 0.0001 && self.direction.x >= -0.0001) {//slightly more than 0 and slightly less than 0
        self.direction = CGPointMake(0, self.direction.y);
    }
    if (self.direction.y <= 0.0001 && self.direction.y >= -0.0001) {//slightly more than 0 and slightly less than 0
        self.direction = CGPointMake(self.direction.y, 0);
    }
    
    //NSLog(@"vector=%1.0f,%1.0f|z rotation=%1.5f",self.direction.x, self.direction.y,sprite.zRotation);
}

- (void)moveBy:(CGVector)targetOffset {
    //NSLog(@"<moveBy>");
    //if ([self actionForKey:@"moveBy"]) { return; }
    
    SKAction *changeLanes = [SKAction moveBy:targetOffset duration:0.2];
    //changeLanes.timingMode = SKActionTimingEaseInEaseOut;
    [self runAction:changeLanes completion:^(void){

        if ([self.name isEqualToString:@"player"]) {
            _controlState = PlayerIsDrivingStraight;
            #if DEBUG_PLAYER_CONTROL

                NSLog(@"[control] PlayerIsChangingLanes -> moveBy -> PlayerIsDrivingStraight");
            #endif
        }

    }];
    
}

- (void)moveSprite:(SKSpriteNode *)sprite directionNormalized:(CGPoint)direction {
    
    CGPoint velocity = CGPointMultiplyScalar(direction, self.speedPointsPerSec);
    CGPoint amountToMove = CGPointMultiplyScalar(velocity, self.sceneDelta);
    
    CGPoint amountToMoveSpeedMult = CGPointMultiplyScalar(amountToMove, _characterSpeedMultiplier);
    sprite.position = CGPointAdd(sprite.position, amountToMoveSpeedMult);
    
    
}


- (void)authorizeMoveEvent: (CGFloat)degrees {
    /* Called by user input. Initiates a turn or a lane change if the move is legal.
     
     The layout of this function is as follows:
     
     Is the tile an intersection?
     Define the target point (slightly different for single lane vs. multi lane)
     
     Does the target point land on a road?
     *TURN!*
     return;
     
     Define the target point for a lane change
     Does the target point land on a road?
     *CHANGE LANES!*
     
     Inputs:
     Scene
     _tilemap
     _mapLayerRoad
     roadTilePaths
     */
    
    
    
    SKSpriteNode *currentTile = [self.levelScene.mapLayerRoad tileAt:self.position];
//    _currentTileProperties = [self.levelScene.tilemap propertiesForGid:[self.levelScene.mapLayerRoad tileGidAt:self.position]]; // moved this into update so we can get it every frame, since I'd like to check if traffic is on an intersection or not
    
    // catch bug for nil currentTile (can happen when traffic drives off the map)
    if (!currentTile) {
//        NSLog(@"currentTile is nil - returning from method");
        return;
    }
    
    CGPoint playerPosInTile = [currentTile convertPoint:self.position fromNode:self.levelScene.tilemap];
    
    BOOL isWithinBounds;
    BOOL currentTileIsMultiLane;
    if([[_currentTileProperties[@"road"] substringToIndex:1] isEqualToString:@"b"]) { currentTileIsMultiLane = YES; } else { currentTileIsMultiLane = NO; }
    
    CGPoint targetPoint; // the result of this tile calculation below
    CGVector targetOffset; // how much we need to move over to get into the next lane
    
    if (_currentTileProperties[@"intersection"]) {
        CGPoint directionNormalized = CGPointNormalize(self.direction);
        CGPoint rotatedPointNormalized = CGPointRotate(directionNormalized, degrees);
        CGPoint rotatedPoint;
        
        // is it single-lane?
        if (currentTileIsMultiLane) {
            rotatedPoint = CGPointMultiplyScalar(rotatedPointNormalized, self.levelScene.tilemap.tileSize.width*2); // target tile is 2 over
        } else {
            rotatedPoint = CGPointMultiplyScalar(rotatedPointNormalized, self.levelScene.tilemap.tileSize.width); // target tile is 1 over
        }
        
        targetPoint = CGPointAdd(rotatedPoint, self.position);
        isWithinBounds = [self isTargetPointValid:targetPoint];
        
        if (isWithinBounds) {
            self.controlState = PlayerIsTurning;
            [self rotateByAngle:degrees];
            if ([self.name isEqualToString:@"player"]) {
                [self.levelScene.camera rotateByAngle:degrees];
#if DEBUG_PLAYER_CONTROL
                
                NSLog(@"[control]    Valid turn; executing rotateByAngle");
#endif
                
            }
            
            
            _requestedMoveEvent = NO; // put this in MovingCharacter's update loop
            return;
        }
        
    } // if currentTileProperties = intersection
    
    // fall through to a lane change if the whole turning thing didn't work out
    
    CGPoint laneChangeVector = CGPointRotate(self.direction, degrees);
    
    NSInteger remainder;
    CGFloat pos;  // the player's position in the tile, either the x or the y value
    CGFloat posNormalized ; // the player's position, normalized to the lane width
    NSInteger targetLaneNormalized;
    NSInteger direction; // the lane change vector, should either be 1 or -1
    
    // the lane change calculation is easiest in one dimension, so we want to extract the relevant details and forget about points until the end
    if (fabsf(laneChangeVector.x) > fabsf(laneChangeVector.y)) {
        pos     = playerPosInTile.x + (self.levelScene.tilemap.tileSize.width/2); // add half the width of the tile to make the coords corner-anchored.
        direction = laneChangeVector.x;
        
    } else {
        pos     = playerPosInTile.y + (self.levelScene.tilemap.tileSize.width/2);
        direction = laneChangeVector.y;
    }
    
    
    // TODO: accept a range around the lane (e.g. if the lane is at 96, 94-98 should be considered the range)
    posNormalized = (direction) > 0 ? floorl( round(pos)/TILE_LANE_WIDTH) : ceilf( round(pos)/TILE_LANE_WIDTH);
    
    
    if ( (int)posNormalized % 2 == 0) { // the player is right on a lane
        targetLaneNormalized = posNormalized + direction;
        
    } else { // the player is somewhere between lanes
        remainder = (int)posNormalized % 2;
        targetLaneNormalized = posNormalized + direction + (remainder * direction);
    }
    
    // convert the result back into a point
    if (fabsf(laneChangeVector.x) > fabsf(laneChangeVector.y)) {
        targetOffset = CGVectorMake((targetLaneNormalized * TILE_LANE_WIDTH) - pos , 0);
        
    } else {
        targetOffset = CGVectorMake(0, (targetLaneNormalized * TILE_LANE_WIDTH) - pos);        }
    
    targetPoint = CGPointAdd(playerPosInTile, CGPointMake(targetOffset.dx, targetOffset.dy));
#if DEBUG
    //NSLog(@"LANE CHANGE: (%1.8f,%1.8f)[%ld] -> (%1.8f,%1.8f)[%ld]",playerPosInTile.x, playerPosInTile.y, (long)posNormalized, targetPoint.x, targetPoint.y, (long)targetLaneNormalized); // current position (lane) -> new position (lane)
#endif
    
    targetPoint = [self.levelScene.tilemap convertPoint:targetPoint fromNode:currentTile]; // convert target point back to real world coords
    
    isWithinBounds = [self isTargetPointValid:targetPoint];
    
    if (isWithinBounds) {
        [self moveBy:targetOffset];
        _requestedMoveEvent = NO;
        
#if DEBUG_PLAYER_CONTROL
        if ([self.name isEqualToString:@"player"]) {
            NSLog(@"lane change");
        }
#endif
        
        return;
    }
    
    // as a final fall-through, stash the turn request if it wasn't able to be completed.
    // the update loop will keep requesting the turn for a while after the keypress, in order
    // to reduce the precise timing required to turn on to other roads.
    _requestedMoveEvent = YES;
    _requestedMoveEventDegrees = degrees;
    
}


- (BOOL)isTargetPointValid: (CGPoint)targetPoint {
    BOOL pointIsValid = NO;
    
    // with the target point, get the target tile and determine a) if it's a road tile, and b) if the point within the road tile is a road surface (and not the border)
    SKSpriteNode *targetTile = [self.levelScene.mapLayerRoad tileAt:targetPoint]; // gets the the tile object being considered for the turn
    
    NSString *targetTileRoadType = [self.levelScene.tilemap propertiesForGid:  [self.levelScene.mapLayerRoad tileGidAt:targetPoint]  ][@"road"];
    CGPoint positionInTargetTile = [targetTile convertPoint:targetPoint fromNode:self.levelScene.tilemap]; // the position of the target within the target tile
    
#if DEBUG_PLAYER_CONTROL
    SKSpriteNode *targetPointSprite = [SKSpriteNode spriteNodeWithColor:[SKColor yellowColor] size:CGSizeMake(10, 10)];
    targetPointSprite.name = @"DEBUG_targetPointSprite";
    targetPointSprite.position = positionInTargetTile;
    targetPointSprite.zPosition = targetTile.zPosition + 1;

    if ([self.name isEqualToString:@"player"]) {
        [targetTile addChild:targetPointSprite];
        [targetPointSprite runAction:[SKAction sequence:@[[SKAction waitForDuration:3],[SKAction removeFromParent]]]];
    }
#endif
    
    if (targetTileRoadType) {
        // check the coordinates to make sure it's on ROAD SURFACE within the tile
        
        CGPathRef path = (__bridge CGPathRef)([self.levelScene.roadTilePaths objectForKey:targetTileRoadType]); // TODO: memory leak because of bridging?
        
        pointIsValid = CGPathContainsPoint(path, NULL, positionInTargetTile, FALSE);
        
#if DEBUG_PLAYER_CONTROL
        if ([self.name isEqualToString:@"player"]) {
            if (pointIsValid) {
                targetPointSprite.color = [SKColor greenColor];
            }
            
            SKShapeNode *bounds = [SKShapeNode node];
            bounds.path = path;
            bounds.fillColor = [SKColor whiteColor];
            bounds.alpha = 0.5;
            bounds.zPosition = targetPointSprite.zPosition - 1;
            
            [targetTile addChild:bounds];
            [bounds runAction:[SKAction sequence:@[[SKAction waitForDuration:1],[SKAction removeFromParent]]]];
        }
#endif
        
        
        return CGPathContainsPoint(path, NULL, positionInTargetTile, FALSE);
    }
    
    return pointIsValid;
}



@end
