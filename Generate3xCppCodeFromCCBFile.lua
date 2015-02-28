-- 此脚本是用来生成cocos2d-x 3.x版本的代码
package.path = package.path .. ';.\\?.lua;'

-- 加载外部的配置脚本
require 'config3x'

-- 加载插件继承类脚本
local inheritClassHanleFunc = require 'pluggin.inherit'
-- 加载插件tableviewex
local tableviewexHandleFunc = require 'pluggin.tableviewex'

local arg = arg or {};

-- 存放解析命令的表
local cmdTbl = {}
-- 是否直接把value存放到上一次对应解析到的命令表中的标志
local bSetValue = false
-- 对应的命令
local command = nil;
-- 辅助的命令表，用于配置只需要配置true的命令
local assistCmdTbl = 
{
	['--sa'] = true,
	['--supportandroidmenu'] = true,
	['--stv'] = true,
	['--usetableview'] = true,
	['-h'] = true,
	['--help'] = true
}

-- 解析命令
table.foreachi(arg, function(idx, value)
	-- 是否设置
	if bSetValue then
		bSetValue = false
		if command then
			cmdTbl[command] = value
		end
	else
	-- 表示是取命令模式
		if assistCmdTbl[value] then
			-- 直接设置该属性为true即可
			cmdTbl[value] = true
		else
			command = value
			bSetValue = true
		end
	end
end)

-- table.foreach(cmdTbl, print)

local filename = FILENAME or cmdTbl['-f'] or cmdTbl['--filename']
-- 文件名先判断下是否是根目录，如果是根目录就是绝对路径
-- 如果是相对路径则加上配置的目录
if string.match(filename or '', '[^/\\]') then
	filename = (defaultConfig.source_directory or '') .. filename
end

local classname = CLASSNAME or cmdTbl['-c'] or cmdTbl['--classname']
if not classname or classname == '' then
	-- 按照文件名去除后缀的方式取得默认类名称
	classname = string.match(filename or '', '([%w_-]+)\.ccb$')
end

-- 输出的文件名默认就是类名
local outputfilename = OUTPUTFILENAME or cmdTbl['-o'] or cmdTbl['--outputfilename'] or classname

-- 默认就是当前目录
local outputpath = OUTPUTPATH or cmdTbl['-p'] or cmdTbl['--outputpath'] or defaultConfig.output_directory or '.'

-- 优化下路径，添加最后的文件夹路径
if not string.match(outputpath, '.+[\\/]$') then
	outputpath = outputpath .. '/';
end

local inheritclass = INHERITCLASS or cmdTbl['-i'] or cmdTbl['--inheritclass'] or "Layer" 	-- 默认继承自Layer
local supportAndroidMenuReturn = SUPPORT_ANDROID_MENU_RETURN or cmdTbl['--sa'] or cmdTbl['--supportandroidmenu']
local dir = DIR or '';
local useTableView = USETABLEVIEW or cmdTbl['--stv'] or cmdTbl['--usetableview'] -- 设置是否继承自CCTableView

local showlog = showlog or function(pattern, ...)
	print(string.format(pattern, unpack(arg or {})))
end

local usage = [[
Usage: lua %s -f filename -c classname
filename is which ccb file you want to parse
classname means the "member" and "callback function" belongs to 
]]

local helpTxt = [[
lua %s -f filename -c classname [-o outputfilename] [-p outputpath] [-i inheritclass] [-sa] [-stv]
  -f	filename	Specify CCB file path.
  -c	classname	Give the class name of cpp file.
  -o	outputfilename	Specify out put file name, it will auto add the ".h" and ".cpp" suffix. It will be classname in default.
  -p	outputpath	Specify out put file path	
  -i	inheritclass	This parameter could supply a inheritclass for your class, CCLayer will be default.
  --sa	If this parameter is set, the "keyBackClicked" and "keyMenuClicked" function will be generated in code. It only supply in Android / Win32
  --stv If this parameter is set, the code will support CCTableView and auto generate some virtual function in code to operate CCTableView
]]
-- 解析帮助
if cmdTbl['-h'] or cmdTbl['--help'] then
	showlog(string.format(helpTxt, arg[0]))
	return
end

-- 校验输入ccb文件名
if not filename or filename == "" then
	showlog("Please input the filename by -f ...");
	showlog(string.format(usage, arg[0]));
	return
end

showlog('==================================')
-- 读取默认的配置文件
showlog('Default config infomation')
showlog('i.   Source directory:')
showlog(string.format('     %s', defaultConfig.source_directory or 'nil'))
showlog('ii.  Output directory:')
showlog(string.format('     %s', defaultConfig.output_directory or 'nil'))
-- 提示对应输入的参数
showlog(string.format('1. Source file is [%s]', filename))
-- 类名
showlog(string.format('2. Class name is [%s]', classname))
-- 输出目录
showlog(string.format('3. Output file path is [%s]', outputpath))
-- 文件名
showlog(string.format('4. Header file name is [%s.h], source file name is [%s.cpp]', outputfilename, outputfilename))

-- 罗列输出的序号，前面已经有4个列表了，所以初始化为4
local helpTxtCnt = 4
-- 继承
if inheritclass then
	helpTxtCnt = helpTxtCnt + 1
	showlog(string.format('%d. Inherit from [%s]', helpTxtCnt, inheritclass))
end
-- 是否实现TableViewEx
if useTableView then
	helpTxtCnt = helpTxtCnt + 1
	showlog(string.format("%d. Use TableViewEx and implement the virtual functions", helpTxtCnt))
end
showlog('==================================')

-- 先找到memberVarAssignmentName，然后把string取出来
local file = io.open(filename, 'r+b');

local FLAG_MEMBER_NONE		= 0
-- 绑定变量的说明
local FLAG_MEMBER_COMMENT	= 1
-- 绑定变量的名字
local FLAG_MEMBER_NAME		= 2
-- 变量基类标志
local FLAG_MEMBER_CLASS		= 3

if file then
	-- 先读入到内存
	local lineData = file:read("*l");
	local varAssignmentFlag = FLAG_MEMBER_NONE;
	local varAssignmentTbl = {};
	local varAssignmengOnceTbl = {}; -- 避免同名变量重复定义
	local menuSelectorTbl = {};
	local menuSelectorOnceTbl = {}; -- 避免重复回调的表
	local controlSelectorTbl = {};
	-- 用来保存得到的所有的变量基类名字，最后一个就是当前处理的基类名字
	-- 遇到一个display后移除最后的类名
	local baseClassNestTbl = {}

	local lineCnt = 1;
	-- 数据解析部分，从ccb文件中抓取需要的数据
	while lineData do
		repeat	-- 为了能break，故意加上一个循环
			if lineData == '' then
				break
			end
			
			-- 校验是否是基类
			if varAssignmentFlag == FLAG_MEMBER_CLASS then
				local baseClass = string.match(lineData, "<string>(.+)</string>")
				if baseClass and baseClass ~= "" then
					-- 根据当前的版本转换下类名，把命名空间顺便也塞一份新的，供后面调用
					local baseClassConfig = classChange3xConfig[baseClass]
					local newBaseClass = {}
					newBaseClass.baseClass = (baseClassConfig and baseClassConfig.baseClass) or baseClass
					newBaseClass.nameSpace = (baseClassConfig and baseClassConfig.nameSpace) or 'cocos2d'
					table.insert(baseClassNestTbl, newBaseClass)
				else
					error("baseClass could not be nil or empty string!")
				end
				-- 清空
				varAssignmentFlag = FLAG_MEMBER_NONE
				break
			-- 检查是否是注释，注释是在之前的
			elseif varAssignmentFlag == FLAG_MEMBER_COMMENT then
				local comment = string.match(lineData, "<string>(.+)</string>")
				if comment and comment ~= "" then
					local member = {}
					-- 得到描述的名称
					-- showlog(string.format('comment:[%s]', comment))
					member.comment = comment
					-- 变量的注释会先于绑定变量名出现，所以会先生成一个member对象
					table.insert(varAssignmentTbl, member)
				end
				varAssignmentFlag = FLAG_MEMBER_NONE
				break
			-- 判断是否是有变量绑定
			elseif varAssignmentFlag == FLAG_MEMBER_NAME then
				local memberName = string.match(lineData, "<string>([%w_]-)</string>");
				if memberName and memberName ~= "" and not varAssignmengOnceTbl[memberName] then
					varAssignmengOnceTbl[memberName] = true
					local member = varAssignmentTbl[#varAssignmentTbl]
					if type(member) == 'table' then
						member.name = memberName
						local baseClassConfig = (#baseClassNestTbl > 0) and baseClassNestTbl[#baseClassNestTbl]
						if not baseClassConfig then
							error(string.format('baseClass could not be nil!!, member.name:[%s]', member.name))
						end

						member.baseClass = baseClassConfig.baseClass
						member.nameSpace = baseClassConfig.nameSpace
						--[[
						showlog('---==MEMBER CONTENT==---')
						table.foreach(member, print)
						--]]
					end
				end
				varAssignmentFlag = FLAG_MEMBER_NONE
				-- 基类栈顶缓存出栈，回到上一个未被匹配的项
				table.remove(baseClassNestTbl, #baseClassNestTbl)
				break
			end

			-- 判断是否有 onPress 关键字（这里建议ccb中回调写成onPressMenu等，避免抓取错误）
			local menuSelector = string.match(lineData, "(onPressMenu[^<]+)");
			if menuSelector and not menuSelectorOnceTbl[menuSelector] then
				-- 标志该菜单回调方法已经有了，下次遇到不再添加代码段
				menuSelectorOnceTbl[menuSelector] = true
				table.insert(menuSelectorTbl, menuSelector)
			end
			
			local controlSelector = string.match(lineData, "(onPressControlButton[^<]+)");
			if controlSelector then
				table.insert(controlSelectorTbl, controlSelector)
			end
			
			-- 针对Key的名字设置对应的标志名称
			local keyName = string.match(lineData, "<key>(.+)</key>")
			if keyName == "displayName" then
				-- 检查是否是display字段
				varAssignmentFlag = FLAG_MEMBER_COMMENT
			elseif keyName == "memberVarAssignmentName" then
				-- 下一行数据为绑定变量
				varAssignmentFlag = FLAG_MEMBER_NAME
			elseif keyName == "baseClass" then
				-- 下一行数据为基类名称
				varAssignmentFlag = FLAG_MEMBER_CLASS
			end

		until true
		
		lineCnt = lineCnt + 1;
		lineData = file:read("*l");
	end
	
	file:close();
	
	showlog("----- Member bind list:")
	-- 绑定变量的个数
	local nMemberBindCnt = 0
	table.foreach(varAssignmentTbl, function(key, value)
		if value.name then
			showlog("member variable: %s", value.name)
			nMemberBindCnt = nMemberBindCnt + 1
		end
	end);
	
	showlog("----- Menu selector bind list:");
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
	
	-- 增加一个判断重复的列表，如果有重复则不添加
	local duplicateTbl = {};
	-- 记录重复的变量名称
	local duplicateVariableNameTbl = {}
	
	-- 成员变量绑定
	for idx, member in ipairs(varAssignmentTbl) do
		-- 只有成员变量名称命名的才绑定，否则略过
		if member.name then
			if duplicateTbl[member.name] ~= true then
				duplicateTbl[member.name] = true
				--[[
				showlog('--======--')
				table.foreach(member, print)
				--]]

				table.insert(memberVariableDeclareTbl, string.format('\t// %s\n\t%s::%s* %s = nullptr;\n', member.comment, member.nameSpace, member.baseClass, member.name));
				
				-- 生成绑定成员代码
				table.insert(memberVariableBindTbl,
					string.format('\tCCB_MEMBERVARIABLEASSIGNER_GLUE_WEAK(this, "%s", %s*, this->%s);\n',
					member.name, member.baseClass, member.name));
			else
				-- 把重复的记录下来，输出到最终日志中
				duplicateVariableNameTbl[member.name] = (duplicateVariableNameTbl[member.name] or 0) + 1
			end
		end
	end
	
	local menuCallBackTpl = [[void %s::%s(Ref* pSender)
{
	// TODO:
}

]]

	duplicateTbl = {}
	-- 菜单回调绑定
	for idx, ms in ipairs(menuSelectorTbl) do
		if duplicateTbl[ms] ~= true then
			duplicateTbl[ms] = true
			-- 生成菜单回调声明
			table.insert(menuSelectorDeclareTbl, string.format('\tvoid %s(cocos2d::Ref* pSender);\n', ms));
			-- 生成菜单回调绑定
			table.insert(menuSelectorBindTbl, 
			string.format('\tCCB_SELECTORRESOLVER_CCMENUITEM_GLUE(this, "%s", %s::%s);\n', ms, classname, ms));
			-- 生成对应菜单回调函数实现代码
			table.insert(menuSelectorCallbackTbl, string.format(menuCallBackTpl, classname, ms));
		end
	end
	
	local controlCallBackTbp = [[void %s::%s(Ref* pSender, ControlEvent event)
{
	// TODO:
}

]]

	duplicateTbl = {}
	-- Control 回调绑定
	for idx, cs in ipairs(controlSelectorTbl) do
		if duplicateTbl[cs] ~= true then
			duplicateTbl[cs] = true
			-- 生成control回调声明
			table.insert(controlSelectorDeclareTbl, string.format('\tvoid %s(cocos2d::Ref* pSender, cocos2d::extension::ControlEvent event);\n', cs));
			-- 生成control回调绑定
			table.insert(controlSelectorBindTbl,
				string.format('\tCCB_SELECTORRESOLVER_CCCONTROL_GLUE(this, "%s", %s::%s);\n', cs, classname, cs));
			-- 生成对应按钮回调函数实现代码
			table.insert(controlSelectorCallbackTbl, string.format(controlCallBackTbp, classname, cs));
		end
	end
	
	local ccbfilename = string.match(filename, '([%w_]+\.ccb)$');
	-- 方便后来一次性替换的临时数据表格
	local DataCache =
	{
		['$ccbifilename'] = ccbfilename .. 'i';		-- ccbi文件名称
		['$classname'] = classname;					-- 当前类名称
		['$outputfilename'] = outputfilename;	-- 文件名 
		['$CLASSNAME'] = string.upper(classname);	-- 用作文件包含宏定义的名称
		['$DATE'] = os.date("%Y-%m-%d %H:%M:%S", os.time());	-- 当前文件生成日期
		['$prefixClass'] = "public cocos2d::";	-- 放在继承类前面的描述，比如public或者private等，仅在头文件有效，默认是继承子cocos2d命名空间，如果需要自定义修改则在下面逻辑中判断覆盖
		['$inheritclass'] = inheritclass;	-- 继承的类
		['$includeHeader'] = '';	-- 继承的类的头文件包含，自定义的头文件需要在这里包含，如果是cocos的类，则不需要指明加载对应的头文件
		['$publicVirtualFunctionsDeclare'] = "";	-- 继承类的虚函数声明(public)
		['$privateVirtualFunctionsDeclare'] = "";	-- 继承类的虚函数声明(private)
		['$protectedVirtualFunctionsDeclare'] = "";	-- 继承类的虚函数声明(protected)
		['$virtualFunctionsImplement'] = "";	-- 虚函数的实现
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
		['$inheritByTableViewClass'] = "";
		['$inheritByTableViewVirtualFunctionDeclare'] = "";
		['$inheritByTableViewVirtualFunctionImplement'] = "";
		
	}

	-- 处理插件中支持自定义继承的处理，比如DialogLayer，ContentBaseLayer等
	if inheritClassHanleFunc then
		inheritClassHanleFunc(DataCache, inheritclass, classname)
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
	
	-- 支持从TableView集成
	if useTableView and tableviewexHandleFunc then
		tableviewexHandleFunc(DataCache, classname)
	end
	
	--[[
		这里开始生成头文件
	]]
	showlog("++++++++++ Generate sample data file [%s.h]", classname);

	local hfilename = outputpath .. outputfilename .. ".h";
	
	local hfile = io.open(hfilename, 'w+b');
	if hfile then
		-- 载入头文件模板
		local templatehfile = io.open(dir .. 'template/template3x.h', 'r+b');
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
	
	showlog("++++++++++ Generate sample data file [%s.cpp]", classname);
	local cppfilename = outputpath .. outputfilename .. ".cpp";
	local cppfile = io.open(cppfilename, 'w+b');
	if cppfile then
		-- 载入源文件模板
		local templatecppfile = io.open(dir .. 'template/template3x.cpp', 'r+b');
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
	
	-- 输出对应的结果
	-- 绑定变量的个数
	showlog('========== Member bind count: %d ==========', nMemberBindCnt)
	-- 显示重复的变量名称，和重复的次数
	showlog(' ----Duplicated member variable data----')
	table.foreach(duplicateVariableNameTbl, function(key, value)
		showlog(' - name:[%s] cnt:[%d]', key, value)
	end)
	showlog(' ' .. string.rep('-', 39))

else
	error(string.format("Open file [%s] failed, please be sure the file is existed and try again later.", filename));
end
