// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract NeverGoon {
    using SafeERC20 for IERC20;
    string public name = "NeverGoon";
    string public symbol = "GOON";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    address public owner;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(uint256 initialSupply) {
        owner = msg.sender;
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0), "Cannot transfer to zero address");
        require(balanceOf[msg.sender] >= value, "Insufficient tokens");
        
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0), "Cannot transfer to zero address");
        require(balanceOf[from] >= value, "Insufficient tokens in source account");
        require(allowance[from][msg.sender] >= value, "Allowance exceeded");
        
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "Cannot approve zero address");
        _approve(msg.sender, spender, value);
        return true;
    }

    function _approve(address _owner, address spender, uint256 value) internal {
    allowance[_owner][spender] = value;
    emit Approval(_owner, spender, value);
}

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0), "Cannot approve zero address");
        require(addedValue > 0, "Added value must be greater than 0");
        _approve(msg.sender, spender, allowance[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0), "Cannot approve zero address");
        require(subtractedValue > 0, "Subtracted value must be greater than 0");
        require(allowance[msg.sender][spender] >= subtractedValue, "Allowance too low");
        _approve(msg.sender, spender, allowance[msg.sender][spender] - subtractedValue);
        return true;
    }

    function burn(uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient tokens to burn");
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
        emit Burn(msg.sender, value);
        emit Transfer(msg.sender, address(0), value);
        return true;
    }

    function burnFrom(address from, uint256 value) public returns (bool) {
        require(balanceOf[from] >= value, "Insufficient tokens to burn");
        require(allowance[from][msg.sender] >= value, "Allowance exceeded");
        
        balanceOf[from] -= value;
        totalSupply -= value;
        allowance[from][msg.sender] -= value;
        
        emit Burn(from, value);
        emit Transfer(from, address(0), value);
        return true;
    }

    function mint(uint256 value) public onlyOwner returns (bool) {
        totalSupply += value;
        balanceOf[owner] += value;
        emit Transfer(address(0), owner, value);
        return true;
    }

    // Safe deposit of external ERC20 tokens using OpenZeppelin's SafeERC20
    function depositExternalToken(address token, uint256 amount) public returns (bool) {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than 0");
        
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        // Additional logic here
        return true;
    }

    // Safe transfer of external ERC20 tokens
    function withdrawExternalToken(address token, address to, uint256 amount) public onlyOwner returns (bool) {
        require(token != address(0), "Invalid token address");
        require(to != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than 0");
        
        IERC20(token).safeTransfer(to, amount);
        return true;
    }

    // Safe approve for external ERC20 tokens
    function approveExternalToken(address token, address spender, uint256 amount) public onlyOwner returns (bool) {
        require(token != address(0), "Invalid token address");
        require(spender != address(0), "Invalid spender address");
        
        IERC20(token).approve(spender, amount);
        return true;
    }
}
