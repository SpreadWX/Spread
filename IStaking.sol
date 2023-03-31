pragma solidity ^0.8.0;

interface IStaking {
    function stake(uint256 _amount) external;
    function unstake() external;
    function getStakedBalance(address _address) external view returns (uint256);

    event Staked(address staker, uint amount);
    event Unstaked(address staker, uint amount);
}