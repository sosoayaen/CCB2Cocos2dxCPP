-- 处理TableViewEx类的继承问题
return function(DataCache, className)
	-- 头文件中，类的继承部分
	DataCache['$inheritByTableViewClass'] = [[ 
	public cocos2d::extension::TableViewDataSource,
	public bailin::ui::TableViewDelegateEx,]]

	-- 增加bailinUi.h
	DataCache['$includeHeader'] = DataCache['$includeHeader'] .. '\n#include "bailinUi.h"'
	DataCache['$customNamespace'] = DataCache['$customNamespace'] .. '\nUSING_NS_BL_UI;'

	-- 虚函数在头文件的声明
	DataCache['$inheritByTableViewVirtualFunctionDeclare'] = [[
	//////////////////////////////////////////////////////////////////////////
	// TableViewDelegate virtual function
	//////////////////////////////////////////////////////////////////////////
	virtual cocos2d::Size cellSizeForTable(cocos2d::extension::TableView *table) override;

	virtual cocos2d::extension::TableViewCell* tableCellAtIndex(cocos2d::extension::TableView *table, ssize_t idx) override;

	virtual ssize_t numberOfCellsInTableView(cocos2d::extension::TableView *table) override;

	// for TableViewDelegate
	virtual void tableCellTouched(cocos2d::extension::TableView* table, cocos2d::extension::TableViewCell* cell) override
	{
		return;
	}

	//////////////////////////////////////////////////////////////////////////
	// TableViewDelegateEx virtual function
	//////////////////////////////////////////////////////////////////////////
	virtual void tableCellTouchedWithTouch(bailin::ui::TableViewEx* table, cocos2d::extension::TableViewCell* cell, cocos2d::Touch* touch) override;
	]]

	-- 增加表格初始化私有函数
	local initTableViewControlDeclare = [[
	/**
	 * @brief create the tableviewex control
	 */
	void initTableViewControl();
	]]
	DataCache['$privateVirtualFunctionsDeclare'] = DataCache['$privateVirtualFunctionsDeclare'] .. initTableViewControlDeclare

	local initTableViewImplement = [[
void %s::initTableViewControl()
{
	// TODO: create instance of tableviewex
}
	]]
	DataCache['$privateFunctionImplement'] = DataCache['$privateFunctionImplement'] .. string.format(initTableViewImplement, className)

	local initTableViewControlCall = [[
		// call init tableview control Method
		initTableViewControl();
	]]
	-- 增加初始化的调用
	DataCache['$initCallMethod'] = DataCache['$initCallMethod'] .. initTableViewControlCall

	local tableViewVirtualFunctionsImplement = [[
Size $classname::cellSizeForTable( TableView *table )
{
	// Return a Size with the item size you want to show
	return Size::ZERO;
}

TableViewCell* $classname::tableCellAtIndex( TableView *table, ssize_t idx )
{
	TableViewCell* pCell = table->dequeueCell();

	bool bCreateCell = false;

	if (!pCell)
	{
		pCell = new TableViewCell();
		pCell->autorelease();
	}

	if (pCell)
	{
		// TODO: Add some control to the Cell like Sprite and so on ...
	}
	return pCell;
}

ssize_t $classname::numberOfCellsInTableView( TableView *table )
{
	// TODO: return the counts of TableView
	return 0;
}

void $classname::tableCellTouchedWithTouch(bailin::ui::TableViewEx* table, cocos2d::extension::TableViewCell* cell, cocos2d::Touch* touch)
{
	Point pt = cell->convertToNodeSpace(touch->getLocation());

	// TODO: Get the point in cell, you can judge which element touched
}
]]

	-- 虚函数的实现
	DataCache['$inheritByTableViewVirtualFunctionImplement'] = string.gsub(tableViewVirtualFunctionsImplement, "$classname", className);
end
