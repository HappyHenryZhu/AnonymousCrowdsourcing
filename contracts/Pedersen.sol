// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Utils.sol";

/**
 * Author: Nan Wang
 * Date: 12-01-2021
 **/

struct ZkpCm {
    uint256 c;
    uint256 cprime;
    uint256 beta;
    uint256 zx;
    uint256 zr;
}


struct ZkpZeroOne {
    uint256 ca;
    uint256 cb;
    int256 f;
    int256 za;
    int256 zb;
}

struct Zkp1N1 {
    uint256[] cs;
    ZkpZeroOne[] zkps;
    uint256[] cls;
    uint256[] cas;
    uint256[] cbs;
    uint256[] cds;
}

struct Zkp1N2 {
    int256[] fs;
    int256[] zas;
    int256[] zbs;
    int256 zd;
}

contract Pedersen {

    using SafeMath for uint256;
    using SafeMath for int256;

    uint256 private g;

    uint256 private h;

    uint256 private q;

    uint256 private k;


    constructor(uint256 _g, uint256 _h, uint256 _q, uint256 _k) {
        g = _g;
        h = _h;
        q = _q;
        k = _k;
    }

    function commitToWithNoRand(uint256 a)
        public
        view
        returns (uint256)
    {
        return g.modPow(a, q);
    }

    function commitTo(uint256 v, uint256 r)
        public
        view
        returns (uint256)
    {
        return mulmod(g.modPow(v, q), h.modPow(r, q), q);
    }

    function commitTo(int256 v, int256 r)
        public
        view
        returns (uint256)
    {
        return mulmod(g.modPow(v, q), h.modPow(r, q), q);
    }

    function homoAdd(uint256 c1, uint256 c2)
        public
        view
        returns (uint256)
    {
        return mulmod(c1, c2, q);
    }

    function homoAdd(uint256[] memory cs)
        public
        view
        returns (uint256)
    {
        uint256 sum = 1;
        for(uint i=0;i<cs.length;i++){
            sum = mulmod(sum, cs[i], q);
        }

        return sum.mod(q);
    }

    function homoSub(uint256 c1, uint256 c2)
        public
        view
        returns (uint256)
    {
        int256 neg = -1;
        return mulmod(c1, homoMul(c2, neg), q);
    }

    function homoMul(uint256 c, uint256 e)
        public
        view
        returns (uint256)
    {
        return c.modPow(e, q);
    }

    function homoMul(uint256 c, int256 e)
        public
        view
        returns (uint256)
    {
        return c.modPow(e, q);
    }

    /////////ZkpCm////////
    function verifyZkpCm(ZkpCm memory zkp)
        public view returns(bool)
    {   
            uint256 c = zkp.c;
            uint256 cprime = zkp.cprime;
            uint256 beta = zkp.beta;
            uint256 zx = zkp.zx;
            uint256 zr = zkp.zr;


        //uint256 beta = uint256(keccak256(abi.encodePacked(cprime))).mod(k);
        uint256 ret1 = mulmod(g.modPow(zx, q),h.modPow(zr, q),q);
        uint256 ret2 = homoAdd(cprime, homoMul(c,beta));
        if (ret1 == ret2){
            return true;
        }else{
            return false;
        }
        
    }

    function verifyZeroOne(uint256 cm, ZkpZeroOne memory zkp)
        public view
    {
        uint256 ca = zkp.ca;
        uint256 cb = zkp.cb;
        int256 f = zkp.f;
        int256 za = zkp.za;
        int256 zb = zkp.zb;

        uint256 beta = uint256(keccak256(abi.encodePacked(cm, ca, cb))).mod(k);

        uint256 ret1_1 = commitTo(f, za);
        uint256 ret1_2 = homoAdd(homoMul(cm, beta), ca);

        uint256 ret2_1 = commitTo(0, zb);
        uint256 ret2_2 = homoAdd(homoMul(cm, int256(beta) - f), cb);

        assert (ret1_1 == ret1_2 && ret2_1 == ret2_2);
    }

    function checkZeroOneZkp(uint256[] memory cls, ZkpZeroOne[] memory zkps)
            internal view
    {
        for(uint i=0;i<cls.length;i++) {
            verifyZeroOne(cls[i], zkps[i]);
        }
    }

    function checkConstraint1(uint256[] memory cls, uint256[] memory cas, int256[] memory fs, int256[] memory zas, int256 betaWithSign, uint8 nbits)
        internal view
    {
        for(uint i=0;i<nbits;i++) {
            int256 f = fs[i];
            uint256 ret11 = homoAdd(homoMul(cls[i], betaWithSign), cas[i]);
            uint256 ret12 = commitTo(f, zas[i]);

            assert(ret11 == ret12);
        }
    }

    function checkConstraint2(uint256[] memory cls, uint256[] memory cbs, int256[] memory fs, int256[] memory zbs, int256 betaWithSign, uint8 nbits)
        internal view
    {
        for(uint i=0;i<nbits;i++) {
            int256 f = fs[i];

            uint256 ret21 = homoAdd(homoMul(cls[i], betaWithSign - f), cbs[i]);
            uint256 ret22 = commitTo(0, zbs[i]);

            assert(ret21 == ret22);
        }
    }

    function verifyZkpOneOfMany(Zkp1N1 memory zkp1, Zkp1N2 memory zkp2, uint8 nbits)
        public
        view
        returns(bool)
    {
        uint256[] memory cs = zkp1.cs;
        uint256[] memory cls = zkp1.cls;
        uint256[] memory cds = zkp1.cds;
        int256[] memory fs = zkp2.fs;
        int256 zd = zkp2.zd;

        checkZeroOneZkp(cls, zkp1.zkps);

        uint256 beta = computeBeta(zkp1);
        int256 betaWithSign = int256(beta);

        checkConstraint1(cls, zkp1.cas, fs, zkp2.zas, betaWithSign, nbits);
        checkConstraint2(cls, zkp1.cbs, fs, zkp2.zbs, betaWithSign, nbits);

        uint256 ret31 = 1;
        for(uint i=0;i<cs.length;i++) {
            int256 fprod = 1;
            for(uint8 j=0;j<nbits;j++) {
                if(bit(i, j) == 1) {
                    fprod = fprod * fs[j];
                } else {
                    fprod = fprod * (betaWithSign - fs[j]);
                }
            }

            ret31 = homoAdd(ret31, homoMul(cs[i], fprod));
        }

        for(uint i=0;i<nbits;i++) {
            ret31 = homoAdd(ret31, homoMul(cds[i], -(betaWithSign**i)));
        }

        uint256 ret32 = commitTo(0, zd);

        if (ret31 == ret32){
            return true;
        }else{
            return false;
        }
    }

    function bit(uint self, uint8 index) public pure returns (uint8) {
        return uint8(self >> index & 1);
    }

    function computeBeta(Zkp1N1 memory zkp)
        public view
        returns (uint256)
    {
        uint256[] memory cs = zkp.cs;
        uint256[] memory cls = zkp.cls;
        uint256[] memory cas = zkp.cas;
        uint256[] memory cbs = zkp.cbs;
        uint256[] memory cds = zkp.cds;

        uint256 sum = 0;
        for(uint i=0;i<cs.length;i++) {
            sum = addmod(sum, cs[i], q);
        }
        for(uint i=0;i<cls.length;i++) {
            sum = addmod(sum, cls[i], q);
        }
        for(uint i=0;i<cas.length;i++) {
            sum = addmod(sum, cas[i], q);
        }
        for(uint i=0;i<cbs.length;i++) {
            sum = addmod(sum, cbs[i], q);
        }
        for(uint i=0;i<cds.length;i++) {
            sum = addmod(sum, cds[i], q);
        }

        return uint256(keccak256(abi.encodePacked(sum))).mod(k);
    }

    function verifyZkpOneOfManyWithX(uint256 serialNo, Zkp1N1 memory zkp1, Zkp1N2 memory zkp2, uint8 nbits) public view returns(bool){
        uint256[] memory cs = zkp1.cs;
        for(uint i=0; i < cs.length; i++){
            cs[i] = homoAdd(cs[i], (g.modPow(serialNo.negate(), q)));
        }
        return verifyZkpOneOfMany(zkp1, zkp2, nbits);
    }
}

