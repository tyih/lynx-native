// Copyright 2017 The Lynx Authors. All rights reserved.

#import "LYXTreatment.h"
#import "LynxUI.h"
#import "LYXCoordinatorActionExecutor.h"
#import "LYXPixelUtil.h"
#import "LYXDefines.h"
#import "LYXCoordinatorTypes.h"
#import "LYXCoordinatorCommands.h"

#include "render/coordinator/coordinator_action.h"

@implementation LYXTreatment {
    BOOL _inited;
    LYXCoordinatorCommands *_commands;
    LYXCoordinatorActionExecutor *_actionExecutor;
}
NSString * const kAttrCoodinatorCommand = @"coordinator-command";
static NSString * const kCommandInit = @"init";
static NSString * const kCommandUpdateProperties = @"onPropertiesUpdated";

LYX_NOT_IMPLEMENTED(-(instancetype) init)

- (instancetype)initWithUI:(LynxUI *)ui {
    self = [super init];
    if (self) {
        _ui = ui;
        _inited = NO;
        _actionExecutor = [[LYXCoordinatorActionExecutor alloc] initWithUI:ui];
    }
    return self;
}

- (void) addCoordinatorCommand:(NSString *) content {
    _commands = [[LYXCoordinatorCommands alloc] initWithContent:content];
}

- (void) initialize:(LYXCommandExecutor *) executor {
    if (!_inited) {
        _inited = YES;
        lynx::CoordinatorAction action = [executor executeCommandWithMethod:kCommandInit
                                                                     andTag:_ui.coordinatorTag
                                                                    andArgs:NULL
                                                                  andLength:0];
        [_actionExecutor executeAction:action];
    }
}

- (void) onPropertiesUpdated:(LYXCommandExecutor *) executor {
    lynx::CoordinatorAction action = [executor executeCommandWithMethod:kCommandUpdateProperties
                                                                 andTag:_ui.coordinatorTag
                                                                andArgs:NULL
                                                              andLength:0];
    [_actionExecutor executeAction:action];
}

- (BOOL) onNestedScrollWithTop:(NSNumber *) scrollTop
                       andLeft:(NSNumber *) scrollLeft
                   andExecutor:(LYXCommandExecutor *) executor {
    double args[2];
    args[0] = [LYXPixelUtil pxToLynxNumber:scrollTop.intValue];
    args[1] = [LYXPixelUtil pxToLynxNumber:scrollLeft.intValue];
    NSString* command = [_commands getCommand:kCoordinatorType_Scroll];
    if (command) {
        lynx::CoordinatorAction action = [executor executeCommandWithMethod:command
                                                                     andTag:_ui.coordinatorTag
                                                                    andArgs:args
                                                                  andLength:2];
        [_actionExecutor executeAction:action];
    }
    return NO;
}

- (BOOL) onNestedTouchEvenWithExecutor:(LYXCommandExecutor *)executor {
    NSString* command = [_commands getCommand:kCoordinatorType_Touch];
    if (command) {
        double args[2] = {0, 0};
        
        lynx::CoordinatorAction action = [executor executeCommandWithMethod:command
                                                                     andTag:_ui.coordinatorTag
                                                                    andArgs:args
                                                                  andLength:2];
        [_actionExecutor executeAction:action];
        return action.consumed_;
    }
    return NO;
}

- (BOOL) onNestedActionWithType:(NSString *) type
                    andExecutor:(LYXCommandExecutor *) executor
                        andArgs:(NSArray *) args {
    if (_commands) {
        if ([type isEqualToString:kCoordinatorType_Scroll]) {
            return [self onNestedScrollWithTop:args[0]  andLeft:args[1] andExecutor:executor];
        } else if ([type isEqualToString:kCoordinatorType_Touch]) {
            return [self onNestedTouchEvenWithExecutor:executor];
        }
    }
    return NO;
}

@end
