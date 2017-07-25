//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Becky Henderson on 7/13/17.
//  Copyright © 2017 Beckasaurus Productions. All rights reserved.
//

import Foundation

struct CalculatorBrain {
	
	let calculatorDidClearNotificationName = NSNotification.Name(rawValue: "calculatorDidClear")
	
	private var accumulator: (Double, String)? {
		didSet {
			if !resultIsPending {
				currentPrecedence = .Max
			}
		}
	}
	
	private var pbo: PendingBinaryOperation?
	
	private var currentPrecedence: Precedence = .Max
	
	@available (*, deprecated: 1.0, message: "Use evalute(using) method instead.")
	var resultIsPending: Bool {
		return evaluate(using: nil).isPending
	}
	
	@available (*, deprecated: 1.0, message: "Use evalute(using) method instead.")
	var result: Double? {
		return evaluate(using: nil).result
	}
	
	@available (*, deprecated: 1.0, message: "Use evalute(using) method instead.")
	var description: String? {
//		get {
//			if resultIsPending {
//				//calculate what the description will be
//				//use an empty string if the accumulator and the description operand are the same (i.e. 7 + on the calculator would have 7 as the description operand and the accumulator.1 value)
//				//use the value of accumulator.1 if the description operand is different (i.e. 7 + 9 √ on the calculator would have √9 as the accumulator.1 value but 7 as the description operand)
//				return pbo!.description(with: pbo!.descriptionFirstOperand != accumulator!.1 ? accumulator!.1 : "")
//			} else {
//				return accumulator?.1
//			}
//		}
		return evaluate(using: nil).description
	}
	
	private struct PendingBinaryOperation {
		let resultFunction: (Double,Double) -> Double
		let firstOperand: Double
		let descriptionFunction: (String, String) -> String
		let descriptionFirstOperand: String
		
		func perform(with secondOperand: Double) -> Double {
			return resultFunction(firstOperand, secondOperand)
		}
		
		func description(with secondOperand: String) -> String {
			return descriptionFunction(descriptionFirstOperand, secondOperand)
		}
	}
	
	private enum Precedence: Int {
		case Min = 0, Max
	}
	
	private enum Operation {
		case constant(Double)
		case unary((Double) -> Double, (String) -> String)
		case binary((Double, Double) -> Double, (String, String) -> String, Precedence)
		case equals
		case clear
	}
	
	private var operations: Dictionary<String,Operation> = [
		"π" : Operation.constant(Double.pi),
		"e" : Operation.constant(M_E),
		
		"±" : Operation.unary({-$0}, { "-(\($0))"}),
		"√" : Operation.unary(sqrt, { "√(\($0))"}),
		"x²" : Operation.unary({pow($0, 2)}, {"(\($0))²"}),
		"x³" : Operation.unary({pow($0, 3)}, {"(\($0))³"}),
		"1/x" : Operation.unary({1/$0}, {"1/\($0)"}),
		
		"+" : Operation.binary(+, {"\($0) + \($1)"}, Precedence.Min),
		"-" : Operation.binary(-, {"\($0) - \($1)"}, Precedence.Min),
		"*" : Operation.binary(*, {"\($0) * \($1)"}, Precedence.Max),
		"/" : Operation.binary(/, {"\($0) / \($1)"}, Precedence.Max),
		"%" : Operation.binary({$0.truncatingRemainder(dividingBy: $1)}, {"\($0.1) % "}, Precedence.Max),
		
		"=" : Operation.equals,
		"c" : Operation.clear
	]
	
	private mutating func performPendingBinaryOperation() {
		if pbo != nil && accumulator != nil {
			let newResult = pbo!.perform(with: accumulator!.0)
			let newDescription = pbo!.description(with: accumulator!.1)
			accumulator = (newResult, newDescription)
			pbo = nil
		}
	}
	
	private mutating func clear() {
		accumulator = nil
		pbo = nil
		
		NotificationCenter.default.post(name: calculatorDidClearNotificationName, object: nil)
	}
	
	mutating func performOperation(_ symbol: String) {
		if let operation = operations[symbol] {
			switch operation {
			
			case .constant(let value):
				accumulator = (value, symbol)
			
			case .unary(let resultFunction, let descriptionFunction):
				if let unwrappedAccumulator = accumulator {
					accumulator = (resultFunction(unwrappedAccumulator.0), descriptionFunction(unwrappedAccumulator.1))
				}
			
			case .binary(let resultFunction, let descriptionFunction, let precedence):
				performPendingBinaryOperation()
				
				if currentPrecedence.rawValue < precedence.rawValue,
					let accumulatorUnwrapped = accumulator {
					accumulator?.1 = "(\(accumulatorUnwrapped.1))"
				}
				
				currentPrecedence = precedence
				
				if let unwrappedAccumulator = accumulator {
					pbo = PendingBinaryOperation(resultFunction: resultFunction, firstOperand: unwrappedAccumulator.0, descriptionFunction: descriptionFunction, descriptionFirstOperand: unwrappedAccumulator.1)
				}
			
			case .equals:
				performPendingBinaryOperation()
			
			case .clear:
				clear()
			}
		}
	}
	
	func evaluate(using variables: Dictionary<String,Double>? = nil) -> (result: Double?, isPending: Bool, description: String) {
		//assume value of zero if operand not found in dictionary
		return (0, false, "")
	}
	
	mutating func setOperand(_ operand: Double) {
		accumulator = (operand, "\(operand)")
	}
	
	func setOperand(variable named: String) {
		
	}
}
