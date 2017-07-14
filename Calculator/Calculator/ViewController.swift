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
	
	var displayValue: Double {
		get {
			return Double(display.text!)!
		}
		set {
			display.text = String(newValue)
		}
	}
	
	var userHasStartedTyping = false
	var userHasEnteredDecimal = false
	
	override func viewDidLoad() {
		super .viewDidLoad()
		observer = NotificationCenter.default.addObserver(forName: brain.calculatorDidClearNotificationName,
		                                                  object: nil,
		                                                  queue: OperationQueue.main,
		                                                  using: { (_) in
															self.displayValue = 0
		})
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		if let observer = observer {
			NotificationCenter.default.removeObserver(observer)
		}
	}
	
	@IBAction func touchedButton(_ sender: UIButton) {
		let digit = sender.currentTitle!
		
		if digit == "." {
			if userHasEnteredDecimal {
				return
			}
			
			userHasEnteredDecimal = true
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
			brain.setOperant(displayValue)
			userHasStartedTyping = false
		}
		
		if let mathematicalSymbol = sender.currentTitle {
			brain.performOperation(mathematicalSymbol)
		}
		
		if let result = brain.result {
			displayValue = result
		}
	}
}

