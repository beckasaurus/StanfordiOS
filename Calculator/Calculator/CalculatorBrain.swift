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
		case unary((Double) -> Double, (String) -> String)
		case binary((Double, Double) -> Double, (String) -> String)
		case equals
		case clear
	}
	
	private var operations: Dictionary<String,Operation> = [
		"π" : Operation.constant(Double.pi, {$0 + "π "}),
		"e" : Operation.constant(M_E, {$0 + "e "}),
		"±" : Operation.unary({-$0}, {"±" + $0}),
		"√" : Operation.unary(sqrt, {"√( \($0) )"}),
		"x²" : Operation.unary({pow($0, 2)}, {$0 + "²"}),
		"x³" : Operation.unary({pow($0, 3)}, {$0 + "³"}),
		"1/x" : Operation.unary({1/$0}, {"1/(\($0))"}),
		"+" : Operation.binary(+, {$0 + " + "}),
		"-" : Operation.binary(-, {$0 + " - "}),
		"*" : Operation.binary(*, {$0 + " * "}),
		"/" : Operation.binary(/, {$0 + " / "}),
		"%" : Operation.binary({$0.truncatingRemainder(dividingBy: $1)}, {$0 + " % "}),
		"=" : Operation.equals,
		"c" : Operation.clear
	]
	
	private mutating func performPendingBinaryOperation(descriptionFunction: (String)-> String) {
		if pbo != nil && accumulator != nil {
			accumulator = (pbo!.perform(with: accumulator!.0), accumulator!.1)
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
				if accumulator != nil {
					accumulator = (function(accumulator!.0), descriptionFunction(accumulator!.1))
				}
			case .binary(let function, let descriptionFunction):
				if resultIsPending {
					performPendingBinaryOperation(descriptionFunction: descriptionFunction)
				}
				
				if accumulator != nil {
					pbo = PendingBinaryOperation(function: function, firstOperand: accumulator!.0)
					accumulator = (accumulator!.0, descriptionFunction(accumulator!.1))
				}
			case .equals:
				performPendingBinaryOperation(descriptionFunction: {_ in accumulator!.1})
			case .clear:
				clear()
			}
		}
	}
	
	mutating func setOperand(_ operand: Double) {
		let newDescription = "\(accumulator?.1 ?? "")\(String(operand))"
		accumulator = (operand, newDescription)
	}
	
	var result: Double? {
		get {
			return resultIsPending ? nil : accumulator?.0
		}
	}
}
