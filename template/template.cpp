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
		// ����ccbi
		CCNodeLoaderLibrary* pLoaderLib = CCNodeLoaderLibrary::newDefaultCCNodeLoaderLibrary();

		CCBReader* pCCBReader = new CCBReader(pLoaderLib);

		// ��Ӧccbi�ļ�
		std::string strCCBFileName = "$ccbifilename";

		// �õ���һ������·��
		const std::vector<std::string> vSearchOrder = CCFileUtils::sharedFileUtils()->getSearchResolutionsOrder();

		// ���������Ƕ�Ӧ�ĵ�һ��Ԫ�ؼ�Ϊ��Ӧ����Դ·��
		std::string strCCBRootPath = vSearchOrder[0];

		// ����CCB����Դ·��
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
	// TODO: ������Զ�����볡���ĳ�ʼ��������ؼ��ĳ�ʼλ�ã���ʼ״̬��
}

void $classname::onExit()
{
	$inheritclass::onExit();
	// TODO: �˳�������ȡ��CCNotificationCenter���Է��������������Ƕ�Ӧ��onEnter��ʱ��Ҫ����ע��
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