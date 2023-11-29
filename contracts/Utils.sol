// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./SafeMath.sol";

/**
 * Author: Nan Wang
 * Date: 13-01-2021
 **/
library Utils {

    using SafeMath for int256;

    function addressIsIn(address target, address[] memory addresses)
        public
        pure
        returns (bool)
    {
        for(uint i=0;i<addresses.length;i++) {
            if(target == addresses[i]){
                return true;
            }
        }

        return false;
    }

    function getIndexOf(address target, address[] memory addresses)
        public
        pure
        returns (uint)
    {
        uint idx = 0;
        for(uint i=0;i<addresses.length;i++){
            if(addresses[i] == target) {
                idx = i;
                break;
            }
        }

        return idx;
    }

    function sumOf(int256[] memory list)
        public
        pure
        returns (int256)
    {
        int256 ret = 0;

        for(uint i=0;i<list.length;i++) {
            ret = ret.add(list[i]);
        }

        return ret;
    }
}
