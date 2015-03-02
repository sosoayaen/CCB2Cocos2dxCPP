/**
* Generate by GenerateCppCodeFromCCBFile.lua
* All rights received
* Author: Jason Tou
* Date: $DATE
*/

#ifndef __$CLASSNAME__H__
#define __$CLASSNAME__H__

#include "cocos2d.h"
#include "cocos-ext.h"
#include "ui/CocosGUI.h"
#include "editor-support/cocosbuilder/CocosBuilder.h"

$includeHeader

class $classname:
	$prefixClass$inheritclass,$inheritByTableViewClass
	public cocosbuilder::CCBMemberVariableAssigner
{
public:
	// Constructor
	$classname();
	~$classname();

	CREATE_FUNC($classname);

	virtual bool onAssignCCBMemberVariable( cocos2d::Ref* pTarget, const char* pMemberVariableName, cocos2d::Node* pNode ) override;

$publicVirtualFunctionsDeclare
private:
	// Attributes for CCB
$bindMemberVariableDeclare

private:
	// Init Menu
	void initMenuControl();

$privateVirtualFunctionsDeclare

protected:
$protectedVirtualFunctionsDeclare

public:
	// Virtual Functions
	virtual bool init() override;
	virtual void onEnter() override;
	virtual void onExit() override;
$inheritByTableViewVirtualFunctionDeclare
	
public:
	// Funcitons
};

#endif // __$CLASSNAME__H__
