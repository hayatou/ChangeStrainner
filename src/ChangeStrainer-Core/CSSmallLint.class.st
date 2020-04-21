Class {
	#name : #CSSmallLint,
	#superclass : #Object,
	#instVars : [
		'environment',
		'rules',
		'checker'
	],
	#category : #'ChangeStrainer-Core'
}

{ #category : #'as yet unclassified' }
CSSmallLint >> asSelectorEnvironment:rbResult [
	^ (rbResult isKindOf: RBMultiEnvironment)
		ifTrue: [ rbResult asSelectorEnvironment ]
		ifFalse: [ rbResult ]
]

{ #category : #accessing }
CSSmallLint >> checker [
	^ checker
]

{ #category : #accessing }
CSSmallLint >> checker: anObject [
	checker := anObject
]

{ #category : #accessing }
CSSmallLint >> environment [
	^ environment
]

{ #category : #accessing }
CSSmallLint >> environment: anObject [
	environment := anObject
]

{ #category : #initialize }
CSSmallLint >> initialize [
	super initialize.
	environment := RPackage .
	rules := RBCompositeLintRule.
	checker := RBSmalllintChecker new
]

{ #category : #accessing }
CSSmallLint >> result [

	^ rules leaves collect: [ :l | l result ]
]

{ #category : #accessing }
CSSmallLint >> rules [
	^ rules
]

{ #category : #accessing }
CSSmallLint >> rules:aCollection [
	rules := aCollection
]

{ #category : #running }
CSSmallLint >> warningsFor: aPackageName [
	|env  check |
	env := environment  organizer packages select: [:e |  e packageName =  aPackageName  ].
	check := self checker.
	self rules: rules allGoodRules.
	self rules resetResult. 
	env do: [:paI |  
		check rule: rules.	
		check environment:  (RBPackageEnvironment new packages: {paI}) . 
		paI classes do: [ :class |	
			 (class isTrait ) ifFalse: [ 
				 check  checkClass: class.
				 check  checkMethodsForClass: class] ] ]. 
]
