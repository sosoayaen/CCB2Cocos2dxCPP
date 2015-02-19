-- 智能类型匹配列表，最终生成到h和cpp文件中会以CCxxx展现，如CCMenu
smartMatchTypeTbl =
{
	{key = "MenuItemImage", ns = "cocos2d"}, -- 菜单选项
	{key = "MenuItem", ns = "cocos2d"}, -- 菜单选项
	{key = "Menu", ns = "cocos2d"},		-- 菜单
	{key = "Sprite", ns = "cocos2d"},	-- 精灵
	{key = "Layer", ns = "cocos2d"},	-- 层
	{key = "Node", ns = "cocos2d"}, 	-- 节点
	--[[
	{key = "LabelBMFont", ns = "cocos2d"}, -- 图片文字
	{key = "LabelTTF", ns = "cocos2d"}, -- 显示文字控件
	--]]
	{key = "Label", ns = "cocos2d"},	-- 字体
	{key = "ControlButton", ns = "cocos2d"}, -- 按钮
	{key = "ParticleSystemQuad", ns = "cocos2d"},	-- 粒子效果
	{key = "Scale9Sprite", ns = "cocos2d::ui"},	-- 九宫格图片
}

-- WIN32 的GUI中选择基类的ComboBox的下拉列表内容
InheritClass =
{
	"Layer",
	"ColorLayer",
	"DialogLayer",
	"ContentBaseLayer",
}

-- 配置信息
defaultConfig =
{
	-- 源文件夹，设置了此数据后，可以只输入文件名，自己会搜索这个目录下的文件
	['source_directory'] = nil,
	-- 输出文件夹
	['output_directory'] = nil,
}
