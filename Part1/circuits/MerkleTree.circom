pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/switcher.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    var total_nodes = 2**(n+1)-1;
    var merkle_tree[total_nodes];

    // Position where leaves start
    var end_leaves_pos = 2**n;
    component poseidon_hash[total_nodes];

    for(var i = 0; i < end_leaves_pos; i++) {
        merkle_tree[i] <== leaves[i];
    }

    for(var i = 0; i < end_leaves_pos; i+=2) {

        poseidon_hash[i] = Poseidon(2);

        // Input to 
        poseidon_hash[i].inputs[0] <== merkle_tree[i];

        // Input to compute the hash of the right child
        poseidon_hash[i].inputs[1] <== merkle_tree[i+1];

        // Update the merkle tree at position i with the computed hash
        merkle_tree[i+end_leaves_pos] <== poseidon_hash[i].out[0];
    }

    // Returns the root, it is in the merkle tree at position 0
    root <== merkle_tree[total_nodes-1];
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path

    component switcher[n];
    switcher[0] = Switcher();
    switcher[0].sel <== path_index[0];
    switcher[0].L <== leaf;
    switcher[0].R <== path_elements[0];

    component currHash[n];
    currHash[0] = Poseidon(2);


    currHash[0].inputs[0] <== switcher[0].outL;
    currHash[0].inputs[1] <== switcher[0].outR;
    
    // log(switcher[0].outL);
    // log(switcher[0].outR);
    

    for(var i = 1; i < n; i++) {
        // log(currHash[i-1].out);
        switcher[i] = Switcher();
        switcher[i].sel <== path_index[i];
        switcher[i].L <== currHash[i-1].out;
        // log(currHash[i-1].out);
        switcher[i].R <== path_elements[i];

        currHash[i] = Poseidon(2);

        // log(switcher[i].outL);
        
        // log(switcher[i].outR);
        // log(switcher[i].R);
        currHash[i].inputs[0] <== switcher[i].outL;
        currHash[i].inputs[1] <== switcher[i].outR;
    }
    
    // log(currHash[n-1].out);
    root <== currHash[n-1].out;
}