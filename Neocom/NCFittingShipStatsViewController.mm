//
//  NCFittingShipStatsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 01.04.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingShipStatsViewController.h"
#import "NCFittingShipViewController.h"
#import "NCFittingShipWeaponsCell.h"
#import "NCFittingShipResourcesCell.h"
#import "NCFittingResistancesCell.h"
#import "NCFittingEHPCell.h"
#import "NCFittingShipCapacitorCell.h"
#import "NCFittingShipFirepowerCell.h"
#import "NCFittingShipTankCell.h"
#import "NCFittingShipMiscCell.h"
#import "NCFittingShipPriceCell.h"
#import "NSString+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCPriceManager.h"
#import "NCTableViewHeaderView.h"

@interface NCFittingShipStatsViewControllerRow : NSObject
@property (nonatomic, assign) BOOL isUpToDate;
@property (nonatomic, strong) NSDictionary* data;
@property (nonatomic, strong) NSString* cellIdentifier;
@property (nonatomic, copy) void (^configurationBlock)(id tableViewCell, NSDictionary* data);
@property (nonatomic, copy) void (^loadingBlock)(NCFittingShipStatsViewController* controller, void (^completionBlock)(NSDictionary* data));
@end

@interface NCFittingShipStatsViewControllerSection : NSObject
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSArray* rows;
@end

@interface NCFittingShipStatsViewControllerShipStats : NSObject
@property (nonatomic, assign) float totalPG;
@property (nonatomic, assign) float usedPG;
@property (nonatomic, assign) float totalCPU;
@property (nonatomic, assign) float usedCPU;
@property (nonatomic, assign) float totalCalibration;
@property (nonatomic, assign) float usedCalibration;
@property (nonatomic, assign) int usedTurretHardpoints;
@property (nonatomic, assign) int totalTurretHardpoints;
@property (nonatomic, assign) int usedMissileHardpoints;
@property (nonatomic, assign) int totalMissileHardpoints;

@property (nonatomic, assign) float totalDB;
@property (nonatomic, assign) float usedDB;
@property (nonatomic, assign) float totalBandwidth;
@property (nonatomic, assign) float usedBandwidth;
@property (nonatomic, assign) int maxActiveDrones;
@property (nonatomic, assign) int activeDrones;
@property (nonatomic, assign) eufe::Resistances resistances;
@property (nonatomic, assign) eufe::HitPoints hp;
@property (nonatomic, assign) float ehp;
@property (nonatomic, assign) eufe::Tank rtank;
@property (nonatomic, assign) eufe::Tank stank;
@property (nonatomic, assign) eufe::Tank ertank;
@property (nonatomic, assign) eufe::Tank estank;

@property (nonatomic, assign) float capCapacity;
@property (nonatomic, assign) BOOL capStable;
@property (nonatomic, assign) float capState;
@property (nonatomic, assign) float capacitorRechargeTime;
@property (nonatomic, assign) float delta;

@property (nonatomic, assign) float weaponDPS;
@property (nonatomic, assign) float droneDPS;
@property (nonatomic, assign) float volleyDamage;
@property (nonatomic, assign) float dps;

@property (nonatomic, assign) int targets;
@property (nonatomic, assign) float targetRange;
@property (nonatomic, assign) float scanRes;
@property (nonatomic, assign) float sensorStr;
@property (nonatomic, assign) float speed;
@property (nonatomic, assign) float alignTime;
@property (nonatomic, assign) float signature;
@property (nonatomic, assign) float cargo;
@property (nonatomic, assign) float mass;
@property (nonatomic, strong) UIImage *sensorImage;
@property (nonatomic, strong) NCDamagePattern* damagePattern;
@property (nonatomic, assign) float droneRange;
@property (nonatomic, assign) float warpSpeed;

@end

@interface NCFittingShipStatsViewControllerPriceStats : NSObject
@property (nonatomic, assign) float shipPrice;
@property (nonatomic, assign) float fittingsPrice;
@property (nonatomic, assign) float dronesPrice;
@property (nonatomic, assign) float totalPrice;
@end

@implementation NCFittingShipStatsViewControllerShipStats
@end

@implementation NCFittingShipStatsViewControllerPriceStats
@end


@interface NCFittingShipStatsViewController()
@property (nonatomic, strong) NSArray* sections;
@property (nonatomic, strong) NCFittingShipStatsViewControllerShipStats* shipStats;
@property (nonatomic, strong) NCFittingShipStatsViewControllerPriceStats* priceStats;
@property (nonatomic, strong) NCPriceManager* priceManager;
@property (nonatomic, strong) NCTaskManager* pricesTaskManager;
@end


@implementation NCFittingShipStatsViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	self.pricesTaskManager = [[NCTaskManager alloc] initWithViewController:self];
	
	self.priceManager = [NCPriceManager sharedManager];
}

- (void) reloadWithCompletionBlock:(void (^)())completionBlock {
	auto pilot = self.controller.fit.pilot;
	if (pilot) {
		if (self.sections) {
			for (NCFittingShipStatsViewControllerSection* section in self.sections)
				for (NCFittingShipStatsViewControllerRow* row in section.rows)
					row.isUpToDate = NO;
			completionBlock();
		}
		else {
			[self.controller.engine performBlock:^{
				NSMutableArray* sections = [NSMutableArray new];
				
				NCFittingShipStatsViewControllerSection* section;
				NCFittingShipStatsViewControllerRow* row;
				
				section = [NCFittingShipStatsViewControllerSection new];
				section.title = NSLocalizedString(@"Resources", nil);
				{
					NSMutableArray* rows = [NSMutableArray new];
					row = [NCFittingShipStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingShipWeaponsCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCFittingShipWeaponsCell* cell = tableViewCell;
						cell.turretsLabel.text = data[@"turrets"];
						cell.turretsLabel.textColor = data[@"turretsColor"];
						
						cell.launchersLabel.text = data[@"launchers"];
						cell.launchersLabel.textColor = data[@"launchersColor"];
						
						cell.calibrationLabel.text = data[@"calibration"];
						cell.calibrationLabel.textColor = data[@"calibrationColor"];
						
						cell.dronesLabel.text = data[@"drones"];
						cell.dronesLabel.textColor = data[@"dronesColor"];
					};
					row.loadingBlock = ^(NCFittingShipStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						auto character = controller.controller.fit.pilot;
						if (character) {
							[controller.controller.engine performBlock:^{
								auto ship = character->getShip();
								int usedTurretHardpoints = ship->getUsedHardpoints(eufe::Module::HARDPOINT_TURRET);
								int totalTurretHardpoints = ship->getNumberOfHardpoints(eufe::Module::HARDPOINT_TURRET);
								int usedMissileHardpoints = ship->getUsedHardpoints(eufe::Module::HARDPOINT_LAUNCHER);
								int totalMissileHardpoints = ship->getNumberOfHardpoints(eufe::Module::HARDPOINT_LAUNCHER);

								int calibrationUsed = ship->getCalibrationUsed();
								int totalCalibration = ship->getTotalCalibration();

								int activeDrones = ship->getActiveDrones();
								int maxActiveDrones = ship->getMaxActiveDrones();

								NSDictionary* data =
								@{@"turrets": [NSString stringWithFormat:@"%d/%d", usedTurretHardpoints, totalTurretHardpoints],
								  @"turretsColor": usedTurretHardpoints > totalTurretHardpoints ? [UIColor redColor] : [UIColor whiteColor],
								  @"launchers": [NSString stringWithFormat:@"%d/%d", usedMissileHardpoints, totalMissileHardpoints],
								  @"launchersColor": usedMissileHardpoints > totalMissileHardpoints ? [UIColor redColor] : [UIColor whiteColor],
								  @"calibration": [NSString stringWithFormat:@"%d/%d", calibrationUsed, totalCalibration],
								  @"calibrationColor": calibrationUsed > totalCalibration ? [UIColor redColor] : [UIColor whiteColor],
								  @"drones": [NSString stringWithFormat:@"%d/%d", activeDrones, maxActiveDrones],
								  @"dronesColor": activeDrones > maxActiveDrones ? [UIColor redColor] : [UIColor whiteColor]};
								dispatch_async(dispatch_get_main_queue(), ^{
									completionBlock(data);
								});
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					
					row = [NCFittingShipStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingShipResourcesCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCFittingShipResourcesCell* cell = (NCFittingShipResourcesCell*) tableViewCell;
						cell.powerGridLabel.text = data[@"powerGrid"];
						cell.powerGridLabel.progress = [data[@"powerGridProgress"] floatValue];
						cell.cpuLabel.text = data[@"cpu"];
						cell.cpuLabel.progress = [data[@"cpuProgress"] floatValue];
						cell.droneBandwidthLabel.text = data[@"droneBandwidth"];
						cell.droneBandwidthLabel.progress = [data[@"droneBandwidthProgress"] floatValue];
						cell.droneBayLabel.text = data[@"droneBay"];
						cell.droneBayLabel.progress = [data[@"droneBayProgress"] floatValue];
					};
					row.loadingBlock = ^(NCFittingShipStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						auto character = controller.controller.fit.pilot;
						if (character) {
							[controller.controller.engine performBlock:^{
								auto ship = character->getShip();
								int totalPG = ship->getTotalPowerGrid();
								int usedPG = ship->getPowerGridUsed();
								int totalCPU = ship->getTotalCpu();
								int usedCPU = ship->getCpuUsed();
								int totalBandwidth = ship->getTotalDroneBandwidth();
								int usedBandwidth = ship->getDroneBandwidthUsed();
								int totalDB = ship->getTotalDroneBay();
								int usedDB = ship->getDroneBayUsed();
								
								NSDictionary* data =
								@{@"powerGrid": [NSString stringWithTotalResources:totalPG usedResources:usedPG unit:@"MW"],
								  @"powerGridProgress": totalPG > 0 ? @(usedPG / totalPG) : @(0),
								  @"cpu": [NSString stringWithTotalResources:totalCPU usedResources:usedCPU unit:@"tf"],
								  @"cpuProgress": totalCPU > 0 ? @(usedCPU / totalCPU) : @(0),
								  @"droneBandwidth": [NSString stringWithTotalResources:totalBandwidth usedResources:usedBandwidth unit:@"Mbit/s"],
								  @"droneBandwidthProgress": totalBandwidth > 0 ? @(usedBandwidth / totalBandwidth) : @(0),
								  @"droneBay": [NSString stringWithTotalResources:totalDB usedResources:usedDB unit:@"m3"],
								  @"droneBayProgress": totalDB > 0 ? @(usedDB / totalDB) : @(0)};
								dispatch_async(dispatch_get_main_queue(), ^{
									completionBlock(data);
								});
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					section.rows = rows;
				}
				[sections addObject:section];
				
				section = [NCFittingShipStatsViewControllerSection new];
				section.title = NSLocalizedString(@"Resistances", nil);
				{
					NSMutableArray* rows = [NSMutableArray new];
					row = [NCFittingShipStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingResistancesHeaderCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
					};
					row.loadingBlock = ^(NCFittingShipStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						completionBlock(nil);
					};
					[rows addObject:row];
					
					NSArray* images = @[@"shield.png", @"armor.png", @"hull.png", @"damagePattern.png"];
					for (int i = 0; i < 4; i++) {
						row = [NCFittingShipStatsViewControllerRow new];
						row.cellIdentifier = @"NCFittingEHPCell";
						row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
							NCFittingResistancesCell* cell = (NCFittingResistancesCell*) tableViewCell;
							NCProgressLabel* labels[] = {cell.emLabel, cell.thermalLabel, cell.kineticLabel, cell.explosiveLabel};
							NSArray* values = data[@"values"];
							NSArray* texts = data[@"texts"];
							for (int i = 0; i < 4; i++) {
								labels[i].progress = [values[i] floatValue];
								labels[i].text = texts[i];
							}
							cell.hpLabel.text = data[@"hp"];
							cell.categoryImageView.image = data[@"categoryImage"];
						};
						row.loadingBlock = ^(NCFittingShipStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
							auto character = controller.controller.fit.pilot;
							if (character) {
								[controller.controller.engine performBlock:^{
									auto ship = character->getShip();
									NSMutableArray* values = [NSMutableArray new];
									NSMutableArray* texts = [NSMutableArray new];

									if (i < 4) {
										auto resistances = ship->getResistances();
										auto hp = ship->getHitPoints();
										
										for (int j = 0; j < 4; j++) {
											[values addObject:@(resistances.layers[i].resistances[j])];
											[texts addObject:[NSString stringWithFormat:@"%.1f%%", resistances.layers[i].resistances[j] * 100]];
										}
										[values addObject:@(hp.layers[i])];
										[texts addObject:[NSString shortStringWithFloat:hp.layers[4] unit:nil]];
									}
									else {
										auto damagePattern = ship->getDamagePattern();
										for (int j = 0; j < 4; j++) {
											[values addObject:@(damagePattern.damageTypes[j])];
											[texts addObject:[NSString stringWithFormat:@"%.1f%%", damagePattern.damageTypes[j] * 100]];
										}
										[values addObject:@(0)];
										[texts addObject:@""];
									}

									NSDictionary* data =
									@{@"values": values,
									  @"texts": texts,
									  @"categoryImage": [UIImage imageNamed:images[i]]};
									dispatch_async(dispatch_get_main_queue(), ^{
										completionBlock(data);
									});
								}];
							}
							else
								completionBlock(nil);
						};
						[rows addObject:row];
					}
					
					row = [NCFittingShipStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingEHPCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCFittingEHPCell* cell = (NCFittingEHPCell*) tableViewCell;
						cell.ehpLabel.text = data[@"ehp"];
					};
					row.loadingBlock = ^(NCFittingShipStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						auto character = controller.controller.fit.pilot;
						if (character) {
							[controller.controller.engine performBlock:^{
								auto ship = character->getShip();
								auto effectiveHitPoints = ship->getEffectiveHitPoints();
								float ehp = effectiveHitPoints.shield + effectiveHitPoints.armor + effectiveHitPoints.hull;
								
								NSDictionary* data =
								@{@"ehp": [NSString stringWithFormat:NSLocalizedString(@"EHP: %@", nil), [NSString shortStringWithFloat:ehp unit:nil]]};
								dispatch_async(dispatch_get_main_queue(), ^{
									completionBlock(data);
								});
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					section.rows = rows;
				}
				[sections addObject:section];
				
				section = [NCFittingShipStatsViewControllerSection new];
				section.title = NSLocalizedString(@"Capacitor", nil);
				{
					NSMutableArray* rows = [NSMutableArray new];
					row = [NCFittingShipStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingShipCapacitorCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCFittingShipCapacitorCell* cell = (NCFittingShipCapacitorCell*) tableViewCell;
						cell.capacitorCapacityLabel.text = data[@"capacitorCapacity"];
						cell.capacitorStateLabel.text = data[@"capacitorState"];
						cell.capacitorRechargeTimeLabel.text = data[@"capacitorRechargeTime"];
						cell.capacitorDeltaLabel.text = data[@"capacitorDelta"];
					};
					row.loadingBlock = ^(NCFittingShipStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						auto character = controller.controller.fit.pilot;
						if (character) {
							[controller.controller.engine performBlock:^{
								auto ship = character->getShip();
								float capCapacity = ship->getCapCapacity();
								bool capStable = ship->isCapStable();
								float capState = capStable ? ship->getCapStableLevel() * 100.0 : ship->getCapLastsTime();
								float capacitorRechargeTime = ship->getAttribute(eufe::RECHARGE_RATE_ATTRIBUTE_ID)->getValue() / 1000.0;
								float delta = ship->getCapRecharge() - ship->getCapUsed();

								NSDictionary* data =
								@{@"capacitorCapacity": [NSString stringWithFormat:NSLocalizedString(@"Total: %@", nil), [NSString shortStringWithFloat:capCapacity unit:@"GJ"]],
								  @"capacitorState": capStable ? [NSString stringWithFormat:NSLocalizedString(@"Stable: %.1f%%", nil), capState] : [NSString stringWithFormat:NSLocalizedString(@"Lasts: %@", nil), [NSString stringWithTimeLeft:capState]],
								  @"capacitorRechargeTime": [NSString stringWithFormat:NSLocalizedString(@"Recharge Time: %@", nil), [NSString stringWithTimeLeft:capacitorRechargeTime]],
								  @"capacitorDelta": [NSString stringWithFormat:NSLocalizedString(@"Delta: %@%@", nil), delta >= 0.0 ? @"+" : @"", [NSString shortStringWithFloat:delta unit:@"GJ/s"]]};
								dispatch_async(dispatch_get_main_queue(), ^{
									completionBlock(data);
								});
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					section.rows = rows;
				}
				[sections addObject:section];

				section = [NCFittingShipStatsViewControllerSection new];
				section.title = NSLocalizedString(@"Recharge Rates (HP/s) / (EHP/s )", nil);
				{
					NSMutableArray* rows = [NSMutableArray new];
					row = [NCFittingShipStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingShipTankHeaderCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
					};
					row.loadingBlock = ^(NCFittingShipStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						completionBlock(nil);
					};
					[rows addObject:row];
					
					row = [NCFittingShipStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingShipTankCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCFittingShipTankCell* cell = (NCFittingShipTankCell*) tableViewCell;
						cell.categoryLabel.text = NSLocalizedString(@"Reinforced", nil);
						cell.shieldRecharge.text = data[@"shieldRecharge"];
						cell.shieldBoost.text = data[@"shieldBoost"];
						cell.armorRepair.text = data[@"armorRepair"];
						cell.hullRepair.text = data[@"hullRepair"];
					};
					row.loadingBlock = ^(NCFittingShipStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						auto character = controller.controller.fit.pilot;
						if (character) {
							[controller.controller.engine performBlock:^{
								auto ship = character->getShip();
								auto rtank = ship->getTank();
								auto ertank = ship->getEffectiveTank();
								
								NSDictionary* data =
								@{@"shieldRecharge": [NSString stringWithFormat:@"%.1f\n%.1f", rtank.passiveShield, ertank.passiveShield],
								  @"shieldBoost": [NSString stringWithFormat:@"%.1f\n%.1f", rtank.shieldRepair, ertank.shieldRepair],
								  @"armorRepair": [NSString stringWithFormat:@"%.1f\n%.1f", rtank.armorRepair, ertank.armorRepair],
								  @"hullRepair": [NSString stringWithFormat:@"%.1f\n%.1f", rtank.hullRepair, ertank.hullRepair]};
								dispatch_async(dispatch_get_main_queue(), ^{
									completionBlock(data);
								});
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					
					row = [NCFittingShipStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingShipTankCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCFittingShipTankCell* cell = (NCFittingShipTankCell*) tableViewCell;
						cell.categoryLabel.text = NSLocalizedString(@"Sustained", nil);
						cell.shieldRecharge.text = data[@"shieldRecharge"];
						cell.shieldBoost.text = data[@"shieldBoost"];
						cell.armorRepair.text = data[@"armorRepair"];
						cell.hullRepair.text = data[@"hullRepair"];
					};
					row.loadingBlock = ^(NCFittingShipStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						auto character = controller.controller.fit.pilot;
						if (character) {
							[controller.controller.engine performBlock:^{
								auto ship = character->getShip();
								auto stank = ship->getSustainableTank();
								auto estank = ship->getEffectiveSustainableTank();
								
								NSDictionary* data =
								@{@"shieldRecharge": [NSString stringWithFormat:@"%.1f\n%.1f", stank.passiveShield, estank.passiveShield],
								  @"shieldBoost": [NSString stringWithFormat:@"%.1f\n%.1f", stank.shieldRepair, estank.shieldRepair],
								  @"armorRepair": [NSString stringWithFormat:@"%.1f\n%.1f", stank.armorRepair, estank.armorRepair],
								  @"hullRepair": [NSString stringWithFormat:@"%.1f\n%.1f", stank.hullRepair, estank.hullRepair]};
								dispatch_async(dispatch_get_main_queue(), ^{
									completionBlock(data);
								});
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					section.rows = rows;
				}
				[sections addObject:section];

				section = [NCFittingShipStatsViewControllerSection new];
				section.title = NSLocalizedString(@"Firepower", nil);
				{
					NSMutableArray* rows = [NSMutableArray new];
					row = [NCFittingShipStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingShipFirepowerCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCFittingShipFirepowerCell* cell = (NCFittingShipFirepowerCell*) tableViewCell;
						cell.weaponDPSLabel.text = data[@"weaponDPS"];
						cell.droneDPSLabel.text = data[@"droneDPS"];
						cell.volleyDamageLabel.text = data[@"volleyDamage"];
						cell.dpsLabel.text = data[@"dps"];
					};
					row.loadingBlock = ^(NCFittingShipStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						auto character = controller.controller.fit.pilot;
						if (character) {
							[controller.controller.engine performBlock:^{
								auto ship = character->getShip();
								float weaponDPS = ship->getWeaponDps();
								float droneDPS = ship->getDroneDps();
								float volleyDamage = ship->getWeaponVolley() + ship->getDroneVolley();
								float dps = weaponDPS + droneDPS;
								
								NSDictionary* data =
								@{@"weaponDPS": [NSString stringWithFormat:NSLocalizedString(@"%@ DPS", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(weaponDPS)]],
								  @"droneDPS": [NSString stringWithFormat:NSLocalizedString(@"%@ DPS", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(droneDPS)]],
								  @"volleyDamage": [NSNumberFormatter neocomLocalizedStringFromNumber:@(volleyDamage)],
								  @"dps": [NSString stringWithFormat:@"%@", [NSNumberFormatter neocomLocalizedStringFromNumber:@(dps)]]};
								dispatch_async(dispatch_get_main_queue(), ^{
									completionBlock(data);
								});
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					section.rows = rows;
				}
				[sections addObject:section];

				section = [NCFittingShipStatsViewControllerSection new];
				section.title = NSLocalizedString(@"Misc", nil);
				{
					NSMutableArray* rows = [NSMutableArray new];
					row = [NCFittingShipStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingShipMiscCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCFittingShipMiscCell* cell = (NCFittingShipMiscCell*) tableViewCell;
						cell.targetsLabel.text = data[@"targets"];
						cell.targetRangeLabel.text = data[@"targetRange"];
						cell.scanResLabel.text = data[@"scanRes"];
						cell.sensorStrLabel.text = data[@"sensorStr"];
						cell.speedLabel.text = data[@"speed"];
						cell.alignTimeLabel.text = data[@"alignTime"];
						cell.signatureLabel.text = data[@"signature"];
						cell.cargoLabel.text = data[@"cargo"];
						cell.sensorImageView.image = data[@"sensorImage"];
						cell.droneRangeLabel.text = data[@"droneRange"];
						cell.warpSpeedLabel.text = data[@"warpSpeed"];
						cell.massLabel.text = data[@"mass"];
					};
					row.loadingBlock = ^(NCFittingShipStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						auto character = controller.controller.fit.pilot;
						if (character) {
							[controller.controller.engine performBlock:^{
								auto ship = character->getShip();
								int targets = ship->getMaxTargets();
								float targetRange = ship->getMaxTargetRange() / 1000.0;
								float scanRes = ship->getScanResolution();
								float sensorStr = ship->getScanStrength();
								float speed = ship->getVelocity();
								float alignTime = ship->getAlignTime();
								float signature =ship->getSignatureRadius();
								float cargo =ship->getAttribute(eufe::CAPACITY_ATTRIBUTE_ID)->getValue();
								float mass = ship->getMass();
								float droneRange = character->getAttribute(eufe::DRONE_CONTROL_DISTANCE_ATTRIBUTE_ID)->getValue() / 1000;
								float warpSpeed = ship->getWarpSpeed();
								UIImage* sensorImage;
								switch(ship->getScanType()) {
									case eufe::Ship::SCAN_TYPE_GRAVIMETRIC:
										sensorImage = [UIImage imageNamed:@"Gravimetric.png"];
										break;
									case eufe::Ship::SCAN_TYPE_LADAR:
										sensorImage = [UIImage imageNamed:@"Ladar.png"];
										break;
									case eufe::Ship::SCAN_TYPE_MAGNETOMETRIC:
										sensorImage = [UIImage imageNamed:@"Magnetometric.png"];
										break;
									case eufe::Ship::SCAN_TYPE_RADAR:
										sensorImage = [UIImage imageNamed:@"Radar.png"];
										break;
									default:
										sensorImage = [UIImage imageNamed:@"Multispectral.png"];
										break;
								}

								NSDictionary* data =
								@{@"targets": [NSString stringWithFormat:@"%d", targets],
								  @"targetRange": [NSString stringWithFormat:@"%.1f km", targetRange],
								  @"scanRes": [NSString stringWithFormat:@"%.0f mm", scanRes],
								  @"sensorStr": [NSString stringWithFormat:@"%.0f", sensorStr],
								  @"speed": [NSString stringWithFormat:@"%.0f m/s", speed],
								  @"alignTime": [NSString stringWithFormat:@"%.1f s", alignTime],
								  @"signature": [NSString stringWithFormat:@"%.0f", signature],
								  @"cargo": [NSString shortStringWithFloat:cargo unit:@"m3"],
								  @"sensorImage": sensorImage,
								  @"droneRange": [NSString stringWithFormat:@"%.1f km", droneRange],
								  @"warpSpeed": [NSString stringWithFormat:@"%.2f AU/s", warpSpeed],
								  @"mass": [NSString stringWithFormat:@"%@ kg", [NSNumberFormatter neocomLocalizedStringFromNumber:@(mass)]]};
								dispatch_async(dispatch_get_main_queue(), ^{
									completionBlock(data);
								});
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					section.rows = rows;
				}
				[sections addObject:section];
				
				section = [NCFittingShipStatsViewControllerSection new];
				section.title = NSLocalizedString(@"Price", nil);
				{
					NSMutableArray* rows = [NSMutableArray new];
					row = [NCFittingShipStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingShipPriceCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCFittingShipPriceCell* cell = (NCFittingShipPriceCell*) tableViewCell;
						cell.shipPriceLabel.text = data[@"shipPrice"];
						cell.fittingsPriceLabel.text = data[@"fittingsPrice"];
						cell.dronesPriceLabel.text = data[@"dronesPrice"];
						cell.totalPriceLabel.text = data[@"totalPrice"];
					};
					row.loadingBlock = ^(NCFittingShipStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						auto character = controller.controller.fit.pilot;
						if (character) {
							[controller.controller.engine performBlock:^{
								auto ship = character->getShip();
								NSCountedSet* types = [NSCountedSet set];
								NSMutableSet* drones = [NSMutableSet set];
								__block int32_t shipTypeID;
								shipTypeID = ship->getTypeID();
								
								[types addObject:@(ship->getTypeID())];
								
								for (auto i: ship->getModules())
									[types addObject:@(i->getTypeID())];
								
								for (auto i: ship->getDrones()) {
									[types addObject:@(i->getTypeID())];
									[drones addObject:@(i->getTypeID())];
								}
								[[NCPriceManager sharedManager] requestPricesWithTypes:[types allObjects] completionBlock:^(NSDictionary *prices) {
									__block float shipPrice = 0;
									__block float fittingsPrice = 0;
									__block float dronesPrice = 0;
									
									[prices enumerateKeysAndObjectsUsingBlock:^(NSNumber* key, NSNumber* obj, BOOL *stop) {
										int32_t typeID = [key intValue];
										if (typeID == shipTypeID)
											shipPrice = [obj doubleValue];
										else if ([drones containsObject:@(typeID)])
											dronesPrice += [obj doubleValue] * [types countForObject:key];
										else
											fittingsPrice += [obj doubleValue] * [types countForObject:key];
									}];
									float totalPrice = shipPrice + fittingsPrice + dronesPrice;
									NSDictionary* data =
									@{@"shipPrice": [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSString shortStringWithFloat:shipPrice unit:nil]],
									  @"fittingsPrice": [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSString shortStringWithFloat:fittingsPrice unit:nil]],
									  @"dronesPrice": [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSString shortStringWithFloat:dronesPrice unit:nil]],
									  @"totalPrice": [NSString stringWithFormat:NSLocalizedString(@"Total: %@ ISK", nil), [NSString shortStringWithFloat:totalPrice unit:nil]]};
									dispatch_async(dispatch_get_main_queue(), ^{
										completionBlock(data);
									});

								}];
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					section.rows = rows;
				}
				[sections addObject:section];
			}];
		}
	}
	else
		completionBlock();
	
	NCFittingShipStatsViewControllerShipStats* stats = [NCFittingShipStatsViewControllerShipStats new];
	if (self.tableView.dataSource == self)
		[self.tableView reloadData];
	
	[self.controller.engine performBlockAndWait:^{
		auto character = self.controller.fit.pilot;
		if (!character)
			return;
		auto ship = character->getShip();
		
		
		
		
		
		
		
		
		
		
		stats.damagePattern = self.controller.damagePattern;
	}];
	self.shipStats = stats;
	if (self.tableView.dataSource == self)
		[self.tableView reloadData];
	[self updatePrice];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	// Return the number of sections.
	return 7;
	//return self.view.window ? 7 : 0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch(section) {
		case 0:
			return 2;
		case 1:
			return 6;
		case 2:
			return 1;
		case 3:
			return 3;
		case 4:
			return 1;
		case 5:
			return 1;
		case 6:
			return 1;
	}
	return 0;
}


- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0)
	else if (section == 1)
	else if (section == 2)
	else if (section == 3)
	else if (section == 4)
	else if (section == 5)
	else if (section == 6)
		return NSLocalizedString(@"", nil);
	else
		return nil;
}

#pragma mark - Table view delegate


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	if (title) {
		NCTableViewHeaderView* view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NCTableViewHeaderView"];
		view.textLabel.text = title;
		return view;
	}
	else
		return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	return title ? 44 : 0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 1 && indexPath.row == 4)
		[self.controller performSegueWithIdentifier:@"NCFittingDamagePatternsViewController" sender:[tableView cellForRowAtIndexPath:indexPath]];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - Private

- (void) updatePrice {
	NCFittingShipStatsViewControllerPriceStats* stats = [NCFittingShipStatsViewControllerPriceStats new];
	
	
	[[self pricesTaskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
										 title:NCTaskManagerDefaultTitle
										 block:^(NCTask *task) {

										 }
							 completionHandler:^(NCTask *task) {
								 if (![task isCancelled]) {
									 self.priceStats = stats;
									 [self.tableView reloadData];
								 }
							 }];
}

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
	}
	else if (indexPath.section == 1) {
	}
	else if (indexPath.section == 2)
	else if (indexPath.section == 3) {
	else if (indexPath.section == 4)
	else if (indexPath.section == 5)
		return @"";
	else if (indexPath.section == 6)
		return @"";
	else
		return nil;
}

// Customize the appearance of table view cells.
- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell *)tableViewCell forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		if (indexPath.row == 0) {
			if (self.shipStats) {
			}
		}
		else {
			if (self.shipStats) {
			}
		}
	}
	else if (indexPath.section == 1) {
	}
	else if (indexPath.section == 2) {
	}
	else if (indexPath.section == 3) {
	}
	else if (indexPath.section == 4) {
	}
	else if (indexPath.section == 5) {
	}
	else if (indexPath.section == 6) {
	}
}

@end
