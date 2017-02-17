//
//  NCLoadout.swift
//  Neocom
//
//  Created by Artem Shimanski on 11.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCFittingLoadoutItem: NSObject, NSCoding {
	let typeID: Int
	let count: Int
	let identifier: String
	
	required init?(coder aDecoder: NSCoder) {
		typeID = aDecoder.decodeInteger(forKey: "typeID")
		count = aDecoder.decodeObject(forKey: "count") as? Int ?? 1
		identifier = (aDecoder.decodeObject(forKey: "identifier") as? String) ?? UUID().uuidString
		super.init()
	}
	
	func encode(with aCoder: NSCoder) {
		aCoder.encode(typeID, forKey: "typeID")
		if count != 1 {
			aCoder.encode(count, forKey: "count")
		}
		aCoder.encode(identifier, forKey: "identifier")
	}
	
	public static func ==(lhs: NCFittingLoadoutItem, rhs: NCFittingLoadoutItem) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
	
	override var hashValue: Int {
		return [typeID, count].hashValue
	}
}

class NCFittingLoadoutModule: NCFittingLoadoutItem {
	let state: NCFittingModuleState
	let charge: NCFittingLoadoutItem?
	
	required init?(coder aDecoder: NSCoder) {
		state = NCFittingModuleState(rawValue: aDecoder.decodeInteger(forKey: "state")) ?? .unknown
		charge = aDecoder.decodeObject(forKey: "charge") as? NCFittingLoadoutItem
		super.init(coder: aDecoder)
	}
	
	override func encode(with aCoder: NSCoder) {
		super.encode(with: aCoder)
		aCoder.encode(state.rawValue, forKey: "state")
		aCoder.encode(charge, forKey: "charge")
	}

	override var hashValue: Int {
		return [typeID, count, state.rawValue, charge?.typeID ?? 0].hashValue
	}
}

class NCFittingLoadoutDrone: NCFittingLoadoutItem {
	let isActive: Bool
	
	required init?(coder aDecoder: NSCoder) {
		isActive = aDecoder.decodeObject(forKey: "isActive") as? Bool ?? true
		super.init(coder: aDecoder)
	}
	
	override func encode(with aCoder: NSCoder) {
		super.encode(with: aCoder)
		if !isActive {
			aCoder.encode(isActive, forKey: "isActive")
		}
	}

	override var hashValue: Int {
		return [typeID, count, isActive ? 1 : 0].hashValue
	}
}


public class NCFittingLoadout: NSObject, NSCoding {
	var modules: [NCFittingModuleSlot: [NCFittingLoadoutModule]]?
	var drones: [NCFittingLoadoutDrone]?
	var cargo: [NCFittingLoadoutItem]?
	var implants: [NCFittingLoadoutItem]?
	var boosters: [NCFittingLoadoutItem]?
	
	override init() {
		super.init()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		modules = [NCFittingModuleSlot: [NCFittingLoadoutModule]]()
		for (key, value) in aDecoder.decodeObject(forKey: "modules") as? [Int: [NCFittingLoadoutModule]] ?? [:] {
			guard let key = NCFittingModuleSlot(rawValue: key) else {continue}
			modules?[key] = value
		}
		
		drones = aDecoder.decodeObject(forKey: "drones") as? [NCFittingLoadoutDrone]
		cargo = aDecoder.decodeObject(forKey: "cargo") as? [NCFittingLoadoutItem]
		implants = aDecoder.decodeObject(forKey: "implants") as? [NCFittingLoadoutItem]
		boosters = aDecoder.decodeObject(forKey: "boosters") as? [NCFittingLoadoutItem]
		super.init()
	}
	
	public func encode(with aCoder: NSCoder) {
		var dic = [Int: [NCFittingLoadoutModule]]()
		for (key, value) in modules ?? [:] {
			dic[key.rawValue] = value
		}
		
		aCoder.encode(dic, forKey:"modules")

		if drones?.count ?? 0 > 0 {
			aCoder.encode(drones, forKey: "drones")
		}
		if cargo?.count ?? 0 > 0 {
			aCoder.encode(cargo, forKey: "cargo")
		}
		if implants?.count ?? 0 > 0 {
			aCoder.encode(implants, forKey: "implants")
		}
		if boosters?.count ?? 0 > 0 {
			aCoder.encode(boosters, forKey: "boosters")
		}
	}
}


extension NCFittingCharacter {
	var loadout: NCFittingLoadout {
		get {
			return NCFittingLoadout()
		}
		set {
			let ship = self.ship!
			for implant in loadout.implants ?? [] {
				addImplant(typeID: implant.typeID)
			}
			for booster in loadout.boosters ?? [] {
				addBooster(typeID: booster.typeID)
			}
			for drone in loadout.drones ?? [] {
				for _ in 0..<drone.count {
					guard let item = ship.addDrone(typeID: drone.typeID) else {break}
					item.engine?.assign(identifier: drone.identifier, for: item)
				}
			}
			for (_, modules) in loadout.modules?.sorted(by: { $0.key.rawValue > $1.key.rawValue }) ?? [] {
				for module in modules {
					for _ in 0..<module.count {
						guard let m = ship.addModule(typeID: module.typeID) else {break}
						m.engine?.assign(identifier: module.identifier, for: m)
						m.preferredState = module.state
						if let charge = module.charge {
							m.charge = NCFittingCharge(typeID: charge.typeID)
						}
					}
				}
			}
		}
	}
}

extension NCFittingModuleSlot {
	var image: UIImage? {
		switch self {
		case .hi:
			return #imageLiteral(resourceName: "slotHigh")
		case .med:
			return #imageLiteral(resourceName: "slotMed")
		case .low:
			return #imageLiteral(resourceName: "slotLow")
		case .rig:
			return #imageLiteral(resourceName: "slotRig")
		case .subsystem:
			return #imageLiteral(resourceName: "slotSubsystem")
		case .service:
			return #imageLiteral(resourceName: "slotService")
		case .mode:
			return #imageLiteral(resourceName: "slotSubsystem")
		default:
			return nil
		}
	}
	
	var title: String? {
		switch self {
		case .hi:
			return NSLocalizedString("Hi Slot", comment: "")
		case .med:
			return NSLocalizedString("Med Slot", comment: "")
		case .low:
			return NSLocalizedString("Low Slot", comment: "")
		case .rig:
			return NSLocalizedString("Rig Slot", comment: "")
		case .subsystem:
			return NSLocalizedString("Subsystem Slot", comment: "")
		case .service:
			return NSLocalizedString("Services", comment: "")
		case .mode:
			return NSLocalizedString("Tactical Mode", comment: "")
		default:
			return nil
		}
	}
}

extension NCFittingModuleState {
	var image: UIImage? {
		switch self {
		case .offline:
			return #imageLiteral(resourceName: "offline")
		case .online:
			return #imageLiteral(resourceName: "online")
		case .active:
			return #imageLiteral(resourceName: "active")
		case .overloaded:
			return #imageLiteral(resourceName: "overheated")
		default:
			return nil
		}
	}
	
	var title: String? {
		switch self {
		case .offline:
			return NSLocalizedString("Offline", comment: "")
		case .online:
			return NSLocalizedString("Online", comment: "")
		case .active:
			return NSLocalizedString("Active", comment: "")
		case .overloaded:
			return NSLocalizedString("Overheated", comment: "")
		default:
			return nil
		}
	}
}

extension NCFittingScanType {
	var image: UIImage? {
		switch self {
		case .gravimetric:
			return #imageLiteral(resourceName: "gravimetric")
		case .magnetometric:
			return #imageLiteral(resourceName: "magnetometric")
		case .ladar:
			return #imageLiteral(resourceName: "ladar")
		case .radar:
			return #imageLiteral(resourceName: "radar")
		case .multispectral:
			return #imageLiteral(resourceName: "multispectral")
		}
	}
	
	var title: String? {
		switch self {
		case .gravimetric:
			return NSLocalizedString("Gravimetric", comment: "")
		case .magnetometric:
			return NSLocalizedString("Magnetometric", comment: "")
		case .ladar:
			return NSLocalizedString("Ladar", comment: "")
		case .radar:
			return NSLocalizedString("Radar", comment: "")
		case .multispectral:
			return NSLocalizedString("Multispectral", comment: "")
		}
	}
}

extension NCFittingDamage {
	static let omni = NCFittingDamage(em: 0.25, thermal: 0.25, kinetic: 0.25, explosive: 0.25)
	var total: Double {
		return em + kinetic + thermal + explosive
	}
	static func + (lhs: NCFittingDamage, rhs: NCFittingDamage) -> NCFittingDamage {
		return NCFittingDamage(em: lhs.em + rhs.em, thermal: lhs.thermal + rhs.thermal, kinetic: lhs.kinetic + rhs.kinetic, explosive: lhs.explosive + rhs.explosive)
	}
}

extension NCFittingFighterSquadron {
	var title: String? {
		switch self {
		case .heavy:
			return NSLocalizedString("Heavy", comment: "")
		case .light:
			return NSLocalizedString("Light", comment: "")
		case .support:
			return NSLocalizedString("Support", comment: "")
		case .none:
			return NSLocalizedString("Drone", comment: "")
		}
	}
}

extension NCFittingAccuracy {
	var color: UIColor {
		switch self {
		case .none:
			return .white
		case .low:
			return .red
		case .average:
			return .yellow
		case .good:
			return .green
		}
	}
}

extension NCFittingSkills{
	func set(levels: [Int: Int]) {
		__setLevels(levels as [NSNumber: NSNumber])
	}
}

extension NCFittingDamage: Hashable {
	public var hashValue: Int {
		return [em, kinetic, thermal, explosive].hashValue
	}
	
	public static func == (lhs: NCFittingDamage, rhs: NCFittingDamage) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
}

extension NCFittingCharacter {
	
	@nonobjc class func url(account: NCAccount) -> URL? {
		guard let uuid = account.uuid else {return nil}
		var components = URLComponents()
		components.scheme = NCURLScheme
		components.host = "character"
		components.queryItems = [URLQueryItem(name: "accountUUID", value: uuid)]
		return components.url
	}

	@nonobjc class func url(level: Int) -> URL? {
		var components = URLComponents()
		components.scheme = NCURLScheme
		components.host = "character"
		components.queryItems = [URLQueryItem(name: "level", value: String(level))]
		return components.url
	}
	
	var url: URL? {
		return URL(string: characterName)
	}
	
	@nonobjc func setSkills(from url: URL, completionHandler: ((Bool) -> Void)?) {
		guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
			let queryItems = components.queryItems,
			components.scheme == NCURLScheme,
			components.host == "character" else {
			completionHandler?(false)
			return
		}

		if let item = queryItems.first(where: {$0.name == "accountUUID"}), let uuid = item.value {
			if let account = NCStorage.sharedStorage?.accounts[uuid] {
				setSkills(from: account, completionHandler: completionHandler)
			}
			else {
				completionHandler?(false)
			}
		}
		else if let item = queryItems.first(where: {$0.name == "level"}), let level = Int(item.value ?? ""){
			setSkills(level: level, completionHandler: completionHandler)
		}
		else {
			completionHandler?(false)
		}
	}

	
	@nonobjc func setSkills(from account: NCAccount, completionHandler: ((Bool) -> Void)?) {
		guard let engine = engine else {
			completionHandler?(false)
			return
		}
		
		let url = NCFittingCharacter.url(account: account)
		NCDataManager(account: account, cachePolicy: .returnCacheDataElseLoad).skills { result in
			switch result {
			case let .success(value, _):
				engine.perform {
					var levels = [Int: Int]()
					for skill in value.skills {
						levels[skill.skillID] = skill.currentSkillLevel
					}
					
					self.skills.set(levels: levels)
					self.characterName = url?.absoluteString ?? ""
					DispatchQueue.main.async {
						completionHandler?(true)
					}
				}

			default:
				break
			}
		}
	}
	
	@nonobjc func setSkills(level: Int, completionHandler: ((Bool) -> Void)? = nil) {
		guard let engine = engine else {
			completionHandler?(false)
			return
		}
		let url = NCFittingCharacter.url(level: level)
		engine.perform {
			self.skills.setAllSkillsLevel(level)
			self.characterName = url?.absoluteString ?? ""
			DispatchQueue.main.async {
				completionHandler?(true)
			}
		}
	}
}