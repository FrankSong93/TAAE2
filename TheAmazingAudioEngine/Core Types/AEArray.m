//
//  AEArray.m
//  TheAmazingAudioEngine
//
//  Created by Michael Tyson on 30/03/2016.
//  Copyright © 2016 A Tasty Pixel. All rights reserved.
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import "AEArray.h"
#import "AEManagedValue.h"

typedef struct {
    void * pointer;
    int referenceCount;
} array_entry_t;

typedef struct {
    int count;
    __unsafe_unretained NSArray * objects;
    array_entry_t * entries[1];
} array_t;

@interface AEArray ()
@property (nonatomic, strong) AEManagedValue * value;
@property (nonatomic, strong, readwrite) NSArray * allValues;
@property (nonatomic, copy) void*(^mappingBlock)(id item);
@end

@implementation AEArray
@dynamic allValues, count;

- (instancetype)init {
    return [self initWithCustomMapping:nil];
}

- (instancetype)initWithCustomMapping:(void *(^)(id))block {
    if ( !(self = [super init]) ) return nil;
    self.mappingBlock = block;
    
    self.value = [AEManagedValue new];
    __unsafe_unretained AEArray * weakSelf = self;
    self.value.releaseBlock = ^(void * value) { [weakSelf releaseOldArray:(array_t*)value]; };
    
    array_t * array = (array_t*)calloc(1, sizeof(array_t));
    array->count = 0;
    self.value.pointerValue = array;
    
    return self;
}

- (void)dealloc {
    self.value = nil;
}

- (NSArray *)allValues {
    array_t * array = (array_t*)_value.pointerValue;
    return array->objects ? array->objects : @[];
}

- (int)count {
    array_t * array = (array_t*)_value.pointerValue;
    return array->count;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len {
    array_t * array = (array_t*)_value.pointerValue;
    return [array->objects countByEnumeratingWithState:state objects:buffer count:len];
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx {
    array_t * array = (array_t*)_value.pointerValue;
    return [array->objects objectAtIndexedSubscript:idx];
}

- (void *)pointerValueAtIndex:(int)index {
    array_t * array = (array_t*)_value.pointerValue;
    return array->count >= index ? array->entries[index]->pointer : NULL;
}

- (void *)pointerValueForObject:(id)object {
    array_t * array = (array_t*)_value.pointerValue;
    if ( !array->objects ) return NULL;
    NSUInteger index = [array->objects indexOfObject:object];
    if ( index == NSNotFound ) return NULL;
    return [self pointerValueAtIndex:(int)index];
}

- (void)updateWithContentsOfArray:(NSArray *)array {
    [self updateWithContentsOfArray:array customMapping:nil];
}

- (void)updateWithContentsOfArray:(NSArray *)array customMapping:(void * _Nonnull (^)(id _Nonnull, int))block {
    array_t * currentArray = (array_t*)_value.pointerValue;
    if ( currentArray && currentArray->objects && [currentArray->objects isEqualToArray:array] ) {
        // Arrays are identical - skip
        return;
    }
    
    array = [array copy];
    
    // Create new array
    array_t * newArray = (array_t*)malloc(sizeof(array_t) + (sizeof(void*) * array.count-1));
    newArray->count = (int)array.count;
    newArray->objects = array;
    CFBridgingRetain(array);
    
    array_t * priorArray = (array_t*)_value.pointerValue;
    
    int i=0;
    for ( id item in array ) {
        NSUInteger priorIndex = priorArray && priorArray->objects ? [priorArray->objects indexOfObject:item] : NSNotFound;
        if ( priorIndex != NSNotFound ) {
            // Copy value from prior array
            newArray->entries[i] = priorArray->entries[priorIndex];
            newArray->entries[i]->referenceCount++;
        } else {
            // Add new value
            newArray->entries[i] = (array_entry_t*)malloc(sizeof(array_entry_t));
            newArray->entries[i]->pointer = block ? block(item, i) : _mappingBlock ? _mappingBlock(item) : (__bridge void*)item;
            newArray->entries[i]->referenceCount = 1;
        }
        i++;
    }
    
    _value.pointerValue = newArray;
}

#pragma mark - Realtime thread accessors

AEArrayToken AEArrayGetToken(__unsafe_unretained AEArray * THIS) {
    return AEManagedValueGetValue(THIS->_value);
}

int AEArrayGetCount(AEArrayToken token) {
    return ((array_t*)token)->count;
}

void * AEArrayGetItem(AEArrayToken token, int index) {
    return ((array_t*)token)->entries[index]->pointer;
}

#pragma mark - Helpers

- (void)releaseOldArray:(array_t *)array {
    if ( _mappingBlock ) {
        for ( int i=0; i<array->count; i++ ) {
            array->entries[i]->referenceCount--;
            if ( array->entries[i]->referenceCount == 0 ) {
                if ( _releaseBlock ) {
                    _releaseBlock(array->objects[i], array->entries[i]->pointer);
                } else if ( array->entries[i]->pointer != (__bridge void*)array->objects[i] && array->entries[i]->pointer ) {
                    free(array->entries[i]->pointer);
                }
                free(array->entries[i]);
            }
        }
    }
    if ( array->objects ) CFRelease((CFTypeRef)array->objects);
    free(array);
}

@end
