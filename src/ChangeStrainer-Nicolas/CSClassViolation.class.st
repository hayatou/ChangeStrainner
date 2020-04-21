Class {
	#name : #CSClassViolation,
	#superclass : #CSViolation,
	#category : #'ChangeStrainer-Nicolas'
}

{ #category : #'instance creation' }
CSClassViolation class >> withRule: ruleName andClass: className [
	^ self new
		ruleName: ruleName ;
		onClassName: className ;
		yourself
]

{ #category : #'as yet unclassified' }
CSClassViolation >> setAlertType [
	"Look if the object responsible for the violation is present after the commit
	Assumes the revision currently loaded is precisely that one"
	(SmalltalkImage current  hasClassNamed:  self onClassName )
				ifTrue: [ self alertType: #both ] 
				ifFalse: [ self alertType: #before ]

]
