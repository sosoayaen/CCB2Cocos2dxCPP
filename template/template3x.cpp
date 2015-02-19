#include "$outputfilename.h"

#include "GameLogicCenter.h"
#include "UserDataCenter.h"
#include "bailinUtils.h"
#include "GameHelper.h"

USING_NS_CC;
USING_NS_CC_EXT;

// Add bailin::util namespace
USING_NS_BL_UTIL;

using namespace cocos2d::ui;
using namespace cocosbuilder;

// Constructor
$classname::$classname()
{

}

// Descontructor
$classname::~$classname()
{

}

bool $classname::init()
{
	bool bRet = false;
	do
	{
		CC_BREAK_IF(!$inheritclass::init());
		NodeLoaderLibrary* pLoaderLib = NodeLoaderLibrary::newDefaultNodeLoaderLibrary();

		CCBReader* pCCBReader = new CCBReader(pLoaderLib);

		std::string strCCBFileName = "$ccbifilename";

		// ccbi files source directory path
        std::string strCCBRootPath = "ccbi/";
        
        strCCBFileName = strCCBRootPath + strCCBFileName;
        
        Node* pNode = pCCBReader->readNodeGraphFromFile(strCCBFileName.c_str(), this);
        
        if (pNode != NULL)
        {
            m_pCCBRoot = pNode;
            this->addChild(pNode);
        }
        
        pCCBReader->release();		

		initLabelTTF();
		
		bRet = true;
		
	} while(0);
	
	return bRet;
}

bool $classname::onAssignCCBMemberVariable( Ref* pTarget, const char* pMemberVariableName, Node* pNode )
{
$bindMemberVariable
	return true;
}

$virtualFunctionsImplement

$inheritByTableViewVirtualFunctionImplement
