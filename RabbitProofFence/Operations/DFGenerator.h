//
//  DFLazyValueGenerator.h

//
//  Created by Sinha, Gyanendra on 6/23/14.

//

#import "DFMetaOperation.h"
#import "StreamOperation.h"

@interface DFGenerator : DFOperation <StreamOperation>

+ (void)terminateValueGeneration;

+ (instancetype)generator;

- (instancetype)initWithGeneratorBlock:(id)generatorBlock ports:(NSArray *)ports;

- (BOOL)next;

- (void)stop;

@end

@interface ArrayGenerator : DFGenerator

//incoming port
@property (nonatomic, strong) NSArray *array;

@end

@interface KeyValue : NSObject

@property (strong, nonatomic) id key;

@property (strong, nonatomic) id value;

@end

@interface DictionaryGenerator : DFGenerator

//incoming port
@property (strong, nonatomic) NSDictionary *dictionary;

@property (readonly, nonatomic) KeyValue *output;

@end

@interface SetGenerator : DFGenerator

//incoming port
@property (nonatomic, strong) NSSet *set;

@end

@interface SequenceGenerator : DFGenerator

@property (strong, nonatomic) NSNumber *i;

@property (strong, nonatomic) NSNumber *j;

@property (strong, nonatomic) NSNumber *inc;

@property (readonly, nonatomic) NSNumber *output;

@end

@interface RepeatGenerator : DFGenerator

@property (strong, nonatomic) id input;

@property (strong, nonatomic) NSNumber *n;

@end

@interface ForeverGenerator : DFGenerator

@property (strong, nonatomic) id input;

@end

