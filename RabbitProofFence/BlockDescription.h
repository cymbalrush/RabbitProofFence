//
//  BlockDescription.h
//  vf-hollywood
//
//  Created by Sinha, Gyanendra on 6/23/14.
//  Copyright (c) 2014 Conde Nast. All rights reserved.
//

#import <Foundation/Foundation.h>

//Refer to this http://clang.llvm.org/docs/Block-ABI-Apple.html

struct BlockLiteral {
    void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct block_descriptor {
        unsigned long int reserved;	// NULL
    	unsigned long int size;         // sizeof(struct Block_literal_1)
        // optional helper functions
    	void (*copy_helper)(void *dst, void *src);     // IFF (1<<25)
    	void (*dispose_helper)(void *src);             // IFF (1<<25)
        // required ABI.2010.3.16
        const char *signature;                         // IFF (1<<30)
    } *descriptor;
    // imported variables
};

enum {
    BlockDescriptionFlagsHasCopyDispose = (1 << 25),
    BlockDescriptionFlagsHasCtor = (1 << 26), // helpers have C++ code
    BlockDescriptionFlagsIsGlobal = (1 << 28),
    BlockDescriptionFlagsHasStret = (1 << 29), // IFF BLOCK_HAS_SIGNATURE
    BlockDescriptionFlagsHasSignature = (1 << 30)
};
typedef int BlockDescriptionFlags;

@interface BlockDescription : NSObject

@property (nonatomic, readonly) BlockDescriptionFlags flags;

@property (nonatomic, readonly) NSMethodSignature *blockSignature;

@property (nonatomic, readonly) unsigned long int size;

@property (nonatomic, readonly) id block;

- (id)initWithBlock:(id)block;

@end
