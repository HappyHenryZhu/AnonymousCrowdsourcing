// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * Author: Nan Wang
 * Date: 12-01-2021
 **/
library SafeMath {

    function add(uint256 a, uint256 b)
        public
        pure
        returns (uint256)
    {
        uint256 c;
        assembly {
            c := add(a, b)
        }

        require(c - a == b, "SafeMath: addition overflow");

        return c;
    }

    function add(int256 a, int256 b)
        public
        pure
        returns (int256)
    {
        int256 c;
        assembly {
            c := add(a, b)
        }

        require(c - a == b, "SafeMath: addition overflow");

        return c;
    }

    function mul(uint256 a, uint256 b)
        public
        pure
        returns (uint256)
    {
        if (a == 0 || b == 0) {
            return 0;
        }

        uint256 c;
        assembly {
            c := mul(a, b)
        }

        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function mul(int256 a, int256 b)
        public
        pure
        returns (int256)
    {
        if (a == 0 || b == 0) {
            return 0;
        }

        int256 c;
        assembly {
            c := mul(a, b)
        }

        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function mul(uint256 a, int256 b)
        public
        pure
        returns (int256)
    {
       return mul(int256(a), b);
    }

    function mod(uint256 a, uint256 b)
        public
        pure
        returns (uint256)
    {
        require(b != 0, "SafeMath: modulo by zero");

        uint256 c;
        assembly {
            c := mod(a, b)
        }

        return c;
    }

    function log2(uint x)
        internal
        pure
        returns (uint y)
    {
       assembly {
            let arg := x
            x := sub(x,1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
            mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
            mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
            mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
            mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
            mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
            mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
            mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
            mstore(0x40, add(m, 0x100))
            let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let shift := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m,sub(255,a))), shift)
            y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
        }
    }

    function pow(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if(a == 0){
            return 0;
        } else if(b == 0){
            return 1;
        }

        uint256 d = log2(a);

        require(d * b < 256, "SafeMath: power overflow");

        uint256 y;
        assembly {
            y := exp(a, b)
        }

        return y;
    }

    function negate(uint256 a)
        internal
        pure
        returns (int256)
    {
        return negate(int256(a));
    }

    function negate(int256 a)
        internal
        pure
        returns (int256)
    {
        return -a;
    }

    function abs(int256 a)
        internal
        pure
        returns (uint256)
    {
        if(a > 0) {
            return uint256(a);
        } else if(a < 0) {
            return uint256(-a);
        }

        return 0;
    }

    function modInv(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if(a > b) {
            a = a % b;
        }

        int256 t1 = 0;
        int256 t2 = 1;

        uint256 r1 = b;
        uint256 r2 = a;
        uint256 q;
        while (r2 != 0) {
            q = r1 / r2;
            (t1, t2, r1, r2) = (t2, t1 - int256(q) * t2, r2, r1 - q * r2);
        }
        if (t1 < 0) {
            return (b - abs(t1));
        }

        return uint256(t1);
    }

    function floorMod(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        require (b != 0);

        int256 c = a / b;
        if(c < 0 && a % b != 0){
            c -= 1;
        }

        return a - c * b;
    }

    /**
     * Gas-intensive
     **/
    function modInv(int256 a, int256 b)
        public
        pure
        returns (int256)
    {
        int start = (b - 1) / a;

        for(int i=start; i< b;i++) {
            if (floorMod(a*i, b) == 1) return i;
        }

        return -1;
    }

    // a - b = c;
    function submod(uint256 a, uint256 b, uint256 q)
        internal
        pure
        returns (uint256)
    {
        uint256 a_nn;

        if(a > b) {
            a_nn = a;
        } else {
            a_nn = a + q;
        }

        return addmod(a_nn - b, 0, q);
    }

    function modPow(uint256 _base, int256 _exponent, uint256 _modulus)
        internal
        view
        returns (uint256)
    {
        if(_exponent >= 0) {
            return modPow(_base, uint256(_exponent), _modulus);
        } else {
            return modPow(modInv(_base, _modulus), abs(_exponent), _modulus);
        }
    }

    function modPow(uint256 _base, uint256 _exponent, uint _exponentSign, uint256 _modulus)
        internal
        view
        returns (uint256)
    {
        if(_exponentSign > 0) {
            return modPow(_base, _exponent, _modulus);
        } else {
            return modPow(modInv(_base, _modulus), _exponent, _modulus);
        }
    }

    function modPow(uint256 _base, uint256 _exponent, uint256 _modulus)
        internal
        view
        returns (uint256)
    {
        bool success;
        uint256[1] memory output;
        uint[6] memory input;
        input[0] = 0x20;        // baseLen = new(big.Int).SetBytes(getData(input, 0, 32))
        input[1] = 0x20;        // expLen  = new(big.Int).SetBytes(getData(input, 32, 32))
        input[2] = 0x20;        // modLen  = new(big.Int).SetBytes(getData(input, 64, 32))
        input[3] = _base;
        input[4] = _exponent;
        input[5] = _modulus;
        assembly {
            success := staticcall(sub(gas(), 2000), 5, input, 0xc0, output, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return output[0];
    }
}
