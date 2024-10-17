// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../libraries/LibDiamond.sol";

contract ERC20Facet is ERC20 {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.erc20.storage");

    struct ERC20Storage {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 totalSupply;
    }

    function erc20Storage() internal pure returns (ERC20Storage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    constructor() ERC20("DiamondToken", "DTK") {}

    function name() public pure override returns (string memory) {
        return "DiamondToken";
    }

    function symbol() public pure override returns (string memory) {
        return "DTK";
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return erc20Storage().totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return erc20Storage().balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return erc20Storage().allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = erc20Storage().allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        ERC20Storage storage es = erc20Storage();
        uint256 senderBalance = es.balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            es.balances[sender] = senderBalance - amount;
        }
        es.balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        erc20Storage().allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        ERC20Storage storage es = erc20Storage();
        es.totalSupply += amount;
        es.balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        ERC20Storage storage es = erc20Storage();
        uint256 accountBalance = es.balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            es.balances[account] = accountBalance - amount;
        }
        es.totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
}