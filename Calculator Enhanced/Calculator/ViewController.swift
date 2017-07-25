//
//  ViewController.swift
//  Calculator
//
//  Created by Becky Henderson on 7/3/17.
//  Copyright © 2017 Beckasaurus Productions. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
	
	private var brain = CalculatorBrain()
	private var observer: NSObjectProtocol?
	
	@IBOutlet weak var display: UILabel!
	@IBOutlet weak var descriptionLabel: UILabel!
	
	var displayValue: Double {
		get {
			return Double(display.text!)!
		}
		set {
			display.text = String(newValue)
		}
	}
	
	var userHasStartedTyping = false
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		setToInitialValues()
		observer = NotificationCenter.default.addObserver(forName: brain.calculatorDidClearNotificationName,
		                                                  object: nil,
		                                                  queue: OperationQueue.main,
		                                                  using: { (_) in
															self.setToInitialValues()
		})
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		if let observer = observer {
			NotificationCenter.default.removeObserver(observer)
		}
	}
	
	func setToInitialValues() {
		display.text = " "
		userHasStartedTyping = false
		descriptionLabel.text = " "
	}
	
	func updateDescription() {
		if var description = brain.description {
			if brain.resultIsPending {
				description += " ... "
			} else if brain.result != nil {
				description += " = "
			}
			
			descriptionLabel.text = description
		}
	}
	
	@IBAction func touchedButton(_ sender: UIButton) {
		let digit = sender.currentTitle!
		
		if let displayText = display.text,
			digit == "." {
			if displayText.contains(".") {
				return
			}
		}
		
		if userHasStartedTyping {
			display.text = display.text! + digit
		} else {
			display.text = digit
			userHasStartedTyping = true
		}
	}
	
	@IBAction func mathematicalOperation(_ sender: UIButton) {
		if userHasStartedTyping {
			brain.setOperand(displayValue)
			userHasStartedTyping = false
		}
		
		if let mathematicalSymbol = sender.currentTitle {
			brain.performOperation(mathematicalSymbol)
		}
		
		if let result = brain.result {
			displayValue = result
		}
		
		updateDescription()
	}
}

