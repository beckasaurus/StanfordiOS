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
	
	private var operationQueue = [Operation]()
	
//	private var pbo: PendingBinaryOperation?
	
//	private var currentPrecedence: Precedence = .Max
	
//	private var accumulator: (Double, String)? {
//		didSet {
//			if !resultIsPending {
//				currentPrecedence = .Max
//			}
//		}
//	}
	
	@available (*, deprecated: 1.0, message: "Use evalute(using:) instead.")
	var resultIsPending: Bool {
		return evaluate(using: nil).isPending
	}
	
	@available (*, deprecated: 1.0, message: "Use evalute(using:) instead.")
	var result: Double? {
		return evaluate(using: nil).result
	}
	
	@available (*, deprecated: 1.0, message: "Use evalute(using:) instead.")
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
		case constant(Double, String)
		case variable(String)
		case unary((Double) -> Double, (String) -> String)
		case binary((Double, Double) -> Double, (String, String) -> String, Precedence)
		case equals
		case clear
	}
	
	private var operations: Dictionary<String,Operation> = [
		"π" : Operation.constant(Double.pi, "π"),
		"e" : Operation.constant(M_E, "e"),
		
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
	
	private func performPendingBinaryOperation(_ pbo: PendingBinaryOperation, accumulator: (Double?, Bool, String)) -> (Double?, Bool, String) {
		guard let accumulatorValue = accumulator.0
			else { return accumulator }
		
		let newResult = pbo.perform(with: accumulatorValue)
		let newDescription = pbo.description(with: accumulator.2)
		return (newResult, false, newDescription)
	}
	
	private mutating func clear() {
		operationQueue = []
		NotificationCenter.default.post(name: calculatorDidClearNotificationName, object: nil)
	}
	
	//MARK: Public API
	
	mutating func performOperation(_ symbol: String) {
		if let operation = operations[symbol] {
			switch operation {
//
//			case .constant(let value):
//				operationQueue.append(Operat)
//				accumulator = (value, symbol)
//				
//			case .variable(let variable):
//				let value = variables[variable] ?? 0
//				accumulator = (value, symbol)
//			
//			case .unary(let resultFunction, let descriptionFunction):
//				if let unwrappedAccumulator = accumulator {
//					accumulator = (resultFunction(unwrappedAccumulator.0), descriptionFunction(unwrappedAccumulator.1))
//				}
//			
//			case .binary(let resultFunction, let descriptionFunction, let precedence):
//				performPendingBinaryOperation()
//				
//				if currentPrecedence.rawValue < precedence.rawValue,
//					let accumulatorUnwrapped = accumulator {
//					accumulator?.1 = "(\(accumulatorUnwrapped.1))"
//				}
//				
//				currentPrecedence = precedence
//				
//				if let unwrappedAccumulator = accumulator {
//					pbo = PendingBinaryOperation(resultFunction: resultFunction, firstOperand: unwrappedAccumulator.0, descriptionFunction: descriptionFunction, descriptionFirstOperand: unwrappedAccumulator.1)
//				}
//			
//			case .equals:
//				performPendingBinaryOperation()
//			
			case .clear:
				clear()
			default:
				operationQueue.append(operation)
			}
		}
	}
	
	func evaluate(using variables: Dictionary<String,Double>? = nil) -> (result: Double?, isPending: Bool, description: String) {
		
		var accumulator: (Double?, Bool, String) = (result: nil, isPending: false, description: "")
		var pbo: PendingBinaryOperation?
		var currentPrecedence: Precedence = .Max
		
		for operation in operationQueue {
			switch operation {
			
			case .constant(let value, let description):
				accumulator = (value, false, description)
			
			case .variable(let variableName):				
				let variableValue = variables?[variableName] ?? 0
				accumulator = (variableValue, false, variableName)
			
			case .unary(let resultFunction, let descriptionFunction):
				guard let previousResult = accumulator.0
					else {continue} // we need one operand
				
				accumulator = (resultFunction(previousResult), accumulator.1, descriptionFunction(accumulator.2))
			
			case .binary(let resultFunction, let descriptionFunction, let precedence):
				if let pbo = pbo {
					accumulator = performPendingBinaryOperation(pbo, accumulator: accumulator)
				}
				
				guard let previousResult = accumulator.0
					else { continue } // we need a previous operand
				
				if currentPrecedence.rawValue < precedence.rawValue {
					accumulator.2 = "(\(accumulator.2))"
				}
				
				currentPrecedence = precedence
				
				pbo = PendingBinaryOperation(resultFunction: resultFunction, firstOperand: previousResult, descriptionFunction: descriptionFunction, descriptionFirstOperand: accumulator.2)
				accumulator.1 = true
			
			case .equals:
				continue
			
			default:
				continue
			}
		}
		
		return accumulator
	}
	
	mutating func setOperand(_ operand: Double) {
		operationQueue.append(Operation.constant(operand, String(operand)))
	}
	
	mutating func setOperand(variable named: String) {
		operationQueue.append(Operation.variable(named))
	}
}
