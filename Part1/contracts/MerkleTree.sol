//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract

contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root

    constructor() {
        // [assignment] initialize a Merkle tree of 8 with blank leaves
        for(uint i = 0; i < 15; i++) {
            hashes.push(0);
        }

        uint k = 0;
        for(uint i = 8; i < 15; i++) {
            // console.log(k);
            uint256[2] memory poseidonInput = [hashes[k], hashes[k+1]];
            hashes[i] = PoseidonT3.poseidon(poseidonInput);
            k += 2;
        }
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree
        require(index < 8, "cannot insert to full merkle tree!");

        hashes[index] = hashedLeaf;

        uint8[4] memory depths = [0, 8, 12, 14];

        uint256 offset = index/2;
        uint256 currInd = index;

        for(uint i = 1; i < 4; i++) {
            if(currInd%2 == 0) {
                uint256[2] memory poseidonInput = [hashes[currInd], hashes[currInd+1]];
                hashes[depths[i] + offset] = PoseidonT3.poseidon(poseidonInput);
            } 
            else {
                uint256[2] memory poseidonInput = [hashes[currInd-1], hashes[currInd]];
                hashes[depths[i] + offset] = PoseidonT3.poseidon(poseidonInput);
            }

            currInd = depths[i] + offset;
            // console.log("currInd: ",currInd,hashes[currInd]);
            offset = offset/2; 
        }

        root = hashes[14];
        index = index + 1;
        return root;
    }

    function verify(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input
        ) public view returns (bool) {

        // [assignment] verify an inclusion proof and check that the proof root matches current root
        verifyProof(a, b, c, input);
        // console.log("circuit hash: ", input[0]);
        // console.log("onchain hash", root);

        require(input[0] == root, "Proof Root does not match with the root on chain");

        return true;
    }

    // Not a part of the assignment
    function insertGenericLeaf(bytes memory b) public returns (uint256) {
        uint result = 0;
        for (uint i = 0; i < b.length; i++) {
            uint c = uint8(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 16 + (c - 48);
            }
            if(c >= 65 && c<= 90) {
                result = result * 16 + (c - 55);
            }
            if(c >= 97 && c<= 122) {
                result = result * 16 + (c - 87);
            }
        }

        // console.log("leaf to insert: ", result);
        return insertLeaf(result);
    }
}
