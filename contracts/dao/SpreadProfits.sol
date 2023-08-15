// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import './DaoWallet.sol';

contract SpreadProfits is Ownable{
    address public walletToCollect;
    DaoWallet public daoWallet;
    IERC20 public usdt;

    constructor(
        address _walletToCollect,
        address _daoWallet,
        address _usdtAddress
    ) {
        daoWallet = DaoWallet(_daoWallet);
        walletToCollect = _walletToCollect;
        usdt = IERC20(_usdtAddress);

        transferOwnership(_daoWallet);
    }

    function spreadProfits() external onlyOwner {
        uint256 balance = usdt.balanceOf(address(this));
        require(balance > 0, "No funds to spread");

        uint256 halfBalance = balance / 2;
        usdt.transfer(walletToCollect, halfBalance);

        address[] memory users = daoWallet.getBarnaje().getUsersAvailable();
        require(users.length > 0, "No users available");

        uint256 amountPerUser = halfBalance / users.length;

        for (uint256 i = 0; i < users.length; i++) {
            usdt.transfer(users[i], amountPerUser);
        }
    }

    function changeWalletToCollect(address newOwner) external onlyOwner{
        walletToCollect = newOwner;
    }

    function getWalletToCollect() external view returns (address) {
        return walletToCollect;
    }
}
