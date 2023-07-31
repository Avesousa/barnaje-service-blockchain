// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct TreeNode {
    address parent;
    address leftChild;
    address rightChild;
    address[] upline;
}