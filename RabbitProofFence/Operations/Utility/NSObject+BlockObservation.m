//
//  NSObject+BlockObservation.h
//  Version 1.0
//
//  Andy Matuschak
//  andy@andymatuschak.org
//  Public domain because I love you. Let me know how you use it.
//

#import "NSObject+BlockObservation.h"
#import <dispatch/dispatch.h>
#import <objc/runtime.h>

@interface AMObserverTrampoline : NSObject
{
    __weak id observee;
    __strong NSString *keyPath;
     __strong AMBlockTask task;
    __strong NSOperationQueue *queue;
    dispatch_once_t cancellationPredicate;
}

- (AMObserverTrampoline *)initObservingObject:(id)obj keyPath:(NSString *)keyPath onQueue:(NSOperationQueue *)queue task:(AMBlockTask)task;
- (void)cancelObservation;
@end

@implementation AMObserverTrampoline

static NSString *AMObserverTrampolineContext = @"AMObserverTrampolineContext";

- (AMObserverTrampoline *)initObservingObject:(id)obj keyPath:(NSString *)newKeyPath onQueue:(NSOperationQueue *)newQueue task:(AMBlockTask)newTask
{
    if (!(self = [super init])) return nil;
    task = [newTask copy];
    keyPath = [newKeyPath copy];
    queue = newQueue;
    observee = obj;
    cancellationPredicate = 0;
    [observee addObserver:self
               forKeyPath:keyPath
                  options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                  context:(__bridge void *)(AMObserverTrampolineContext)];
    return self;
}

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == (__bridge void *)(AMObserverTrampolineContext))
    {
        if (queue)
            [queue addOperationWithBlock:^{ task(object, change); }];
        else
            task(object, change);
    }
}

- (void)cancelObservation
{
    dispatch_once(&cancellationPredicate, ^{
        [observee removeObserver:self forKeyPath:keyPath];
        observee = nil;
    });
}

- (AMBlockToken *)token
{
    return [NSValue valueWithPointer:&task];
}

- (void)dealloc
{
    [self cancelObservation];
}

@end

static NSString *AMObserverMapKey = @"org.andymatuschak.observerMap";
static dispatch_queue_t AMObserverMutationQueue = NULL;

static dispatch_queue_t AMObserverMutationQueueCreatingIfNecessary()
{
    static dispatch_once_t queueCreationPredicate = 0;
    dispatch_once(&queueCreationPredicate, ^{
        AMObserverMutationQueue = dispatch_queue_create("org.andymatuschak.observerMutationQueue", 0);
    });
    return AMObserverMutationQueue;
}

@implementation NSObject (AMBlockObservation)

- (AMBlockToken *)addObserverForKeyPath:(NSString *)keyPath task:(AMBlockTask)task
{
    return [self addObserverForKeyPath:keyPath onQueue:nil task:task];
}

- (AMBlockToken *)addObserverForKeyPath:(NSString *)keyPath onQueue:(NSOperationQueue *)queue task:(AMBlockTask)task
{
    __block AMBlockToken *token = nil;
    dispatch_sync(AMObserverMutationQueueCreatingIfNecessary(), ^{
        NSMutableDictionary *dict = objc_getAssociatedObject(self, (__bridge const void *)(AMObserverMapKey));
        if (!dict)
        {
            dict = [[NSMutableDictionary alloc] init];
            objc_setAssociatedObject(self, (__bridge const void *)(AMObserverMapKey), dict, OBJC_ASSOCIATION_RETAIN);
        }
        AMObserverTrampoline *trampoline = [[AMObserverTrampoline alloc] initObservingObject:self
                                                                                     keyPath:keyPath
                                                                                     onQueue:queue
                                                                                        task:task];
        token = [trampoline token];
        [dict setObject:trampoline forKey:token];
    });
    return token;
}

- (void)removeObserverWithBlockToken:(AMBlockToken *)token
{
    dispatch_sync(AMObserverMutationQueueCreatingIfNecessary(), ^{
        NSMutableDictionary *observationDictionary = objc_getAssociatedObject(self, (__bridge const void *)(AMObserverMapKey));
        AMObserverTrampoline *trampoline = [observationDictionary objectForKey:token];
        if (!trampoline)
        {
            NSLog(@"[NSObject(AMBlockObservation) removeObserverWithBlockToken]: Ignoring attempt to remove non-existent observer on %@ for token %@.", self, token);
            return;
        }
        [trampoline cancelObservation];
        [observationDictionary removeObjectForKey:token];
        
        // Due to a bug in the obj-c runtime, this dictionary does not get cleaned up on release when running without GC.
        if ([observationDictionary count] == 0)
            objc_setAssociatedObject(self, (__bridge const void *)(AMObserverMapKey), nil, OBJC_ASSOCIATION_RETAIN);
    });
}

@end
