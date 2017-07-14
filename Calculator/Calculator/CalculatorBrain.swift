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
	
	private var accumulator: Double?
	
	private var pbo: PendingBinaryOperation?
	
	var resultIsPending: Bool {
		get {
			return pbo != nil
		}
	}
	
	var description: String?
	
	private struct PendingBinaryOperation {
		let function: (Double,Double) -> Double
		let firstOperand: Double
		
		func perform(with secondOperand: Double) -> Double {
			return function(firstOperand, secondOperand)
		}
	}
	
	private enum Operation {
		case constant(Double)
		case unary((Double) -> Double)
		case binary((Double, Double) -> Double)
		case equals
		case clear
	}
	
	private var operations: Dictionary<String,Operation> = [
		"π" : Operation.constant(Double.pi),
		"e" : Operation.constant(M_E),
		"±" : Operation.unary({-$0}),
		"√" : Operation.unary(sqrt),
		"x²" : Operation.unary({pow($0, 2)}),
		"x³" : Operation.unary({pow($0, 3)}),
		"1/x" : Operation.unary({1/$0}),
		"+" : Operation.binary(+),
		"-" : Operation.binary(-),
		"*" : Operation.binary(*),
		"/" : Operation.binary(/),
		"%" : Operation.binary({$0.truncatingRemainder(dividingBy: $1)}),
		"=" : Operation.equals,
		"c" : Operation.clear
	]
	
	private mutating func performPendingBinaryOperation() {
		if pbo != nil && accumulator != nil {
			accumulator = pbo!.perform(with: accumulator!)
			pbo = nil
		}
	}
	
	private mutating func clear() {
		accumulator = nil
		description = nil
		
		NotificationCenter.default.post(name: calculatorDidClearNotificationName, object: nil)
	}
	
	mutating func performOperation(_ symbol: String) {
		if let operation = operations[symbol] {
			switch operation {
			case .constant(let value):
				accumulator = value
			case .unary(let function):
				if accumulator != nil {
					accumulator = function(accumulator!)
				}
			case .binary(let function):
				if accumulator != nil {
					pbo = PendingBinaryOperation(function: function, firstOperand: accumulator!)
					accumulator = nil
				}
			case .equals:
				performPendingBinaryOperation()
			case .clear:
				clear()
			}
		}
	}
	
	mutating func setOperant(_ operand: Double) {
		accumulator = operand
	}
	
	var result: Double? {
		get {
			return accumulator
		}
	}
}
