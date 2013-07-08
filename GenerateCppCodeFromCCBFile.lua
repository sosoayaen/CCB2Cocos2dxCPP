package.path = package.path .. ';.\\?.lua;'

-- 加载外部的配置脚本
require 'config'

local smartMatchTypeTbl = smartMatchTypeTbl;

local arg = arg or {};
local filename = FILENAME or arg[1]
local classname = CLASSNAME or arg[2]
local outputfilename = OUTPUTFILENAME or arg[3] or classname
local outputpath = OUTPUTPATH or arg[4] or ''
local inheritclass = INHERITCLASS or arg[5] or "CCLayer" 	-- 默认继承自CCLayer
local supportAndroidMenuReturn = SUPPORT_ANDROID_MENU_RETURN or arg[6]
local dir = DIR or '';
local useCCTableView = USECCTABLEVIEW or arg[7] -- 设置是否继承自CCTableView

local showlog = showlog or print;

if not filename or filename == "" then
	showlog("No file input...");
	local usage = [[
	Usage: lua %s filename classname
	filename is which ccb file you want to parse
	classname means the [member] and [callback function] belongs to 
	]]
	showlog(string.format(usage, arg[0]));
	return
end

if not classname or classname == "" then
	showlog("class is not given...");
	return
end

-- 先找到memberVarAssignmentName，然后把string取出来
local file = io.open(filename, 'r+b');

if file then
	-- 先读入到内存
	local lineData = file:read("*l");
	local varAssignmentFlag = false;
	local varAssignmentTbl = {};
	local menuSelectorTbl = {};
	local controlSelectorTbl = {};
	local lineCnt = 1;
	-- 数据解析部分，从ccb文件中抓取需要的数据
	while lineData do
		repeat
			if lineData == '' then
				break
			end
			
			-- 判断是否是有变量绑定
			if varAssignmentFlag then
				local memberName = string.match(lineData, "<string>([%w_]-)</string>");
				if memberName and memberName ~= "" then
					table.insert(varAssignmentTbl, memberName);
				end
				varAssignmentFlag = false;
				break;
			end
			
			-- 判断是否有 onPress 关键字（这里建议ccb中回调携程onPressMenu等，避免抓取错误）
			local menuSelector = string.match(lineData, "(onPressMenu[^<]+)");
			if menuSelector then
				table.insert(menuSelectorTbl, menuSelector);
			end
			
			local controlSelector = string.match(lineData, "(onPressControlButton[^<]+)");
			if controlSelector then
				table.insert(controlSelectorTbl, controlSelector);
			end
			
			-- 检查当前行数据是否有memberVarAssignmentName字段
			if string.find(lineData, "memberVarAssignmentName") then
--				showlog("find", "lineNum is ", lineCnt);
				-- 下一行数据为绑定变量
				varAssignmentFlag = true;
				
				break;
			end
		until true
		
		lineCnt = lineCnt + 1;
		lineData = file:read("*l");
	end
	
	file:close();
	
	showlog("------------member list:")
	table.foreach(varAssignmentTbl, function(key, value)
		showlog(value);
	end);
	
	showlog("------------menu selector list:");
	table.foreach(menuSelectorTbl, function(key, value)
		showlog(value);
	end);
	
	-- 预处理数据
	-- 初始化数据h
	local initCodeTbl = {};
	-- 数据定义表h
	local memberVariableDeclareTbl = {};
	-- 数据绑定表cpp
	local memberVariableBindTbl = {};
	-- 菜单回调函数原型h
	local menuSelectorDeclareTbl = {};
	-- 菜单回调绑定cpp
	local menuSelectorBindTbl = {};
	-- 菜单回调函数实现
	local menuSelectorCallbackTbl = {};
	-- Control回调函数原型h
	local controlSelectorDeclareTbl = {};
	-- Control回调绑定cpp
	local controlSelectorBindTbl = {};
	-- Control回调函数实现cpp
	local controlSelectorCallbackTbl = {};
	
	-- 成员变量绑定
	for idx, member in ipairs(varAssignmentTbl) do
		-- 生成初始化代码
		table.insert(initCodeTbl, string.format("\t\t%s = NULL;\n", member));
		
		-- 判断是什么类型的数据
		local varType = 'unKnowType';
		local extension = '';
		for idx, types in ipairs(smartMatchTypeTbl) do
--			if string.find(member, "Part") and string.find(member, types) then error(member .. ' ' .. types) end
			if string.find(member, types) then
				-- 这里可以加入一个判断是否是扩展类型的判断
				-- print(member, types);
				varType = types;
				break;
			end
		end
		table.insert(memberVariableDeclareTbl, string.format('\tcocos2d::%sCC%s* %s;\n', extension, varType, member));
		
		-- 生成绑定成员代码
		table.insert(memberVariableBindTbl,
			string.format('\tCCB_MEMBERVARIABLEASSIGNER_GLUE(this, "%s", CC%s*, this->%s);\n',
			member, varType, member));
				
	end
	
	local menuCallBackTpl = [[void %s::%s(CCObject* pSender)
{
	// TODO:
}

]]
	-- 菜单回调绑定
	for idx, ms in ipairs(menuSelectorTbl) do
		-- 生成菜单回调声明
		table.insert(menuSelectorDeclareTbl, string.format('\tvoid %s(cocos2d::CCObject* pSender);\n', ms));
		-- 生成菜单回调绑定
		table.insert(menuSelectorBindTbl, 
			string.format('\tCCB_SELECTORRESOLVER_CCMENUITEM_GLUE(this, "%s", %s::%s);\n', ms, classname, ms));
		-- 生成对应菜单回调函数实现代码
		table.insert(menuSelectorCallbackTbl, string.format(menuCallBackTpl, classname, ms));
	end
	
	local controlCallBackTbp = [[void %s::%s(CCObject* pSender, CCControlEvent event)
{
	// TODO:
}

]]
	-- Control 回调绑定
	for idx, cs in ipairs(controlSelectorTbl) do
		-- 生成control回调声明
		table.insert(controlSelectorDeclareTbl, string.format('\tvoid %s(cocos2d::CCObject* pSender, cocos2d::extension::CCControlEvent event);\n', cs));
		-- 生成control回调绑定
		table.insert(controlSelectorBindTbl,
			string.format('\tCCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "%s", %s::%s);\n', cs, classname, cs));
		-- 生成对应按钮回调函数实现代码
		table.insert(controlSelectorCallbackTbl, string.format(controlCallBackTbp, classname, cs));
	end
	
	local ccbfilename = string.match(filename, '\\([%w_]+\.ccb)$');
	-- 方便后来一次性替换的临时数据表格
	local DataCache =
	{
		['$ccbifilename'] = ccbfilename .. 'i';		-- ccbi文件名称
		['$classname'] = classname;					-- 当前类名称
		['$CLASSNAME'] = string.upper(classname);	-- 用作文件包含宏定义的名称
		['$DATE'] = os.date("%Y-%m-%d %H:%M:%S", os.time());	-- 当前文件生成日期
		['$prefixClass'] = "public cocos2d::";	-- 放在继承类前面的描述，比如public或者private等，仅在头文件有效，默认是继承子cocos2d命名空间，如果需要自定义修改则在下面逻辑中判断覆盖
		['$inheritclass'] = inheritclass;	-- 继承的类
		['$includeHeader'] = "";	-- 继承的类的头文件包含，自定义的头文件需要在这里包含
		['$virtualFunctions'] = "";	-- 初始化虚函数，比如DialogLayer::initDialog();
		['$memberInit'] = table.concat(initCodeTbl);	-- 初始化代码
				
		['$bindMemberVariableDeclare'] = table.concat(memberVariableDeclareTbl);	-- 成员变量定义
		['$bindMemberVariable'] = table.concat(memberVariableBindTbl);	-- 成员变量绑定
		
		['$bindMenuSelectorDeclare'] = table.concat(menuSelectorDeclareTbl);	-- 菜单回调函数定义
		['$bindMenuSelector'] = table.concat(menuSelectorBindTbl);	-- 菜单回调函数绑定
		['$menuSelectorCallback'] = table.concat(menuSelectorCallbackTbl);	-- cpp中菜单回调的实现
		
		['$bindControlSelectorDeclare'] = table.concat(controlSelectorDeclareTbl); -- control回调函数定义
		['$bindControlSelector'] = table.concat(controlSelectorBindTbl); -- cpp中回调函数绑定
		['$controlSelectorCallback'] = table.concat(controlSelectorCallbackTbl); -- cpp中回调函数实现代码
	
		['$bindCallfuncSelectorDeclare'] = '';	-- 暂时未实现
		['$bindCallfuncSelector'] = '';	-- 暂时未实现
		['$callfuncSelectorCallback'] = '';	-- 暂时未实现
		
		['$setKeypadEnabled'] = "";
		['$androidMenuReturnCallback'] = "";
		['$keyMenuAndBackFunctionDeclare'] = "";
		
		-- CCTableView 处理
		['$inheritByCCTableViewClass'] = "";
		['$inheritByCCTableViewVirtualFunctionDeclare'] = "";
		['$inheritByCCTableViewVirtualFunctionImplement'] = "";
		
	}
	
	-- 如果是继承自DialogLayer
	if inheritclass == "DialogLayer" then
		DataCache['$prefixClass'] = "public ";	-- 直接为DialogLayer，不在cocos2d命名空间下
		-- 加上头文件的include
		DataCache['$includeHeader'] = '#include "DialogLayer.h"';
		-- 加上initDialog的虚函数
		DataCache['$virtualFunctions'] = "virtual bool onInitDialog()\n\t{\n\t\treturn true;\n\t}\n\t";
	end
	
	-- 支持 Android 菜单和返回按钮
	if supportAndroidMenuReturn then
		DataCache['$setKeypadEnabled'] = "setKeypadEnabled(true);";
		local tmpTpl = [[void %s::keyBackClicked( void )
{
	// TODO:
}

void %s::keyMenuClicked( void )
{
	// TODO:
}
]];
		DataCache['$androidMenuReturnCallback'] = string.format(tmpTpl, classname, classname);
		DataCache['$keyMenuAndBackFunctionDeclare'] = [[
	virtual void keyBackClicked( void );
	virtual void keyMenuClicked( void );
]]
	end
	
	-- 支持从CCTableView集成
	if useCCTableView then
		-- 集成类声明
		DataCache['$inheritByCCTableViewClass'] = "\n\tpublic cocos2d::extension::CCTableViewDataSource,\n\tpublic cocos2d::extension::CCTableViewDelegate,";
		-- 设置虚函数声明
		DataCache['$inheritByCCTableViewVirtualFunctionDeclare'] = [[
	//////////////////////////////////////////////////////////////////////////
	// CCScrollViewDelegate virtual function
	//////////////////////////////////////////////////////////////////////////
	virtual void scrollViewDidScroll(cocos2d::extension::CCScrollView* view);

	virtual void scrollViewDidZoom(cocos2d::extension::CCScrollView* view);

	//////////////////////////////////////////////////////////////////////////
	// CCTableViewDelegate virtual function
	//////////////////////////////////////////////////////////////////////////

	virtual void tableCellTouched(cocos2d::extension::CCTableView* table, cocos2d::extension::CCTableViewCell* cell);

	virtual cocos2d::CCSize cellSizeForTable(cocos2d::extension::CCTableView *table);

	virtual cocos2d::extension::CCTableViewCell* tableCellAtIndex(cocos2d::extension::CCTableView *table, unsigned int idx);

	virtual unsigned int numberOfCellsInTableView(cocos2d::extension::CCTableView *table);
]]
		-- 设置cpp中的虚函数实现
		local tmpTpl = [[
void $classname::scrollViewDidScroll( CCScrollView* view )
{

}

void $classname::scrollViewDidZoom( CCScrollView* view )
{

}

void $classname::tableCellTouched( CCTableView* table, CCTableViewCell* cell )
{
	CCLOG("cell touched at index: %i, table's children counts:%i", cell->getIdx()+1, numberOfCellsInTableView(NULL));
	
	if (cell != NULL)
	{
		// TODO: Do something when TOUCH the item
	} // end if (cell != NULL)
}

CCSize $classname::cellSizeForTable( CCTableView *table )
{
	// Return a CCSize with the item size you want to show
	return CCSizeMake(100, 100);
}

CCTableViewCell* $classname::tableCellAtIndex( CCTableView *table, unsigned int idx )
{
	CCTableViewCell* pCell = table->dequeueCell();

	if (!pCell)
	{
		pCell = new CCTableViewCell();
		pCell->autorelease();
		// TODO: Add some control to the Cell like CCSprite and so on ...
	}
	else
	{
		// TODO: Update the Control or data you added before in Cell
	}
	return pCell;
}

unsigned int $classname::numberOfCellsInTableView( CCTableView *table )
{
	// TODO: return the counts of TableView
	return 1;
}
]]
		DataCache['$inheritByCCTableViewVirtualFunctionImplement'] = string.gsub(tmpTpl, "$classname", classname);
	end
	
	--[[
		这里开始生成头文件
	]]
	showlog(string.format("++++++++++ Generate sample data file [%s.h] ", classname));
	local hfilename = outputpath .. outputfilename .. ".h";
	
	local hfile = io.open(hfilename, 'w+b');
	if hfile then
		-- 载入头文件模板
		local templatehfile = io.open(dir .. 'template/template.h', 'r+b');
--		error(tostring(templatehfile))
		local templatehdata = nil;
		if templatehfile then
			templatehdata = templatehfile:read('*a');
			templatehfile:close();
		end
			
		if templatehdata then
			-- 生成头文件数据
			templatehdata = string.gsub(templatehdata, "($[%w]+)", DataCache);
			
			-- 导出头文件
			hfile:write(templatehdata);
		end
		
		hfile:close();
	else
		error(string.format("[%s] can't be opened ...", hfilename));
	end
	
	--[[
		这里开始生成cpp源文件
	]]
	
	showlog(string.format("++++++++++ Generate sample data file [%s.cpp] ", classname));
	local cppfilename = outputpath .. outputfilename .. ".cpp";
	local cppfile = io.open(cppfilename, 'w+b');
	if cppfile then
		-- 载入源文件模板
		local templatecppfile = io.open(dir .. 'template/template.cpp', 'r+b');
		local templatecppdata = nil;
		if templatecppfile then
			templatecppdata = templatecppfile:read('*a');
			templatecppfile:close();
		end
		
		if templatecppdata then
			-- 替换绑定变量数据
			templatecppdata = string.gsub(templatecppdata, "($[%w]+)", DataCache);			
			
			-- 导出源文件
			cppfile:write(templatecppdata);
		end
		
		cppfile:close();
	else
		error(string.format("[%s] can't be opened ...", hfilename));
	end
	
else
	error(string.format("Open file [%s] failed, please be sure the file is existed and try again later.", filename));
end
