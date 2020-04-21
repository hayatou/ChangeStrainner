Class {
	#name : #CSViolation,
	#superclass : #Object,
	#instVars : [
		'alertType',
		'ruleName',
		'className'
	],
	#category : #'ChangeStrainer-Nicolas'
}

{ #category : #'as yet unclassified' }
CSViolation class >> with: anAlertAsString [
	| elements viol |
	elements := anAlertAsString subStrings: '>>'.
	viol := nil.

	elements size = 2
		ifTrue: [ viol := CSClassViolation withRule: elements first andClass: elements second ].
	elements size = 3
		ifTrue: [ viol := CSMethodViolation withRule: elements first andClass: elements second andSelector: elements third ].

	viol ifNil: [ Error signal: 'CSViolation creation, does not understand critic: ' , anAlertAsString ].
	
	viol setAlertType.
	
	^ viol
]

{ #category : #accessing }
CSViolation >> alertType [
	
	^ alertType
]

{ #category : #accessing }
CSViolation >> alertType: anObject [

	alertType  := anObject
]

{ #category : #accessing }
CSViolation >> onClassName [
	^ className
]

{ #category : #accessing }
CSViolation >> onClassName: anObject [
	
	className := anObject
]

{ #category : #printing }
CSViolation >> printString [
	^ ruleName , '>>' , className
]

{ #category : #accessing }
CSViolation >> ruleName [
	^ ruleName
]

{ #category : #accessing }
CSViolation >> ruleName: anObject [
	ruleName := anObject
]
