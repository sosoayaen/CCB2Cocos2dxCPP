/**
* Create by GenerateCppCodeFromCCBFile.lua
* All right received
* Author: Jason Tou
* Date: $DATE
*/

#ifndef __$CLASSNAME__H__
#define __$CLASSNAME__H__

#include "cocos2d.h"
#include "cocos-ext.h"
$includeHeader

class $classname:
	$prefixClass$inheritclass,$inheritByCCTableViewClass
	public cocos2d::extension::CCBSelectorResolver,
	public cocos2d::extension::CCBMemberVariableAssigner
{
public:
	// Constructor
	$classname()
	{
$memberInit
	}
	~$classname();

	CREATE_FUNC($classname);

	virtual cocos2d::SEL_CallFuncN onResolveCCBCCCallFuncSelector( cocos2d::CCObject * pTarget, const char* pSelectorName );

	virtual cocos2d::extension::SEL_CCControlHandler onResolveCCBCCControlSelector( cocos2d::CCObject * pTarget, const char* pSelectorName );

	virtual cocos2d::SEL_MenuHandler onResolveCCBCCMenuItemSelector( cocos2d::CCObject * pTarget, const char* pSelectorName );

	virtual bool onAssignCCBMemberVariable( cocos2d::CCObject* pTarget, const char* pMemberVariableName, cocos2d::CCNode* pNode );

	$virtualFunctions
private:
	// Attributes for CCB
$bindMemberVariableDeclare

public:
	// Virtual Functions
	virtual bool init();
	virtual void onEnter();
	virtual void onExit();
$keyMenuAndBackFunctionDeclare
$inheritByCCTableViewVirtualFunctionDeclare
	
public:
	// Funcitons
$bindMenuSelectorDeclare

$bindControlSelectorDeclare

$bindCallfuncSelectorDeclare
};

#endif // __$CLASSNAME__H__