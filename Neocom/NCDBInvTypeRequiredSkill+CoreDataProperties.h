//
//  NCDBInvTypeRequiredSkill+CoreDataProperties.h
//  Neocom
//
//  Created by Artem Shimanski on 29.11.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBInvTypeRequiredSkill.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBInvTypeRequiredSkill (CoreDataProperties)

@property (nonatomic) int16_t skillLevel;
@property (nullable, nonatomic, retain) NCDBInvType *skillType;
@property (nullable, nonatomic, retain) NCDBInvType *type;

@end

NS_ASSUME_NONNULL_END
