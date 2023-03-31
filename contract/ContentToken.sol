pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ContentToken is ERC20 {
    address public owner;
    constructor() ERC20("ContentToken", "CT") {
        owner = msg.sender;
        _mint(msg.sender, 100000000 * (10 ** decimals()));
    }

    modifier OnlyOwner() {
        require(msg.sender == owner, "Only owner.");
        _;
    }

    function mint(uint256 amount) public OnlyOwner {
        _mint(msg.sender, amount);
    }

    function burn(uint256 amount) public OnlyOwner {
        _burn(msg.sender, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
}
