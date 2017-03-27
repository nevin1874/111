//
//  NCFittingAmmoDamageChartViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 26.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit


class NCFittingAmmoDamageChartViewController: UITableViewController, TreeControllerDelegate {
	@IBOutlet var treeController: TreeController!
	
	var category: NCDBDgmppItemCategory?
	var modules: [NCFittingModule]?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self

		guard let category = category else {return}
		guard let group: NCDBDgmppItemGroup = NCDatabase.sharedDatabase?.viewContext.fetch("DgmppItemGroup", where: "category == %@ AND parentGroup == NULL", category) else {return}
		title = group.groupName
		
		guard let ammo = NCAmmoSection(category: category) else {return}
		guard let modules = modules else {return}
		guard let module = modules.first else {return}
		
		let root = TreeNode()
		root.children = [NCFittingAmmoDamageChartRow(module: module, count: modules.count), ammo]
		
		treeController.content = root

	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		treeController.deselectCell(for: node, animated: true)
		guard let node = node as? NCAmmoNode else {return}
		guard let damageChartRow = treeController.content?.children.first as? NCFittingAmmoDamageChartRow else {return}
		let typeID = Int(node.object.typeID)
		if let i = damageChartRow.charges.index(of: typeID) {
			damageChartRow.charges.remove(at: i)
		}
		else {
			damageChartRow.charges.append(typeID)
		}
		
		guard let cell = treeController.cell(for: damageChartRow) as? NCFittingAmmoDamageChartTableViewCell else {return}

		cell.damageChartView.charges = damageChartRow.charges
	}
	
	//MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "NCDatabaseTypeInfoViewController"?:
			guard let controller = segue.destination as? NCDatabaseTypeInfoViewController,
				let cell = sender as? NCTableViewCell,
				let type = cell.object as? NCDBInvType else {
					return
			}
			controller.type = type
		default:
			break
		}
	}
}