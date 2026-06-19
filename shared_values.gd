extends Node

var numOfObjects

class StackEl:
	var objName
	var right_ascension
	var declination
	var priority

class Stack:
	var stackBuffer = []
	var TOP
	
# global stack
var stackOfObject: Stack = Stack.new()

func _ready() -> void:
	stackOfObject.TOP = -1

func isEmpty(S: Stack) -> bool:
	return (S.TOP == -1)

func pushStack(S: Stack, El: StackEl) -> void:
	S.TOP += 1
	S.stackBuffer.append(El)
	
func popStack(S: Stack) -> StackEl:
	S.TOP -= 1
	return S.stackBuffer[S.TOP + 1]

var totalWeight = null
var path = null
