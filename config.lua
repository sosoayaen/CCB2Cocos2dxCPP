-- 智能类型匹配列表，最终生成到h和cpp文件中会以CCxxx展现，如CCMenu
smartMatchTypeTbl =
{
	"MenuItem", -- 菜单选项
	"Menu",		-- 菜单
	"Sprite",	-- 精灵
	"Layer",	-- 层
	"Node", 	-- 节点
	"LabelTTF", -- 显示文字控件
}

-- WIN32 的GUI中选择基类的ComboBox的下拉列表内容
InheritClass =
{
	"CCLayer",
	"CCColorLayer",
	"DialogLayer",
}