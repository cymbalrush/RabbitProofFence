//
//  DFLazyValueGenerator.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import "DFMetaOperation.h"
#import "StreamOperation.h"

@interface DFSequenceGenerator : DFOperation <StreamOperation>

+ (void)terminateValueGeneration;

- (instancetype)initWithGeneratorBlock:(id)generatorBlock ports:(NSArray *)ports;

- (void)generateNext;

@end

@interface ArraySequenceGenerator : DFSequenceGenerator

//incoming port
@property (nonatomic, strong) NSArray *array;

+ (ArraySequenceGenerator *)sequenceGenerator;

@end

@interface KeyValue : NSObject

@property (strong, nonatomic) id key;

@property (strong, nonatomic) id value;

@end

@interface DictionarySequenceGenerator : DFSequenceGenerator

//incoming port
@property (nonatomic, strong) NSDictionary *dictionary;

@property (nonatomic, strong) KeyValue *output;

+ (DictionarySequenceGenerator *)sequenceGenerator;

@end
