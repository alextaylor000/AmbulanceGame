//
//  AMBConstants.h
//  AmbulanceGame
//
//  Created by Alex Taylor on 2015-04-11.
//  Copyright (c) 2015 Alex Taylor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

# pragma mark GAME MODES
static const NSTimeInterval GAMETYPE_DAYSHIFT_LENGTH = 180; // countdown timer for the "day shift" game mode
static const NSTimeInterval GAMETYPE_SUDDEN_LENGTH = 45; // countdown timer for the "sudden death" game mode
static const NSTimeInterval SUDDEN_DEATH_PATIENT_TIME_BONUS = 30; // you get this many seconds for each patient delivered


typedef NS_ENUM(int, AMBVehicleType) {
    AMBVehicleWhite,
    AMBVehicleRed,
    AMBVehicleSpecial1,
    AMBVehicleSpecial2
};

typedef NS_ENUM (int, AMBLevelType) {
    AMBCity1,
    AMBCity2,
    AMBCity3
};

typedef NS_ENUM(int, AMBGameType) {
    AMBGameTypeDayShift,
    AMBGameTypeSuddenDeath,
    AMBGameTypeEndless
};

#pragma mark CAMERA
static const CGFloat CAMERA_ROTATION_SPEED = 0.65;


#pragma mark CHARACTER - Collision Bitmasks
static const uint32_t categoryPlayer =                  0x1 << 0;
static const uint32_t categoryPatient =                 0x1 << 1;
static const uint32_t categoryHospital =                0x1 << 2;
static const uint32_t categoryTraffic =                 0x1 << 3; // the real body of the traffic vehicle
static const uint32_t categoryTrafficCollisionZone =    0x1 << 4; // the tailgate zone which the AI uses to determine if it should slow down
static const uint32_t categoryTrafficStoppingZone =     0x1 << 5; // the stopping zone which the AI uses to determine if it should stop
static const uint32_t categoryPowerup =                 0x1 << 6; // powerups (fuel etc)


#pragma mark FUEL GUAGE
static const CGFloat fuelCapacity = 124; // 124 total degrees in the gauge's rotation, this makes it easier
static const CGFloat fuelUnitDuration = 0.25; /** Number of seconds a single unit of fuel lasts for. */
static const NSInteger fuelUnitsInPowerup = 8;/** Amount of fuel you get when you run over a fuel powerup */

#pragma mark ON_SCREEN_INDICATOR
static const CGFloat OSI_PADDING =              40; // indicator padding from screen edge
static const CGFloat OSI_DUR_FADE_IN =          0.25;
static const CGFloat OSI_DUR_FADE_OUT =         0.25;

#pragma mark MOVING CHARACTER
static const float TURN_BUFFER = 1; // attempt a turn every frame for this many seconds after initial keypress. this helps reduce the accuracy required to hit a corner just right.

static const float PLAYER_NATIVE_SPEED = 600.0;
static const int TILE_LANE_WIDTH = 32;

#pragma mark PLAYER
static const CGFloat PLAYER_INVINCIBLE_TIME = 10.0; // how long is a player invincible for?

#pragma mark POWERUP
static const CGFloat FUEL_EXPIRY_DURATION = 30; // the fuel powerups expire after they spawn on the map
static const CGFloat FUEL_TIMER_INCREMENT = 25; // every x seconds, the fuel gets decremented

#pragma mark TRAFFIC VEHICLE
static const CGFloat speedMultiplier = 75; // the vehicle speed (1, 2, 3) gets multiplied by this
static const int tailgateZoneMultiplier = 2; // the zone in which tailgating is enabled is the vehicle's height multiplied by this value.
static const CGFloat resumeMovementDelayLower = 0.5; // if the vehicle is stopped, a random delay between when the blocking vehicle starts moving and when this vehicle starts moving.
static const CGFloat resumeMovementDelayUpper = 1.25;
static const CGFloat TRAFFIC_MAX_DISTANCE_FROM_PLAYER = 1500; // when traffic vehicles are within this many points away from the player, they will be activated. value is 1500 to allow for the maximum screen distance PLUS lots of extra padding to allow the randomized delay of traffic starting to move from its original position.

#pragma mark SCORE KEEPER
static const int SCORE_LABEL_SPACING = 34; // vertical spacing between score messages (e.g. "Safe DRiving bonus")
static const int SCORE_LABEL_FRAME_UPDATE = 2500; // add this many points per frame when animating the score label

static const float SCORE_TIMEBONUS_FAST = 5; // if <time elapsed/deliveryBenchmark> is less than this, the player gets the fast bonus
static const float SCORE_TIMEBONUS_SLOW = 15; // if <time elapsed/deliveryBenchmark> is greater than this, the player gets the slow bonus
                                            // anything between these, the player gets the medium bonus

static const int SCORE_PATIENT_SEVERITY_1 =                100000;
static const int SCORE_PATIENT_SEVERITY_2 =                200000;
static const int SCORE_PATIENT_SEVERITY_3 =                300000;
static const int SCORE_PATIENT_TTL_BONUS =                 50000;
static const int SCORE_SAFE_DRIVING_BONUS =                30000;
static const int SCORE_CARS_HIT_MAX =                      5;
static const int SCORE_CARS_HIT_MULTIPLIER =               SCORE_SAFE_DRIVING_BONUS / SCORE_CARS_HIT_MAX; // max number of cars you can hit, then you get a zero safe driving
static const int SCORE_END_ALL_PATIENTS_DELIVERED_BONUS =  10000;


#pragma mark GAME OVER SCENE ALIGNMENTS
static const int GAMEOVER_LEFT_JUSTIFICATION    =   80;  // distance between left of screen and score category text
static const int GAMEOVER_VALUE_PADDING         =   450; // distance between left of score category text and end of score value
