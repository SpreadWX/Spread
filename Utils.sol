pragma solidity ^0.8.0;
import "./Model.sol";

library utils {

    // 构建分页查询的开始下标和结束下标，数据使用：[start,end)
    function buildStartAndEndForPageData(
        model.PageQueryCondition memory _condition,
        uint _dataTotal
    ) public pure returns(uint start, uint end, uint size) {
        if (_condition.pageIndex < 1) {
            _condition.pageIndex = 1;
        }
        if (_condition.pageSize < 1) {
            _condition.pageSize = 10;
        }
        if (_condition.pageSize > 100) {
            _condition.pageSize = 100;
        }
        if (_condition.isDescend) {
            return buildStartAndEndForPageDataDesc(_condition.pageIndex, _condition.pageSize, _dataTotal);
        }
        return buildStartAndEndForPageDataAsc(_condition.pageIndex, _condition.pageSize, _dataTotal);
    }

    // 升序
    function buildStartAndEndForPageDataAsc(
        uint _pageIndex,
        uint _pageSize,
        uint _dataTotal
    ) private pure returns(uint start, uint end, uint size) {
        require(_pageIndex > 0);
        unchecked {
            // 从 0 开始
            start = (_pageIndex - 1) * _pageSize;
            if (start > _dataTotal) {
                start = _dataTotal;
            }
            // 到 total 结束
            end = start + _pageSize;
            if (end > _dataTotal) {
                end = _dataTotal;
            }
            size = end - start;
        }
        return (start, end, size);
    }

    // 降序
    function buildStartAndEndForPageDataDesc(
        uint _pageIndex,
        uint _pageSize,
        uint _dataTotal
    ) private pure returns(uint start, uint end, uint size) {
        require(_pageIndex > 0);
        unchecked {
            // 从 total 开始
            start = _dataTotal - (_pageIndex - 1) * _pageSize;
            if (start > _dataTotal) {
                start = 0;
            }
            // 到 0 结束
            end = start - _pageSize;
            if (end > start) {
                end = 0;
            }
            size = start - end;
        }
        return (start, end, size);
    }
}