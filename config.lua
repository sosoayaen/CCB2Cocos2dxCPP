-- 智能类型匹配列表，最终生成到h和cpp文件中会以CCxxx展现，如CCMenu
smartMatchTypeTbl =
{
	"MenuItemImage", -- 菜单选项
	"MenuItem", -- 菜单选项
	"Menu",		-- 菜单
	"Sprite",	-- 精灵
	"Layer",	-- 层
	"Node", 	-- 节点
	"LabelBMFont", -- 图片文字
	"LabelTTF", -- 显示文字控件
	"ControlButton", -- 按钮
	"ParticleSystemQuad",	-- 粒子效果
}

-- WIN32 的GUI中选择基类的ComboBox的下拉列表内容
InheritClass =
{
	"CCLayer",
	"CCColorLayer",
	"DialogLayer",
}