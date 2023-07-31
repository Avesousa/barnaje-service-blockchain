// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./Barnaje.sol";
import "./model/TreeNode.sol";

contract TreeHandler is Ownable{

    event addTree(address indexed user, address sponsor);

    Barnaje private barnaje;
    bool daoHasDoneNode;

    constructor(Barnaje _barnaje) {
        barnaje = _barnaje;
        transferOwnership(address(_barnaje));
        initDao();
    }

    mapping(address => TreeNode) private tree;

    function initDao() private {
        address dao = barnaje.getDao();
        tree[dao].parent = address(0);
        tree[dao].upline = new address[](0);
        emit addTree(dao, address(0));
    }

    function addToTree(address _user, address _sponsor) external onlyOwner {
        require(_sponsor != barnaje.getDao() || !daoHasDoneNode, "Dao cannot be a sponsor");

        if(_sponsor == barnaje.getDao()){
            daoHasDoneNode = true;
        }

        // Create and initialize the new node
        tree[_user].parent = _sponsor;
        tree[_user].upline = tree[_sponsor].upline;
        tree[_user].upline.push(_sponsor);

        // BFS to find the first node with available space"
        address[] memory queue = new address[](1);
        queue[0] = _sponsor;
        uint256 front = 0;

        while (front < queue.length) {
            address currentAddress = queue[front];
            front += 1;

            if (tree[currentAddress].leftChild == address(0)) {
                tree[currentAddress].leftChild = _user;
                emit addTree(_user, _sponsor);
                return;
            } 
            if (tree[currentAddress].rightChild == address(0)) {
                tree[currentAddress].rightChild = _user;
                emit addTree(_user, _sponsor);
                return;
            } else {
                // If both spaces are full, we add the children to the queue
                queue[front + 1] = tree[currentAddress].leftChild;
                queue[front + 2] = tree[currentAddress].rightChild;
                front += 2;
            }
        }
    }

    function getTreeNode(address _addr) public view returns (TreeNode memory) {
        return tree[_addr];
    }

}