#include "$classname.h"

USING_NS_CC;
USING_NS_CC_EXT;

$classname::~$classname()
{
}

bool $classname::init()
{
	// TODO:
	bool bRet = false;
	do
	{
		CC_BREAK_IF(!$inheritclass::init());
		// 加载ccbi
		CCNodeLoaderLibrary* pLoaderLib = CCNodeLoaderLibrary::newDefaultCCNodeLoaderLibrary();

		CCBReader* pCCBReader = new CCBReader(pLoaderLib);

		// 对应ccbi文件
		std::string strCCBFileName = "$ccbifilename";

		// 得到第一个搜索路径
		const std::vector<std::string> vSearchOrder = CCFileUtils::sharedFileUtils()->getSearchResolutionsOrder();

		// 本程序中是对应的第一个元素即为对应的资源路径
		std::string strCCBRootPath = vSearchOrder[0];

		// 设置CCB的资源路径
		pCCBReader->setCCBRootPath(strCCBRootPath.c_str());

		CCNode* pNode = pCCBReader->readNodeGraphFromFile(strCCBFileName.c_str(), this);

		if (pNode != NULL)
		{
			this->addChild(pNode);
		}

		pCCBReader->release();
		
		$setKeypadEnabled
		
		bRet = true;
		
	} while(0);
	
	return bRet;
}

void $classname::onEnter()
{
	$inheritclass::onEnter();
	// TODO: 这里可以定义进入场景的初始化，比如控件的初始位置，初始状态等
}

void $classname::onExit()
{
	$inheritclass::onExit();
	// TODO: 退出场景，取消CCNotificationCenter可以放在这里做，但是对应在onEnter的时候要重新注册
}

SEL_CallFuncN $classname::onResolveCCBCCCallFuncSelector( CCObject * pTarget, const char* pSelectorName )
{
$bindCallfuncSelector
	return NULL;
}

SEL_MenuHandler $classname::onResolveCCBCCMenuItemSelector( CCObject * pTarget, const char* pSelectorName )
{
$bindMenuSelector
	return NULL;
}

bool $classname::onAssignCCBMemberVariable( CCObject* pTarget, const char* pMemberVariableName, CCNode* pNode )
{
$bindMemberVariable
	return true;
}

SEL_CCControlHandler $classname::onResolveCCBCCControlSelector( CCObject * pTarget, const char* pSelectorName )
{
$bindControlSelector
	return NULL;
}

$menuSelectorCallback

$controlSelectorCallback

$callfuncSelectorCallback

$androidMenuReturnCallback

$inheritByCCTableViewVirtualFunctionImplement