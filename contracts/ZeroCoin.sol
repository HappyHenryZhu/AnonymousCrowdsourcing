// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Pedersen.sol";

contract ZeroCoin {

    uint private k = 1173792922; 
    uint private q = 29645808988800697353566862307331691561207478437311896149463650348773872465515;
    uint private g = 2090583907;
    uint private h = 642996076579571851939547582363769362446679167969816015137470108219624530351;
	Pedersen private pedersen;

	event CreditsReceived(address addr, uint value);

	uint[] public mintedCoins;
	uint[] public spentCoins;
	constructor() payable{
		pedersen = new Pedersen(g,h,q,k);
		//require (msg.sender != tx.origin, "Only smart contracts are allowed to initiate this call");
	}

	//mint a new zerocoin with an ether
	function mint(uint coin) public payable{
		require (msg.value == 1 ether, "need to mint a coin with 1 ether");
		mintedCoins.push(coin);
	}

	//burn a zerocoin and redeem back to an ether
	function spendnRedeem(uint serialNo, Zkp1N1 memory zkp1, Zkp1N2 memory zkp2, uint8 nbits) public{
		require(pedersen.verifyZkpOneOfMany(zkp1, zkp2, nbits));
		for(uint i = 0; i < spentCoins.length; i++){
			require(spentCoins[i] != serialNo, "The coin has been spent");
		}
		spentCoins.push(serialNo);
		payable(msg.sender).transfer(1 ether);
	}

	//burn an old zerocoin and mint a new one
	function spendnRemint(uint serialNo, Zkp1N1 memory zkp1, Zkp1N2 memory zkp2, uint8 nbits, uint newCoin) public{
		require(pedersen.verifyZkpOneOfMany(zkp1, zkp2, nbits));
		for(uint i = 0; i < spentCoins.length; i++){
			require(spentCoins[i] != serialNo);
		}
		spentCoins.push(serialNo);
		mintedCoins.push(newCoin);
	}

    //fallback function
    receive() payable external{
        emit CreditsReceived(msg.sender, msg.value);
    }

}