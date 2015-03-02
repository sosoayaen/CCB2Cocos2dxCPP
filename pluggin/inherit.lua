-- 此文件为继承类的特殊处理
-- 在继承自特殊的类时，在这里进行特殊处理
-- 目前仅仅支持cocos2d-x 3.x代码的生成

local commonHandleFunc = function(Cache, inheritClassName, className)
	-- 加上包含的头文件
	Cache['$includeHeader'] = '#include "' .. inheritClassName .. '.h"'
end

-- @function 增加对应虚函数实现
local appendVirtualFunctionsImplment = function(Cache, strImplment)
	Cache['$virtualFunctionsImplement'] = Cache['$virtualFunctionsImplement'] .. strImplment
end

-- @class DialogLayer的处理函数
-- @param Cache 外部传入的数据缓存表，函数内部可以修改最终生成的数据
local dialogLayerHandleFunc = function(Cache, inheritClassName, className)
	-- 通用处理
	commonHandleFunc(Cache, inheritClassName, className)
	-- DialogLayer 现在是归类在 bailin::ui::命名空间下
	Cache['$prefixClass'] = 'public bailin::ui::'
	--[[
	-- 增加initMainBoard虚函数实现
	Cache['$privateVirtualFunctionsDeclare'] = '\tvirtual bool initMainBoard() override;\n'
	-- 增加虚函数实现体
	local initMainBoardImplement = [-[
bool %s::initMainBoard()
{
	bool bRet = false;
	do
	{
		// TODO: implement MainBoard initialized
		// e.g. m_pMainBoardNode = Node::create();
		//      m_pMainBoardNode->setPosition(getContentSize()*0.5f);
		//      addChild(m_pMainBoardNode);

		bRet = true;
		
	} while (0);

	return bRet;
}
	]-]
	appendVirtualFunctionsImplment(Cache, string.format(initMainBoardImplement, className))
	--]]
end

-- @class ContentBaseLayer 处理函数
-- @param Cache
local contentBaseLayerFunc = function(Cache, inheritClassName, className)
	-- 通用处理
	commonHandleFunc(Cache, inheritClassName, className)
	-- ContentBaseLayer 是和项目相关的，仅仅在三国挂机项目中有效，所以没有定义工具类的命名空间
	Cache['$prefixClass'] = 'public '
	-- ContentBaseLayer需要子类实现一个重排布的函数
	Cache['$protectedVirtualFunctionsDeclare'] = '\tvirtual bool reLayout() override;\n'
	-- 重新布局的实现函数
	local reLayoutImplement = [[
void %s::reLayout()
{
	// TODO: reLayout will be called when content size changed, so relayout every
	//       child in this layer
}
	]]
	appendVirtualFunctionsImplment(Cache, string.format(reLayoutImplement, className))
end

-- 继承处理表格，key为特殊的继承类类名，value为处理函数
local inheritClassHandle =
{
	['DialogLayer'] = dialogLayerHandleFunc,
	['ContentBaseLayer'] = contentBaseLayerFunc,
}

-- 返回的处理函数，只需要把类名作为参数传入即可，如果匹配处理了就返回true，否则返回false
return function(Cache, inheritClassName, className)
	-- 表示是否处理
	local handleFunc = inheritClassHandle[inheritClassName] 
	local bHandled = type(handleFunc) == 'function'
	if bHandled then
		handleFunc(Cache, inheritClassName, className)
	end

	return bHandled
end
