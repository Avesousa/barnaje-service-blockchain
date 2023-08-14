// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./Barnaje.sol";
import "./model/TreeNode.sol";

contract TreeHandler is Ownable{

    modifier onlyInFirst24Hours() {
        require(block.timestamp <= deploymentTime + 1 days, "This function can only be called within the first 24 hours after deployment");
        _;
    }

    event addTree(address indexed sponsor, address referred, bool isLeft);

    Barnaje private barnaje; // Barnaje contract interface
    bool daoHasDoneNode; // Flag to check if the DAO has done a node
    uint256 public deploymentTime; // Contract deployment time

    constructor(Barnaje _barnaje) {
        barnaje = _barnaje;
        transferOwnership(address(_barnaje));
        deploymentTime = block.timestamp;
        initDao();
    }

    mapping(address => TreeNode) private tree;

    function initDao() private {
        address dao = barnaje.getDao();
        tree[dao].parent = address(0);
        tree[dao].upline = new address[](0);
        emit addTree(address(0), dao, true);
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

        // BFS to find the first node with available space
        address[] memory queue = new address[](1);
        queue[0] = _sponsor;
        uint256 front = 0;

        while (front < queue.length) {
            address currentAddress = queue[front];

            // Check if direct children are available
            if (tree[currentAddress].leftChild == address(0)) {
                tree[currentAddress].leftChild = _user;
                emit addTree(currentAddress, _user, true);
                return;
            } 
            if (tree[currentAddress].rightChild == address(0)) {
                tree[currentAddress].rightChild = _user;
                emit addTree(currentAddress, _user, false);
                return;
            }

            // The order of these conditions determines the filling order
            if (tree[tree[currentAddress].leftChild].leftChild == address(0)) {
                tree[tree[currentAddress].leftChild].leftChild = _user;
                emit addTree(tree[currentAddress].leftChild, _user, true);
                return;
            }
            if (tree[tree[currentAddress].rightChild].leftChild == address(0)) {
                tree[tree[currentAddress].rightChild].leftChild = _user;
                emit addTree(tree[currentAddress].rightChild, _user, true);
                return;
            }
            if (tree[tree[currentAddress].leftChild].rightChild == address(0)) {
                tree[tree[currentAddress].leftChild].rightChild = _user;
                emit addTree(tree[currentAddress].leftChild, _user, false);
                return;
            }
            if (tree[tree[currentAddress].rightChild].rightChild == address(0)) {
                tree[tree[currentAddress].rightChild].rightChild = _user;
                emit addTree(tree[currentAddress].rightChild, _user, false);
                return;
            }

            // If all spaces are full, we add the children to the queue
            if (tree[currentAddress].leftChild != address(0)) {
                queue = pushAddress(queue, tree[currentAddress].leftChild);
            }
            if (tree[currentAddress].rightChild != address(0)) {
                queue = pushAddress(queue, tree[currentAddress].rightChild);
            }

            front += 1;
        }
    }

    function pushAddress(address[] memory arr, address addr) private pure returns (address[] memory) {
        address[] memory newArr = new address[](arr.length + 1);
        for (uint256 i = 0; i < arr.length; i++) {
            newArr[i] = arr[i];
        }
        newArr[arr.length] = addr;
        return newArr;
    }

    function getTreeNode(address _addr) public view returns (TreeNode memory) {
        return tree[_addr];
    }

    function pushToTreeManually(address _user, address _parent, address leftChild, address rightChild) external onlyOwner onlyInFirst24Hours {
        tree[_user].upline = tree[_parent].upline;
        tree[_user].upline.push(_parent);
        tree[_user].parent = _parent;
        tree[_user].leftChild = leftChild;
        tree[_user].rightChild = rightChild;
        if(leftChild != address(0)){
            emit addTree(_user, leftChild, true);
        }
        if(rightChild != address(0)){
            emit addTree(_user, rightChild, false);
        }
    }

}