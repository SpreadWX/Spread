pragma solidity ^0.8.0;

import "./Model.sol";

interface IContentPool {
    // 内容发布事件
    event PublishContent(address _promoter, uint256 _contentId, uint256 _budget);
    // 内容申请事件
    event RequestContent(address _broadcaster, uint256 _contenId);
    // 领取内容奖励事件
    event Claim(address _broadcaster, uint256 _contentId, uint256 _amount);

    // 发布内容
    function publishContent(model.PublishContentDto memory dto) external;

    // 获取内容详情
    function getContent(uint256 _contentId) external view returns (model.Content memory _content);

    // 申请广播内容
    function requestBroadcast(uint256 _contentId) external;

    // 领取奖励
    function claim(uint256 _contentId) external;
}
