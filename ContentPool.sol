// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Model.sol";
import "./Utils.sol";
import "./IContentPool.sol";
import "./IStaking.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// 内容池合约
contract ContentPool is IContentPool, IStaking {

    //    ================== ContentPool =================
    // 内容存储池
    model.Content[] public contents;
    // 内容自增id，每成功添加一条内容值+1
    uint256 public contentId;
    // 发送者记录池，存储发送者发送过的所有广告的id，用于方便查找
    mapping(address => uint256[]) public promoterContentIds;
    // 接收者记录池，存储接收者接收过的所有广告的id，用于方便查找
    mapping(address => uint256[]) public broadcasterContentIds;
    // 内容申请记录池，记录每一个内容对应的所有广播参与者及其奖励领取情况
    mapping(uint256 => model.BroadcasterClaimed[]) public broadcastersForContent;

    //    ================== Token Manager =================
    address owner;
    // 资产合约
    IERC20 public token;
    // 最小内容广播预算
    uint256 public minBudget;
    // 质押金额
    uint256 public stakingAmount;
    // 记录每个地址的质押金额
    mapping (address => uint256) public stakedBalances;

    //    ================== Tag Manager =================
    string[] public tags;

    //    ================== Tag Manager =================
    // Todo

    //    ================== RequestQualification =================
    // 申请条件自增id，每成功添加一条值+1
    uint256 public requestQualificationId;
    model.RequestQualification[] public requestQualifications;

    //    ================== ClaimQualification =================
    // 限定条件自增id，每成功添加一条值+1
    uint256 public claimQualificationId;
    model.ClaimQualification[] public claimQualifications;

    constructor(address _token, uint256 _minBudget, uint256 _stakingAmount) {
        owner = msg.sender;
        token = IERC20(_token);
        minBudget = _minBudget;
        stakingAmount = _stakingAmount;
    }

    modifier OnlyOwner() {
        require(msg.sender == owner, "Only owner.");
        _;
    }

    //    ================== Token Manager =================
    function stake(uint256 _amount) public override  {
        require(_amount == stakingAmount, "Amount should be equal to the staking amount");
        require(token.balanceOf(msg.sender) >= _amount, "Not enough balance to stake");
        require(token.allowance(msg.sender, address(this)) >= _amount, "Token allowance not set");
        // require(lastStakedTime[msg.sender] < endTime, "Staking period has ended");
        require(stakedBalances[msg.sender] == 0, "Staker can only stake once");

        // lastStakedTime[msg.sender] = block.timestamp;
        stakedBalances[msg.sender] = _amount;

        token.transferFrom(msg.sender, address(this), _amount);

        emit Staked(msg.sender, _amount);
    }

    function unstake() public override {
        require(stakedBalances[msg.sender] > 0, "Nothing to withdraw");
        // require(block.timestamp >= endTime, "Staking period has not ended yet");

        uint256 amount = stakedBalances[msg.sender];
        stakedBalances[msg.sender] = 0;

        token.transfer(msg.sender, amount);

        emit Unstaked(msg.sender, amount);
    }

    function getStakedBalance(address _staker) public view override returns (uint256) {
        return stakedBalances[_staker];
    }

    function setMinBudget(uint256 _minBudget) public OnlyOwner {
        minBudget = _minBudget;
    }

    function setStakingAmount(uint256 _stakingAmount) public OnlyOwner {
        stakingAmount = _stakingAmount;
    }

    //    ================== ContentPool =================
    // 发布内容
    function publishContent(model.PublishContentDto memory _dto) public override {
        // 检查预算
        require(_dto.contentDto.budget >= minBudget, "Insufficient budget");
        require(token.balanceOf(msg.sender) >= _dto.contentDto.budget, "Not enough balance to publish");
        require(token.allowance(msg.sender, address(this)) >= _dto.contentDto.budget, "Token allowance not set");
        require(_dto.contentDto.total >= 1, "Total must be greater than or equal to 1");
        contentId++;

        // 添加申请条件
        if (_dto.contentDto.typ == model.ContentType.RESTRICTED) {
            requestQualificationId++;
            requestQualifications.push(
                model.RequestQualification(
                    requestQualificationId,
                    _dto.requestDto.flows,
                    _dto.requestDto.tags
                )
            );
        }

        // 添加领取条件
        claimQualificationId++;
        claimQualifications.push(model.ClaimQualification(
                claimQualificationId,
                _dto.claimDto.likes,
                _dto.claimDto.comments,
                _dto.claimDto.mirrors
            ));

        // 添加内容
        model.Content memory newContent;
        newContent.id = contentId;
        newContent.promoter = msg.sender;
        newContent.headline = _dto.contentDto.headline;
        newContent.description = _dto.contentDto.description;
        newContent.typ = _dto.contentDto.typ;
        newContent.status = _dto.contentDto.status;
        newContent.budget = _dto.contentDto.budget;
        newContent.url = _dto.contentDto.url;
        newContent.previewUrl = _dto.contentDto.previewUrl;
        newContent.total = _dto.contentDto.total;
        newContent.createTime = block.timestamp;
        model.ContentData memory data;
        data.balance = newContent.budget;
        data.requestQualificationId = requestQualificationId;
        data.claimQualificationId = claimQualificationId;
        newContent.data = data;
        contents.push(newContent);

        // 记录 sender 发布了该内容
        promoterContentIds[newContent.promoter].push(contentId);
        // 将预算 token 转移到 tokenManager 合约中
        token.transferFrom(msg.sender, address(this), newContent.budget);
        emit PublishContent(newContent.promoter, contentId, newContent.budget);
    }

    // 获取内容详情
    function getContent(uint256 _contentId) public view override returns (model.ContentVo memory _content) {
        require(_contentId > 0 && _contentId <= contents.length, "Invalid content id");
        model.Content memory content = contents[_contentId - 1];
        _content.content = content;
        if (content.data.requestQualificationId > 0) {
            model.RequestQualification memory requestQualification = requestQualifications[content.data.requestQualificationId - 1];
            _content.requestQualification = requestQualification;
        }
        if (content.data.claimQualificationId > 0) {
            model.ClaimQualification memory claimQualification = claimQualifications[content.data.claimQualificationId - 1];
            _content.claimQualification =claimQualification;
        }
        return _content;
    }

    // 分页查询内容数据
    function getContents(model.PageQueryCondition memory condition) public view returns(uint total, model.Content[] memory cs) {
        total = contentId;
        (uint start, uint end, uint size) = utils.buildStartAndEndForPageData(condition, total);
        cs = new model.Content[](size);
        if (condition.isDescend) {
            int st = int(start);
            int ed = int(end);
            st -= 1;
            ed -= 1;
            for (int i = st; i > ed; i --) {
                cs[uint(st-i)] = contents[uint(i)];
            }
        } else {
            for (uint i = start; i < end; i ++) {
                cs[i-start] = contents[i];
            }
        }
        return (total, cs);
    }

    // 分页查询指定用户发布的内容数据
    function getPublishContentsForUser(
        address _user,
        model.PageQueryCondition memory condition
    )
    public view
    returns(uint total, model.Content[] memory cs)
    {
        total = promoterContentIds[_user].length;
        (uint start, uint end, uint size) = utils.buildStartAndEndForPageData(condition, total);
        cs = new model.Content[](size);
        if (condition.isDescend) {
            int st = int(start);
            int ed = int(end);
            st -= 1;
            ed -= 1;
            for (int i = st; i > ed; i --) {
                cs[uint(st-i)] = contents[promoterContentIds[_user][uint(i)] - 1];
            }
        } else {
            for (uint i = start; i < end; i ++) {
                cs[i-start] = contents[promoterContentIds[_user][i] - 1];
            }
        }
        return (total, cs);
    }

    // 分页查询指定用户接收的内容数据
    function getReceiveContentsForUser(
        address _user,
        model.PageQueryCondition memory condition
    )
    public view
    returns(uint total, model.Content[] memory cs)
    {
        total = broadcasterContentIds[_user].length;
        (uint start, uint end, uint size) = utils.buildStartAndEndForPageData(condition, total);
        cs = new model.Content[](size);
        if (condition.isDescend) {
            int st = int(start);
            int ed = int(end);
            st -= 1;
            ed -= 1;
            for (int i = st; i > ed; i --) {
                cs[uint(st-i)] = contents[broadcasterContentIds[_user][uint(i)] - 1];
            }
        } else {
            for (uint i = start; i < end; i ++) {
                cs[i-start] = contents[broadcasterContentIds[_user][i] - 1];
            }
        }
        return (total, cs);
    }

    // 获取指定内容中的所有参与的广播者及其奖励领取情况
    function getBroadcasterByContentId(
        uint256 _contentId,
        model.PageQueryCondition memory condition
    )
    public view
    returns(uint total, model.BroadcasterClaimed[] memory broadcasters)
    {
        total = broadcastersForContent[_contentId].length;
        (uint start, uint end, uint size) = utils.buildStartAndEndForPageData(condition, total);
        broadcasters = new model.BroadcasterClaimed[](size);
        if (condition.isDescend) {
            int st = int(start);
            int ed = int(end);
            st -= 1;
            ed -= 1;
            for (int i = st; i > ed; i --) {
                broadcasters[uint(st-i)] = broadcastersForContent[_contentId][uint(i)];
            }
        } else {
            for (uint i = start; i < end; i ++) {
                broadcasters[i-start] = broadcastersForContent[_contentId][uint(i)];
            }
        }
        return (total, broadcasters);
    }

    // 申请参与内容广播
    function requestBroadcast(uint256 _contentId) public override {
        // 验证质押
        require(getStakedBalance(msg.sender) >= stakingAmount, "Invalid broadcaster");
        // 验证内容合法性
        require(_contentId > 0 && _contentId <= contents.length, "Invalid content id");
        // 验证重复申请
        bool requested = false;
        for (uint256 i = 0; i < broadcastersForContent[_contentId].length; i ++) {
            if (broadcastersForContent[_contentId][i].broadcaster == msg.sender) {
                requested = true;
            }
        }
        require(!requested, "Content has already been requested");

        // 验证内容
        model.Content storage content = contents[_contentId - 1];
        require(content.status == model.ContentStatus.ENABLE, "This content is currently not available.");
        if (content.typ == model.ContentType.RESTRICTED) {
            // model.RequestQualification storage qualification = qualifications[content.requestQualificationId];
            // Todo：验证申请条件
        }
        content.data.requestedCnt ++;
        // 记录 sender 参与了该内容
        broadcastersForContent[_contentId].push(model.BroadcasterClaimed(msg.sender, false));
        // 记录 sender 接收了该内容
        broadcasterContentIds[msg.sender].push(_contentId);
        emit RequestContent(msg.sender, _contentId);
    }

    // 领取奖励
    function claim(uint256 _contentId) public override {
        // 验证质押
        require(getStakedBalance(msg.sender) >= stakingAmount, "Invalid broadcaster");
        // 验证内容合法性
        require(_contentId > 0 && _contentId <= contents.length, "Invalid content id");
        // 验证 sender 已经申请了该内容，且没有领取过奖励
        bool requested = false;
        bool claimed = false;
        uint256 index = 0;
        for (uint256 i = 0; i < broadcastersForContent[_contentId].length; i ++) {
            if (broadcastersForContent[_contentId][i].broadcaster == msg.sender) {
                requested = true;
                claimed = broadcastersForContent[_contentId][i].claimed;
                index = i;
            }
        }
        require(requested, "Content has not requested");
        require(!claimed, "Already claimed");
        // 验证内容
        model.Content storage content = contents[_contentId - 1];
        require(content.status == model.ContentStatus.ENABLE, "This content is currently not available.");
        // Todo: 验证完成结果
        require(content.status == model.ContentStatus.ENABLE, "This content is currently not available.");
        content.data.completedCnt ++;
        if (content.data.completedCnt == content.total) {
            content.status = model.ContentStatus.COMPLETED;
        }

        // 记录为已经领取
        broadcastersForContent[_contentId][index].claimed = true;
        uint256 award = content.budget / content.total;
        // 更新该内容的预算余额
        content.data.balance -= award;
        // 发放奖励
        token.transfer(msg.sender, award);

        emit Claim(msg.sender, _contentId, award);
    }
}