-- cocos2d-x 2.x到3.x的转换表格
classChange3xConfig =
{
	-- 菜单图片
	['CCMenuItemImage'] = {
		baseClass = 'MenuItemImage',
		nameSpace = 'cocos2d'
	},
	-- 菜单容器
	['CCMenu'] = {
		baseClass = 'Menu',
		nameSpace = 'cocos2d'
	},
	-- 层
	['CCLayer'] = {
		baseClass = 'Layer',
		nameSpace = 'cocos2d'
	},
	-- 彩色层
	['CCLayerColor'] = {
		baseClass = 'LayerColor',
		nameSpace = 'cocos2d'
	},
	-- 渐变层
	['CCLayerGradient'] = {
		baseClass = 'LayerGradient',
		nameSpace = 'cocos2d'
	},
	-- 九宫格图片
	['CCScale9Sprite'] = {
		baseClass = 'Scale9Sprite',
		nameSpace = 'cocos2d::ui',
		-- 绑定变量的时候的额外的前缀
		bindNameSpace = "ui"
	},
	-- 精灵图片
	['CCSprite'] = {
		baseClass = 'Sprite',
		nameSpace = 'cocos2d'
	},
	-- 节点
	['CCNode'] = {
		baseClass = 'Node',
		nameSpace = 'cocos2d'
	},
	-- TTF字体
	['CCLabelTTF'] = {
		baseClass = 'Label',
		nameSpace = 'cocos2d'
	},
	-- 图字
	['CCLabelBMFont'] = {
		baseClass = 'Label',
		nameSpace = 'cocos2d'
	},
	-- 按钮
	['CCControlButton'] = {
		byerGradientaseClass = 'ControlButton',
		nameSpace = 'cocos2d::ext'
	},
	-- 例子效果
	['CCParticleSystemQuad'] = {
		baseClass = 'ParticleSystemQuad',
		nameSpace = 'cocos2d'
	}
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
	['source_directory'] = '/Users/mac/Documents/bailin/projects/guaji-sango/ccb/Resources/',
	-- 输出文件夹
	['output_directory'] = '/Users/mac/Documents/bailin/projects/guaji-sango/frameworks/runtime-src/Classes/scene/dialog/JifenDuihuanDialog/'
}
