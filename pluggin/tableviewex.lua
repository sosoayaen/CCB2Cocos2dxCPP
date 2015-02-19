-- 处理TableViewEx类的继承问题
return function(DataCache, className)
	-- 头文件中，类的继承部分
	DataCache['$inheritByTableViewClass'] = [[ 
	public cocos2d::extension::TableViewDataSource,
	public bailin::ui::TableViewDelegateEx,]]

	-- 虚函数在头文件的声明
	DataCache['$inheritByTableViewVirtualFunctionDeclare'] = [[
	//////////////////////////////////////////////////////////////////////////
	// ScrollViewDelegate virtual function
	//////////////////////////////////////////////////////////////////////////
	virtual void scrollViewDidScroll(cocos2d::extension::ScrollView* view) override;

	virtual void scrollViewDidZoom(cocos2d::extension::ScrollView* view) override;

	//////////////////////////////////////////////////////////////////////////
	// TableViewDelegate virtual function
	//////////////////////////////////////////////////////////////////////////
	virtual void tableCellTouched(bailin::ui::TableViewEx* table, cocos2d::extension::TableViewCell* cell) override;

	virtual cocos2d::Size cellSizeForTable(bailin::ui::TableViewEx *table) override;

	virtual cocos2d::extension::TableViewCell* tableCellAtIndex(bailin::ui::TableViewEx *table, ssize_t idx) override;

	virtual ssize_t numberOfCellsInTableView(bailin::ui::TableViewEx *table) override;

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

	local tableViewVirtualFunctionsImplement = [[
void $classname::scrollViewDidScroll( ScrollView* view )
{

}

void $classname::scrollViewDidZoom( ScrollView* view )
{

}

Size $classname::cellSizeForTable( TableViewEx *table )
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

ssize_t $classname::numberOfCellsInTableView( TableViewEx *table )
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
