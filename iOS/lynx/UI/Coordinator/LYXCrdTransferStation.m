// Copyright 2017 The Lynx Authors. All rights reserved.

#import "LYXCrdTransferStation.h"
#import "LYXPreTreatment.h"

@interface LYXCrdTransferStation()
// TransferStation
// affinity <-> responders
@property(nonatomic) NSMutableDictionary<NSString*, NSMutableSet<id<LYXCoordinatorResponder>>*> *coordinatorResponders;
// affinity <-> sponsor
@property(nonatomic) NSMutableDictionary<NSString*, id<LYXCoordinatorSponsor>> *coordinatorSponsors;
// affinity <-> executor
@property(nonatomic) NSMutableDictionary<NSString*, LYXCommandExecutor*> *executorPool;
// sponsor affinity <-> responder affinity
@property(nonatomic) NSMutableDictionary<NSString*, NSMutableSet<NSString*>*> *affinityRelationShip;
@property(nonatomic) LYXPreTreatment *preTreatment;

@end;

@implementation LYXCrdTransferStation

- (void)updateProperties:(NSDictionary *)object
         sponsorAffinity:(NSString *)sponsorAffinity
       responderAffinity:(NSString *)responderAffinity
                  notify:(BOOL)notify {
    if (_coordinatorResponders && _executorPool && _affinityRelationShip) {
        NSSet<NSString *> *responderAffinityList = _affinityRelationShip[sponsorAffinity];
        if (!responderAffinityList) return;
        LYXCommandExecutor *executor = _executorPool[responderAffinity];
        NSSet<id<LYXCoordinatorResponder>> *set = _coordinatorResponders[responderAffinity];
        if (!executor || !set) return;
        for (NSString * name in object.allKeys) {
            id value = object[name];
            if ([value isKindOfClass:[NSString class]]) {
                [executor updateProperty:name withStr:value];
            } else if ([value isKindOfClass:[NSNumber class]]) {
                NSNumber *number = value;
                if (number.objCType[0] == 'c') {
                    [executor updateProperty:name withBool:number.boolValue];
                } else {
                    [executor updateProperty:name withDouble:number.doubleValue];
                }
            }
        }
        if (notify) {
            // Notify responder
            for (id<LYXCoordinatorResponder> responder : set) {
                [responder.coordinatorTreatment onPropertiesUpdated:executor];
            }
            // Notify sponsor which is a responder
            id<LYXCoordinatorSponsor> sponsor = _coordinatorSponsors[sponsorAffinity];
            if (sponsor && [sponsor conformsToProtocol:@protocol(LYXCoordinatorResponder)]) {
                LYXTreatment *sponsorTreatment = ((id<LYXCoordinatorResponder>) sponsor).coordinatorTreatment;
                if (sponsorTreatment) {
                    [sponsorTreatment onPropertiesUpdated:executor];
                }
            }
        }
    }
}

- (void) addExecutableAction:(NSString *) executable
             sponsorAffinity:(NSString *) sponsorAffinity
           responderAffinity:(NSString *) responderAffinity {
    if (!_affinityRelationShip) {
        _affinityRelationShip = [[NSMutableDictionary alloc] init];
    }
    if (!_executorPool) {
        _executorPool = [[NSMutableDictionary alloc] init];
    }
    NSMutableSet<NSString*> *responderAffinityList = _affinityRelationShip[sponsorAffinity];
    if (!responderAffinityList) {
        responderAffinityList = [[NSMutableSet alloc] init];
        [_affinityRelationShip setObject:responderAffinityList forKey:sponsorAffinity];
    }
    [responderAffinityList addObject:responderAffinity];
    
    LYXCommandExecutor *executor = _executorPool[responderAffinity];
    if (!executor) {
        executor = [[LYXCommandExecutor alloc] initWithExecutableContent:executable];
        [_executorPool setObject:executor forKey:responderAffinity];
    } else {
        [executor updateExecutableContent:executable];
    }
    
    if (!_preTreatment) {
        _preTreatment = [[LYXPreTreatment alloc] init];
    }
    // Init responder
    if (_coordinatorResponders) {
        NSMutableSet<id<LYXCoordinatorResponder>> *set = _coordinatorResponders[responderAffinity];
        if (set) {
            for (id<LYXCoordinatorResponder> responder in set) {
                [responder.coordinatorTreatment initialize:executor];
            }
        }
    }
    // Init sponsor which is a responder
    if (_coordinatorSponsors) {
        id<LYXCoordinatorSponsor> sponsor = _coordinatorSponsors[sponsorAffinity];
        if (sponsor && [sponsor conformsToProtocol:@protocol(LYXCoordinatorResponder)]) {
            LYXTreatment *sponsorTreatment = ((id<LYXCoordinatorResponder>) sponsor).coordinatorTreatment;
            if (sponsorTreatment) {
                [sponsorTreatment initialize:executor];
            }
        }
    }
}

- (void) removeExecutableActionWithSponsorAffinity:(NSString *) sponsorAffinity
                                 responderAffinity:(NSString *) responderAffinity {
    if (!_affinityRelationShip || !_executorPool) {
        return;
    }
    NSMutableSet<NSString*> *responderAffinityList = _affinityRelationShip[sponsorAffinity];
    if (responderAffinityList) {
        [responderAffinityList removeObject:responderAffinity];
        [_executorPool removeObjectForKey:responderAffinity];
    }
}

- (void) removeAllExecutableAction {
    [_affinityRelationShip removeAllObjects];
    [_executorPool removeAllObjects];
}

- (void) addCoordinatorSponsor:(id<LYXCoordinatorSponsor>) sponsor {
    if (!_coordinatorSponsors) {
        _coordinatorSponsors = [[NSMutableDictionary alloc] init];
    }
    [_coordinatorSponsors setObject:sponsor forKey:sponsor.coordinatorAffinity];
    
    // Init sponsor which is a responder
    if (!_affinityRelationShip) return;
    NSMutableSet<NSString*> *responderAffinityList = _affinityRelationShip[sponsor.coordinatorAffinity];
    LYXTreatment *sponsorTreatment = nil;
    if ([sponsor conformsToProtocol:@protocol(LYXCoordinatorResponder)]) {
        sponsorTreatment = ((id<LYXCoordinatorResponder>) sponsor).coordinatorTreatment;
    }
    if (!responderAffinityList || !sponsorTreatment) return;
    for (NSString *responderAffinity : responderAffinityList) {
        LYXCommandExecutor *executor = _executorPool[responderAffinity];
        if (executor) [sponsorTreatment initialize:executor];
    }
}

- (void) removeCoordinatorSponsor:(id<LYXCoordinatorSponsor>) sponsor {
    if (_coordinatorSponsors) {
        [_coordinatorSponsors removeObjectForKey:sponsor.coordinatorAffinity];
    }
}

- (void) addCoordinatorResponder:(id<LYXCoordinatorResponder>) responder {
    if (!_coordinatorResponders) {
        _coordinatorResponders = [[NSMutableDictionary alloc] init];
    }
    NSMutableSet<id<LYXCoordinatorResponder>> *set = _coordinatorResponders[responder.coordinatorAffinity];
    if (!set) {
        set = [[NSMutableSet alloc] init];
        [_coordinatorResponders setObject:set forKey:responder.coordinatorAffinity];
    }
    [set addObject:responder];
    // Init responder
    if (_executorPool) {
        LYXCommandExecutor *executor = _executorPool[responder.coordinatorAffinity];
        if (executor) {
            [responder.coordinatorTreatment initialize:executor];
        }
    }
}

- (void) removeCoordinatorResponder:(id<LYXCoordinatorResponder>) responder {
    if (_coordinatorResponders && responder) {
        NSString *affinity = [responder coordinatorAffinity];
        NSMutableSet<id<LYXCoordinatorResponder>>* array = _coordinatorResponders[affinity];
        if (array) {
            [array removeObject:responder];
        }
    }
}

- (BOOL) dispatchNestedActionType: (NSString *) type
                          sponsor: (id<LYXCoordinatorSponsor>) sponsor
                           params: (NSArray *) params {
    BOOL consumed = NO;
    if (_coordinatorResponders && _executorPool && _affinityRelationShip) {
        NSMutableSet<NSString*> *responderAffinityList = _affinityRelationShip[sponsor.coordinatorAffinity];;
        if (!responderAffinityList) return consumed;
        
        LYXTreatment *sponsorTreatment = nil;
        if ([sponsor conformsToProtocol:@protocol(LYXCoordinatorResponder)]) {
            sponsorTreatment = ((id<LYXCoordinatorResponder>) sponsor).coordinatorTreatment;
        }
        
        for (NSString *responderAffinity in responderAffinityList) {
            LYXCommandExecutor *executor = _executorPool[responderAffinity];
            NSMutableSet<id<LYXCoordinatorResponder>> *set = _coordinatorResponders[responderAffinity];
            if (!executor || !set) continue;
            // First call onDispatch
            consumed = [_preTreatment dispatchAction:type
                                         andExecutor:executor
                                              andTag:sponsor.coordinatorTag
                                           andParams:params];
            if (sponsorTreatment) {
                [sponsorTreatment onNestedActionWithType:type andExecutor:executor andArgs:params];
            }
            for (id<LYXCoordinatorResponder> responder in set) {
                [responder.coordinatorTreatment onNestedActionWithType:type andExecutor:executor andArgs:params];
            }
        }
    }
    return consumed;
}

@end
