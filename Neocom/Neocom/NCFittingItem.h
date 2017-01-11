//
//  NCFittingItem.h
//  Neocom
//
//  Created by Artem Shimanski on 04.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NCFittingTypes.h"

@class NCFittingItem;
@class NCFittingAttribute;
@interface NCFittingAttributes : NSObject

- (nullable NCFittingAttribute*) objectAtIndexedSubscript:(NSInteger) attributeID;

@end

@interface NCFittingItem : NSObject
@property (readonly) NSInteger typeID;
@property (readonly, nonnull) NSString* typeName;
@property (readonly, nonnull) NSString* groupName;
@property (readonly) NSInteger groupID;
@property (readonly) NSInteger categoryID;
@property (readonly, nullable) NCFittingItem* owner;
@property (readonly, nonnull) NCFittingAttributes* attributes;

- (nonnull instancetype) init NS_SWIFT_UNAVAILABLE("");

@end