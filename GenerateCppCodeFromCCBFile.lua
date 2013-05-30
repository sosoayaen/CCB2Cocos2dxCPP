package.path = package.path .. ';.;'
local filename = FILENAME or arg[1]
local classname = CLASSNAME or arg[2]
local outputfilename = OUTPUTFILNAME or classname
local outputpath = OUTPUTPATH or ''
local dir = DIR or '';

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

-- 智能类型匹配列表，最终生成到h和cpp文件中会以CCxxx展现，如CCMenu
local smartMatchTypeTbl =
{
	"Menu",		-- 菜单
	"Sprite",	-- 精灵
	"Layer",	-- 层
	"Node", 	-- 节点
	"MenuItem", -- 菜单选项
	"LabelTTF", -- 显示文字控件
}


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
			
			local controlSelector = string.match(lineData, "(onPressControl[^<]+");
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
			if string.find(member, types) then
				-- 这里可以加入一个判断是否是扩展类型的判断
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
	
	local menuCallBackTpl = [[void %s::%s(CCObject* pSender, CCControlEvent event)
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
		table.insert(controlSelectorCallbackTbl, string.format(controlCallBackTbp, classname, ms));
	end
	
	-- 方便后来一次性替换的临时数据表格
	local DataCache =
	{
		['$ccbifilename'] = filename .. 'i';		-- ccbi文件名称
		['$classname'] = classname;					-- 当前类名称
		['$CLASSNAME'] = string.upper(classname);	-- 用作文件包含宏定义的名称
		['$DATE'] = os.date("%Y-%m-%d %H:%M:%S", os.time());	-- 当前文件生成日期
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
	}
	
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
