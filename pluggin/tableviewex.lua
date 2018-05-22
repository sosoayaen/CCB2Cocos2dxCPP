-- 处理TableViewEx类的继承问题
return function(DataCache, className)
	-- 头文件中，类的继承部分
	DataCache['$inheritByTableViewClass'] = [[ 
	public cocos2d::extension::TableViewDataSource,
	public bailin::ui::TableViewDelegateEx,]]

	-- 增加bailinUi.h
	DataCache['$includeHeader'] = DataCache['$includeHeader'] .. '\n#include "bailinUi.h"'
	DataCache['$customNamespace'] = DataCache['$customNamespace'] .. '\nUSING_NS_BL_UI;'

	-- 预定义的变量，cell 的大小和对应的 tableview 变量
	local tableview_variable = [[
	// size of cell
	cocos2d::Size m_sizeCell;
	// tableview
	bailin::ui::TableViewEx* m_pTableView = nullptr;
	]]
	DataCache['$privateAttributesVariable'] = DataCache['$privateAttributesVariable'] .. '\n' .. tableview_variable 

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

	/**
	 * @brief generate the cell node
	 */
	cocos2d::Node* generateCellNode(ssize_t idx);
	]]
	DataCache['$privateVirtualFunctionsDeclare'] = DataCache['$privateVirtualFunctionsDeclare'] .. initTableViewControlDeclare

	local initTableViewImplement = [[
void %s::initTableViewControl()
{
	// FIXME: set the cell size
	m_sizeCell = Size::ZERO;

	// TODO: create instance of tableviewex
	// const auto& sizeView = m_pLayerTableviewContainer->getContentSize();
	// m_pTableView = TableViewEx::create(this, sizeView);
	// m_pTableView->setDelegate(this);
	// m_pLayerTableviewContainer->addChild(m_pTableView);
	// m_pTableView->setDirection(cocos2d::extension::ScrollView::Direction::VERTICAL);
	// m_pTableView->reloadData();
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
	return m_sizeCell;
}

Node* $classname::generateCellNode(ssize_t idx)
{
	// TODO: generate the cell node with idx of data source
	//       Add some control to the Cell like Sprite and so on ...
}

TableViewCell* $classname::tableCellAtIndex( TableView *table, ssize_t idx )
{
	TableViewCell* pCell = table->dequeueCell();

	if (!pCell)
	{
		pCell = new TableViewCell();
		pCell->autorelease();
	}

	if (pCell)
	{
		// clear all children
		pCell->removeAllChildren();

		// generate the cell node
		auto pCellNode = generateCellNode(idx);

		// add node to cell in middle of rectangle
		pCellNode->setAnchorPoint(Vec2::ANCHOR_MIDDLE);
		pCellNode->setPosition(m_sizeCell * 0.5f);
		pCell->addChild(pCellNode);

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
	cocos2d::Point pt = cell->convertToNodeSpace(touch->getLocation());

	// TODO: Get the point in cell, you can judge which element touched
}
]]

	-- 虚函数的实现
	DataCache['$inheritByTableViewVirtualFunctionImplement'] = string.gsub(tableViewVirtualFunctionsImplement, "$classname", className);
end
