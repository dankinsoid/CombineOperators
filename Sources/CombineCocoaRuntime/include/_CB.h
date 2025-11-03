//
//  _CB.h
//  RxCocoa
//
//  Created by Krunoslav Zaher on 7/12/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/**
 ################################################################################
 This file is part of CB private API
 ################################################################################
 */

#if        TRACE_RESOURCES >= 2
#   define DLOG(...)         NSLog(__VA_ARGS__)
#else
#   define DLOG(...)
#endif

#if        DEBUG
#   define ABORT_IN_DEBUG    abort();
#else
#   define ABORT_IN_DEBUG
#endif


#define SEL_VALUE(x)      [NSValue valueWithPointer:(x)]
#define CLASS_VALUE(x)    [NSValue valueWithNonretainedObject:(x)]
#define IMP_VALUE(x)      [NSValue valueWithPointer:(x)]

/**
 Checks that the local `error` instance exists before assigning it's value by reference.
 This macro exists to work around static analysis warnings — `NSError` is always assumed to be `nullable`, even though we explicitly define the method parameter as `nonnull`. See http://www.openradar.me/21766176 for more details.
 */
#define CB_THROW_ERROR(errorValue, returnValue) if (error != nil) { *error = (errorValue); } return (returnValue);

#define CB_CAT2(_1, _2) _CB_CAT2(_1, _2)
#define _CB_CAT2(_1, _2) _1 ## _2

#define CB_ELEMENT_AT(n, ...) CB_CAT2(_CB_ELEMENT_AT_, n)(__VA_ARGS__)
#define _CB_ELEMENT_AT_0(x, ...) x
#define _CB_ELEMENT_AT_1(_0, x, ...) x
#define _CB_ELEMENT_AT_2(_0, _1, x, ...) x
#define _CB_ELEMENT_AT_3(_0, _1, _2, x, ...) x
#define _CB_ELEMENT_AT_4(_0, _1, _2, _3, x, ...) x
#define _CB_ELEMENT_AT_5(_0, _1, _2, _3, _4, x, ...) x
#define _CB_ELEMENT_AT_6(_0, _1, _2, _3, _4, _5, x, ...) x

#define CB_COUNT(...) CB_ELEMENT_AT(6, ## __VA_ARGS__, 6, 5, 4, 3, 2, 1, 0)
#define CB_EMPTY(...) CB_ELEMENT_AT(6, ## __VA_ARGS__, 0, 0, 0, 0, 0, 0, 1)

/**
 #define SUM(context, index, head, tail) head + tail
 #define MAP(context, index, element) (context)[index] * (element)

 CB_FOR(numbers, SUM, MAP, b0, b1, b2);

 (numbers)[0] * (b0) + (numbers)[1] * (b1) + (numbers[2]) * (b2)
 */

#define CB_FOREACH(context, concat, map, ...) CB_FOR_MAX(CB_COUNT(__VA_ARGS__), _CB_FOREACH_CONCAT, _CB_FOREACH_MAP, context, concat, map, __VA_ARGS__)
#define _CB_FOREACH_CONCAT(index, head, tail, context, concat, map, ...) concat(context, index, head, tail)
#define _CB_FOREACH_MAP(index, context, concat, map, ...) map(context, index, CB_ELEMENT_AT(index, __VA_ARGS__))

/**
 #define MAP(context, index, item) (context)[index] * (item)

 CB_FOR_COMMA(numbers, MAP, b0, b1);

 ,(numbers)[0] * b0, (numbers)[1] * b1
 */
#define CB_FOREACH_COMMA(context, map, ...) CB_CAT2(_CB_FOREACH_COMMA_EMPTY_, CB_EMPTY(__VA_ARGS__))(context, map, ## __VA_ARGS__)
#define _CB_FOREACH_COMMA_EMPTY_1(context, map, ...)
#define _CB_FOREACH_COMMA_EMPTY_0(context, map, ...) , CB_FOR_MAX(CB_COUNT(__VA_ARGS__), _CB_FOREACH_COMMA_CONCAT, _CB_FOREACH_COMMA_MAP, context, map, __VA_ARGS__)
#define _CB_FOREACH_COMMA_CONCAT(index, head, tail, context, map, ...) head, tail
#define _CB_FOREACH_COMMA_MAP(index, context, map, ...) map(context, index, CB_ELEMENT_AT(index, __VA_ARGS__))

// rx for

#define CB_FOR_MAX(max, concat, map, ...) CB_CAT2(CB_FOR_, max)(concat, map, ## __VA_ARGS__)

#define CB_FOR_0(concat, map, ...)
#define CB_FOR_1(concat, map, ...) map(0, __VA_ARGS__)
#define CB_FOR_2(concat, map, ...) concat(1, CB_FOR_1(concat, map, ## __VA_ARGS__), map(1, __VA_ARGS__), __VA_ARGS__)
#define CB_FOR_3(concat, map, ...) concat(2, CB_FOR_2(concat, map, ## __VA_ARGS__), map(2, __VA_ARGS__), __VA_ARGS__)
#define CB_FOR_4(concat, map, ...) concat(3, CB_FOR_3(concat, map, ## __VA_ARGS__), map(3, __VA_ARGS__), __VA_ARGS__)
#define CB_FOR_5(concat, map, ...) concat(4, CB_FOR_4(concat, map, ## __VA_ARGS__), map(4, __VA_ARGS__), __VA_ARGS__)
#define CB_FOR_6(concat, map, ...) concat(5, CB_FOR_5(concat, map, ## __VA_ARGS__), map(5, __VA_ARGS__), __VA_ARGS__)

