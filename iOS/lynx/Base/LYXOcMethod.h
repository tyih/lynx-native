// Copyright 2017 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LYXOcProperty.h"

typedef struct LYXMethodInfo {
    const char *const js_name;
    const char *const method;
} LYXMethodInfo;

@interface LYXOcMethod : NSObject

@property(nonatomic, readonly) Class clazz;
@property(nonatomic, readonly) const LYXMethodInfo * info;
@property(nonatomic, readonly) NSString *signature;
@property(nonatomic, readonly) NSString *name;
@property(nonatomic, readonly) LYXOcProperty *returnType;
@property(nonatomic, readonly) LYXOcProperty *argumentTypes;
@property(nonatomic, readonly) SEL selector;

- (instancetype) initWithInfo:(const LYXMethodInfo *)info
                     andClass:(Class) clazz NS_DESIGNATED_INITIALIZER;

- (id) invokeWithReceiver:(id) object
                  andArgs:(NSArray *) args;

+ (NSString *) generateSingatureWithReciever:(Class) clazz
                                  methodName:(NSString *)name
                                        args:(NSArray*) args;

@end
