//
//  NCDBDgmppItem.h
//  NCDatabase
//
//  Created by Артем Шиманский on 30.12.15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBDgmppItemCategory, NCDBDgmppItemDamage, NCDBDgmppItemGroup, NCDBDgmppItemRequirements, NCDBDgmppItemShipResources, NCDBInvType, NCDBDgmppItemSpaceStructureResources;

NS_ASSUME_NONNULL_BEGIN

@interface NCDBDgmppItem : NSManagedObject

// Insert code here to declare functionality of your managed object subclass

@end

NS_ASSUME_NONNULL_END

#import "NCDBDgmppItem+CoreDataProperties.h"
