//
//  AMBMovingCharacter.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-20.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//


#define TICK    NSDate *startTime = [NSDate date]
#define TOCK    NSLog(@"%s Time: %f", __func__, -[startTime timeIntervalSinceNow])

#import "AMBMovingCharacter.h"
#import "SKTUtils.h"

static const int TILE_LANE_WIDTH = 32;



@interface AMBMovingCharacter ()


@property NSTimeInterval sceneDelta;
@property NSTimeInterval lastTurnEvent; // to prevent wild and crazy u-turns

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
    
    _currentTileGID = [self.levelScene.mapLayerRoad tileGidAt:self.position];
    _currentTileProperties = [self.levelScene.tilemap propertiesForGid:_currentTileGID]; // store the current tile properties every frame. this allows us to ask each traffic vehicle if it's on an intersection.
    
    
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
//            #if DEBUG_PLAYER_CONTROL
//                NSLog(@"[control] PlayerIsAccelerating -> startMoving -> PlayerIsDrivingStraight");
//            #endif
            }
    }];
    

    
    
}

-(void)stopMovingWithDecelTime:(CGFloat)decel {
    //if ([self hasActions]) return; // TODO: commented this out to improve the snappiness of the controls. this results in a jerky motion
    
    SKAction *stopMoving = [SKAction customActionWithDuration:decel actionBlock:^(SKNode *node, CGFloat elapsedTime){
        float t = elapsedTime / decel;
        t = sinf(t * M_PI_2);
        _characterSpeedMultiplier = 1 - t;
    }];
    [self runAction:stopMoving completion:^{
        self.isMoving = NO;
        self.speedPointsPerSec = 0;
        
        if ([self.name isEqualToString:@"player"]) {
            _controlState = PlayerIsStopped;
//            #if DEBUG_PLAYER_CONTROL
//                    NSLog(@"[control] PlayerIsDecelerating -> stopMoving -> PlayerIsStopped");
//            #endif
        }
    
    }];
    
}

- (void)adjustSpeedToTarget:(CGFloat)targetSpeed {

    if (![self actionForKey:@"adjustSpeed"]) {
        CGFloat delta = self.speedPointsPerSec - targetSpeed;
        _originalSpeed = self.speedPointsPerSec;
        
        CGFloat adjDecelTime = self.decelTimeSeconds / 1.5;
        
        SKAction *adjustSpeed = [SKAction customActionWithDuration:adjDecelTime actionBlock:^(SKNode *node, CGFloat elapsedTime){
            float t = elapsedTime / adjDecelTime;
            t = sinf(t * M_PI_2);
            self.speedPointsPerSec = _originalSpeed - delta * t;
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
    
    
    SKAction *rotateSprite = [SKAction rotateToAngle:angle duration:self.pivotSpeed];
    [sprite runAction:rotateSprite completion:^(void) {
        // update the direction of the sprite
        self.direction = [self getDirectionFromAngle:self.zRotation];
    }];
    
    SKAction *wait = [SKAction waitForDuration:0.2]; // wait this duration before being allowed to change lanes
    [sprite runAction:wait completion:^(void){
        if ([self.name isEqualToString:@"player"]) {
            _controlState = PlayerIsDrivingStraight;
//#if DEBUG_PLAYER_CONTROL
//            NSLog(@"[control] PlayerIsTurning -> rotateByAngle (%1.0f,%1.0f) -> PlayerIsDrivingStraight",self.direction.x,self.direction.y);
//#endif
        }
        
    }];
    

}

- (CGPoint)getDirectionFromAngle:(CGFloat)angle {
    CGPoint vector = CGPointForAngle(angle); // the vector may be close to 0 or 1

    CGFloat x = roundf(vector.x); // round to get whole numbers
    CGFloat y = roundf(vector.y);
    
    x = (fabsf(x) == 0) ? 0 : x; // remove any negative zeros
    y = (fabsf(y) == 0) ? 0 : y;
    
    return CGPointMake(x, y);
}

- (void)moveBy:(CGVector)targetOffset {
    //NSLog(@"<moveBy>");
    //if ([self actionForKey:@"moveBy"]) { return; }
    
    SKAction *changeLanes = [SKAction moveBy:targetOffset duration:0.125];
    //changeLanes.timingMode = SKActionTimingEaseInEaseOut;
    [self runAction:changeLanes completion:^(void){

        if ([self.name isEqualToString:@"player"]) {
            _controlState = PlayerIsDrivingStraight;
//            #if DEBUG_PLAYER_CONTROL
//
//                NSLog(@"[control] PlayerIsChangingLanes -> moveBy -> PlayerIsDrivingStraight");
//            #endif
        }

    }];
    
}

- (void)moveSprite:(SKSpriteNode *)sprite directionNormalized:(CGPoint)direction {
    // TODO: replace with an action so we can use .paused on objects
    CGPoint velocity = CGPointMultiplyScalar(direction, self.speedPointsPerSec);
    CGPoint amountToMove = CGPointMultiplyScalar(velocity, self.sceneDelta);
    CGPoint amountToMoveSpeedMult = CGPointMultiplyScalar(amountToMove, _characterSpeedMultiplier);
    CGPoint newPosition = CGPointAdd(sprite.position, amountToMoveSpeedMult);
    
    sprite.position = newPosition;
    
    
}


- (void)authorizeMoveEvent: (CGFloat)degrees snapToLane:(BOOL)snap {
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
    
    
//

#warning Make sure the new way of using currentTile still catches illegal coordinates
//    // catch bug for nil currentTile (can happen when traffic drives off the map)
//    if (!currentTile) {
////        NSLog(@"currentTile is nil - returning from method");
//        return;
//    }

    
    //CGPoint playerPosInTile = [currentTile convertPoint:self.position fromNode:self.levelScene.tilemap];
    
    // using this to convert coordinate spaces because it's MUCH faster than instantiating a currentTile object and converting points that way
    CGPoint currentTilePos = [self.levelScene.mapLayerRoad pointForCoord:  [self.levelScene.mapLayerRoad coordForPoint:self.position]];
    CGPoint playerPosInTile = CGPointSubtract(self.position, currentTilePos);
    

    
    
    BOOL isWithinBounds;
    BOOL currentTileIsMultiLane;
    if([[_currentTileProperties[@"road"] substringToIndex:1] isEqualToString:@"b"]) { currentTileIsMultiLane = YES; } else { currentTileIsMultiLane = NO; }
    
    CGPoint targetPoint; // the result of this tile calculation below
    CGVector targetOffset; // how much we need to move over to get into the next lane
    
    if (_currentTileProperties[@"intersection"]) {
        CGPoint directionNormalized = CGPointNormalize(self.direction);
        CGPoint rotatedPointNormalized = CGPointRotate(directionNormalized, degrees);
        CGPoint rotatedPoint;
        
        
        if (currentTileIsMultiLane) {
            rotatedPoint = CGPointMultiplyScalar(rotatedPointNormalized, self.levelScene.tilemap.tileSize.width);
            targetPoint = CGPointAdd(rotatedPoint, self.position);
            isWithinBounds = [self isTargetPointValid:targetPoint];
            
            // get valid directions; the turn will only be allowed if it's happening in a valid direction from the multi-lane.
            NSString *validDirectionsStr = _currentTileProperties[@"valid_directions"];
            NSArray *validDirectionsArr = [self parseValidDirections:validDirectionsStr];
            
            
            CGPoint targetTileCenter = [self centerOfTileWhichContainsPoint:targetPoint]; // get center of target tile

            CGPoint offset =  CGPointMultiply(CGPointSubtract(targetTileCenter, self.position), rotatedPointNormalized); // calculate the offset between the center of the target tile and the player's position.
            CGFloat offsetAbsolute = offset.x + offset.y; // "flatten" the offset; one of these numbers will be 0
            
            
            if (offsetAbsolute <= self.levelScene.tilemap.tileSize.width && isWithinBounds) {
                if ([validDirectionsArr containsObject:[NSValue valueWithCGPoint:rotatedPointNormalized]]) {
                    // the desired direction of travel matches a valid direction in the tile
                    isWithinBounds = YES;
                } else {
                    isWithinBounds = NO;
                }
                

            } else {
                isWithinBounds = NO;
            }
            
            
//#if DEBUG_PLAYER_CONTROL
//            NSLog(@"********");
//            NSLog(@"self.position           = %1.0f, %1.0f", self.position.x, self.position.y);
//            NSLog(@"targetTileCenter        = %1.0f, %1.0f", targetTileCenter.x, targetTileCenter.y);
//            NSLog(@"offset)                 = %1.3f", offsetAbsolute);
//            NSLog(@"isWithinBounds          = %i", isWithinBounds);
//            NSLog(@"valid_directions        = %@", validDirectionsStr);
//            NSLog(@"rotated_point =         = %1.0f,%1.0f",rotatedPointNormalized.x,rotatedPointNormalized.y);
//            NSLog(@" ");
//            NSLog(@" ");
//#endif
            
        } else {
            rotatedPoint = CGPointMultiplyScalar(rotatedPointNormalized, self.levelScene.tilemap.tileSize.width); // target tile is 1 over
            targetPoint = CGPointAdd(rotatedPoint, self.position);
            isWithinBounds = [self isTargetPointValid:targetPoint];
        }
        

        if (isWithinBounds) {
            if (CACurrentMediaTime() - _lastTurnEvent > 1) {
                self.controlState = PlayerIsTurning;
                _lastTurnEvent = CACurrentMediaTime();
                [self rotateByAngle:degrees];
                if ([self.name isEqualToString:@"player"]) {

                        
                        [self.levelScene.camera rotateByAngle:degrees];
                        [self.levelScene rotateInteractives:degrees];
                        [self.levelScene.tutorialOverlay playerDidPerformEvent:PlayerEventTurnCorner]; // tutorial event
//    #if DEBUG_PLAYER_CONTROL
//                        
//                        NSLog(@"[control]    Valid turn; executing rotateByAngle");
//    #endif
                    
                }
                
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
    
    targetPoint = CGPointAdd(self.position, CGPointMake(targetOffset.dx, targetOffset.dy));
#if DEBUG
    //NSLog(@"LANE CHANGE: (%1.8f,%1.8f)[%ld] -> (%1.8f,%1.8f)[%ld]",playerPosInTile.x, playerPosInTile.y, (long)posNormalized, targetPoint.x, targetPoint.y, (long)targetLaneNormalized); // current position (lane) -> new position (lane)
#endif
    
    
    isWithinBounds = [self isTargetPointValid:targetPoint];

    if (isWithinBounds) {
        if (snap) {
            self.controlState = PlayerIsChangingLanes;
            [self moveBy:targetOffset]; // moveBy will update the state upon completion
            _requestedMoveEvent = NO;
            
            if ([self.name isEqualToString:@"player"]) {
                [self.levelScene.tutorialOverlay playerDidPerformEvent:PlayerEventChangeLanes]; // tutorial event
            }
            
        } else {
            // "manual" player control, using the left or right controls slides the player over a set amount
            CGPoint laneChangeVector = CGPointRotate(self.direction, degrees);
            CGPoint moveAmt = CGPointMultiplyScalar(laneChangeVector, 384*self.sceneDelta); // # of points to move
            CGVector moveVector = CGVectorMake(moveAmt.x, moveAmt.y);
            [self runAction:[SKAction moveBy:moveVector duration:self.sceneDelta]];
            if ([self.name isEqualToString:@"player"]) {
                [self.levelScene.tutorialOverlay playerDidPerformEvent:PlayerEventConstantMovement]; // tutorial event
            }
            
        }
        
        return;
    }
    
    // as a final fall-through, stash the turn request if it wasn't able to be completed.
    // the update loop will keep requesting the turn for a while after the keypress, in order
    // to reduce the precise timing required to turn on to other roads.
    // this is for the traffic AI only at this point; players request turns manually by pressing down on the button
    _requestedMoveEvent = YES;
    _requestedMoveEventDegrees = degrees;

}


- (NSArray *)parseValidDirections:(NSString *)directionsString {
    NSArray *cardinalDirections = [directionsString componentsSeparatedByString:@","];
    NSMutableArray *validDirections = [NSMutableArray array];
    
    for (NSString *str in cardinalDirections) {
        if ([str isEqualToString:@"N"]) {
            [validDirections addObject:[NSValue valueWithCGPoint:CGPointMake(0, 1)]];
        } else if ([str isEqualToString:@"E"]) {
            [validDirections addObject:[NSValue valueWithCGPoint:CGPointMake(1, 0)]];
            
        } else if ([str isEqualToString:@"S"]) {
            [validDirections addObject:[NSValue valueWithCGPoint:CGPointMake(0, -1)]];
            
        } else if ([str isEqualToString:@"W"]) {
            [validDirections addObject:[NSValue valueWithCGPoint:CGPointMake(-1, 0)]];
            
        }
    
    }
    
    return validDirections;
}

- (CGPoint)centerOfTileWhichContainsPoint:(CGPoint)point {
    // returns the center point of the tile that contains the specified point.
    return  [self.levelScene.mapLayerRoad pointForCoord: [self.levelScene.mapLayerRoad coordForPoint:point] ];
}

- (BOOL)isTargetPointValid: (CGPoint)targetPoint {

    // with the target point, get the target tile and determine a) if it's a road tile, and b) if the point within the road tile is a road surface (and not the border)

    NSString *targetTileRoadType = [self.levelScene.tilemap propertiesForGid:  [self.levelScene.mapLayerRoad tileGidAt:targetPoint]  ][@"road"];
    CGPoint targetTilePos = [self.levelScene.mapLayerRoad pointForCoord:  [self.levelScene.mapLayerRoad coordForPoint:targetPoint]];
    CGPoint positionInTargetTile = CGPointSubtract(targetPoint, targetTilePos);
    
    
#if DEBUG_TURNING
    if ([self.name isEqualToString:@"player"]) {
        SKSpriteNode *targetTile = [self.levelScene.mapLayerRoad tileAt:targetPoint]; // gets the the tile object being considered for the turn. tileAt ultimately works by finding the node by name, which is computationally expensive. the only use of this line is to figure out the coordinates of the player within the tile.

        SKSpriteNode *targetPointSprite = [SKSpriteNode spriteNodeWithColor:[SKColor yellowColor] size:CGSizeMake(10, 10)];
        targetPointSprite.name = @"DEBUG_targetPointSprite";
        targetPointSprite.position = positionInTargetTile;
        targetPointSprite.zPosition = targetTile.zPosition + 1;


        [targetTile addChild:targetPointSprite];
        [targetPointSprite runAction:[SKAction sequence:@[[SKAction waitForDuration:3],[SKAction fadeOutWithDuration:3]]]];
    }
#endif
    
    if (targetTileRoadType) {
        // if it's a road tile, check the coordinates to make sure it's on ROAD SURFACE within the tile
        
        CGPathRef path = (__bridge CGPathRef)([self.levelScene.roadTilePaths objectForKey:targetTileRoadType]); // TODO: memory leak because of bridging?
        
        BOOL pointIsValid = CGPathContainsPoint(path, NULL, positionInTargetTile, FALSE);
        
#if DEBUG_PLAYER_CONTROL
//        if ([self.name isEqualToString:@"player"]) {
//            if (pointIsValid) {
//                targetPointSprite.color = [SKColor greenColor];
//            }
//            
//            SKShapeNode *bounds = [SKShapeNode node];
//            bounds.path = path;
//            bounds.fillColor = [SKColor whiteColor];
//            bounds.alpha = 0.5;
//            bounds.zPosition = targetPointSprite.zPosition + 10;
//            
//            [targetTile addChild:bounds];
//            [bounds runAction:[SKAction sequence:@[[SKAction waitForDuration:1],[SKAction removeFromParent]]]];
//        }
#endif
        
        return pointIsValid;
    }
    
    return NO; // no, it's not valid because it's not on a road tile!
}

//}

- (void)startMovingTransitionState {
    // stub; overridden by Player.
}

@end
