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
	
	private var accumulator: (Double, String)?
	
	private var pbo: PendingBinaryOperation?
	
	var resultIsPending: Bool {
		get {
			return pbo != nil
		}
	}
	
	var description: String? {
		get {
			return accumulator?.1
		}
	}
	
	private struct PendingBinaryOperation {
		let function: (Double,Double) -> Double
		let firstOperand: Double
		
		func perform(with secondOperand: Double) -> Double {
			return function(firstOperand, secondOperand)
		}
	}
	
	private enum Operation {
		case constant(Double, (String) -> String)
		case unary((Double) -> Double, ((Double, String), Bool) -> String)
		case binary((Double, Double) -> Double, ((Double, String)) -> String)
		case equals
		case clear
	}
	
	private var operations: Dictionary<String,Operation> = [
		"π" : Operation.constant(Double.pi, {$0 + "π "}),
		"e" : Operation.constant(M_E, {$0 + "e "}),
		
		"±" : Operation.unary({-$0}, {accumulator, _ in "±" + accumulator.1 }),
		"√" : Operation.unary(sqrt, { accumulator, resultIsPending in
			if resultIsPending {
				return "\(accumulator.1) √( \(accumulator.0) )"
			} else {
				return "√( \(accumulator.1) )"
			}
		}),
		"x²" : Operation.unary({pow($0, 2)}, {"\($0.1) \($0.0)²"}),
		"x³" : Operation.unary({pow($0, 3)}, {"\($0.1) \($0.0)³"}),
		"1/x" : Operation.unary({1/$0}, {"\($0.1) 1/(\($0.0))"}),
		
		"+" : Operation.binary(+, {"\($0.1) + "}),
		"-" : Operation.binary(-, {"\($0.1) - "}),
		"*" : Operation.binary(*, {"\($0.1) * "}),
		"/" : Operation.binary(/, {"\($0.1) / "}),
		"%" : Operation.binary({$0.truncatingRemainder(dividingBy: $1)}, {"\($0.1) % "}),
		
		"=" : Operation.equals,
		"c" : Operation.clear
	]
	
	private mutating func performPendingBinaryOperation() {
		if pbo != nil && accumulator != nil {
			let newValue = pbo!.perform(with: accumulator!.0)
			accumulator = (newValue, "\(accumulator!.1)\(accumulator!.0)")
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
			case .constant(let value, let descriptionFunction):
				accumulator = (value, descriptionFunction(accumulator?.1 ?? ""))
			case .unary(let function, let descriptionFunction):
				if let unwrappedAccumulator = accumulator {
					accumulator = (function(unwrappedAccumulator.0), descriptionFunction(unwrappedAccumulator, resultIsPending))
				}
			case .binary(let function, let descriptionFunction):
				if resultIsPending {
					performPendingBinaryOperation()
				}
				
				if let unwrappedAccumulator = accumulator {
					pbo = PendingBinaryOperation(function: function, firstOperand: unwrappedAccumulator.0)
					accumulator = (unwrappedAccumulator.0, descriptionFunction(unwrappedAccumulator))
				}
			case .equals:
				performPendingBinaryOperation()
			case .clear:
				clear()
			}
		}
	}
	
	mutating func setOperand(_ operand: Double) {
		var description = "\(operand)"
		if let accumulator = accumulator,
			!resultIsPending { // for unary?
			description = "\(accumulator.1)\(operand)"
		} else if resultIsPending { //for binary?
			description = accumulator!.1
		}
		
		accumulator = (operand, description)
	}
	
	var result: Double? {
		get {
			return resultIsPending ? nil : accumulator?.0
		}
	}
}
