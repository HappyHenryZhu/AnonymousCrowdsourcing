const Web3 = require("web3");
const lib = require("./lib.js");
const AnonymousCrowdsourcing = require("../build/contracts/AnonymousCrowdsourcing.json");
const ZeroCoin = require("../build/contracts/ZeroCoin.json");
const Pedersen = require("../build/contracts/Pedersen.json");


var web3, gasPrice, account, zc, cs, pd;

// const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:7545"));
window.ethereum.on('accountsChanged', (accounts) => {
  // account = accounts[0];
  connectWallet();
});

window.ethereum.on('chainChanged', (chainId) => {
  location.reload();

});

const init = async () => {

  if (typeof window !== "undefined" && typeof window.ethereum !== "undefined") {
    web3 = new Web3(window.ethereum);
    gasPrice = await web3.eth.getGasPrice();
    console.log("gasPrice", gasPrice);
  } else {
    alert ("Please install Metamask");
    return;
  }

  zc = new web3.eth.Contract(ZeroCoin.abi, ZeroCoin.networks[5777].address);
  cs = new web3.eth.Contract(AnonymousCrowdsourcing.abi, AnonymousCrowdsourcing.networks[5777].address);
  pd = new web3.eth.Contract(Pedersen.abi, Pedersen.networks[5777].address);

  const zcAddr = lib.createElementFromString(
    `<p> Address : ${zc.options.address} </p>`);
  const csAddr = lib.createElementFromString(
    `<p> Address : ${cs.options.address} </p>`);
  document.getElementById('zcaddr').replaceWith(zcAddr);
  document.getElementById('csaddr').replaceWith(csAddr);
  document.getElementById('connect').addEventListener('click', connectWallet);

  document.getElementById('sensingDataBtn').addEventListener('click', submitSensingData);
  document.getElementById('proveBtn').addEventListener('click', proveSubmittedData);
  document.getElementById('etherBtn').addEventListener('click', getEtherBack);
  document.getElementById('resultBtn').addEventListener('click', getAggregatedResult);
  document.getElementById('spendnRedeemBtn').addEventListener('click', spendnRedeem);
  document.getElementById('spendnRemintBtn').addEventListener('click', spendnRemint);

}


const connectWallet = async () => {
  try {
    await window.ethereum.request({ method: "eth_requestAccounts" })
    const accounts = await web3.eth.getAccounts();
    account = accounts[0];
  } catch(err) {
    alert(err.message);
    return;
  }

  const btn = document.getElementById('connect');
  const acc = lib.createElementFromString(
    "<b class='is-pulled-right'>Account: " + account + "</b>"
  );
  btn.nextElementSibling.replaceWith(acc);
}

const submitSensingData = async() => {
  if (account == null) {
    alert("Please connect wallet first");
    return;
  }

  const cm1 = lib.parseNestedTuple(document.getElementById('cm1').value);
  const cm2 = lib.parseNestedTuple(document.getElementById('cm2').value);

  try {
    const tx = await cs.methods.submitSensingData(cm1, cm2).send(
      {from: account, gas: 6721975, gasPrice: gasPrice, value: 1e18});
  } catch(err) {
    alert(err.message);
    return;
  }

  alert("Sensing Data Submitted");

}

const proveSubmittedData = async() => {
  if (account == null) {
    alert("Please connect wallet first");
    return;
  }

  const obs = lib.parseNestedTuple(document.getElementById('obs').value);
  const zkp1obs = lib.parseNestedTuple(document.getElementById('zkp1obs').value);
  const zkp2obs = lib.parseNestedTuple(document.getElementById('zkp2obs').value);
  const nbitsobs = lib.parseNestedTuple(document.getElementById('nbitsobs').value);
  const q = lib.parseNestedTuple(document.getElementById('q').value);
  const zkp1q = lib.parseNestedTuple(document.getElementById('zkp1q').value);
  const zkp2q = lib.parseNestedTuple(document.getElementById('zkp2q').value);
  const nbitsq = lib.parseNestedTuple(document.getElementById('nbitsq').value);
  const cms = lib.parseNestedTuple(document.getElementById('cms').value);
  const cmqprime = lib.parseNestedTuple(document.getElementById('cmqprime').value);

  try {
    const tx = await cs.methods.proveSubmittedData(
      obs, zkp1obs, zkp2obs, nbitsobs, q, zkp1q, zkp2q, nbitsq, cms, cmqprime).send(
      {from: account, gas: 6721975, gasPrice: gasPrice});
  } catch(err) {
    alert(err.message);
    return;
  }
  
  alert("Verified Submitted Data");
}

const getEtherBack = async() => {
  if (account == null) {
    alert("Please connect wallet first");
    return;
  }

  const qprime = lib.parseNestedTuple(document.getElementById('qprime').value);
  const zkp1qprime = lib.parseNestedTuple(document.getElementById('zkp1qprime').value);
  const zkp2qprime = lib.parseNestedTuple(document.getElementById('zkp2qprime').value);
  const nbitsqprime = lib.parseNestedTuple(document.getElementById('nbitsqprime').value);

  try {
    const tx = await cs.methods.getEtherBack(
      qprime, zkp1qprime, zkp2qprime, nbitsqprime
    ).send(
      {from: account, gas: 6721975, gasPrice: gasPrice});
  } catch(err) {
    alert(err.message);
    return;
  }

  alert("Ether Back");
}

const getAggregatedResult = async() => {
  if (account == null) {
    alert("Please connect wallet first");
    return;
  }

  var result;

  try {
    const tx = await cs.methods.getAggregatedResults().send(
      {from: account, gas: 6721975, gasPrice: gasPrice});
    result = await get_transaction_result(tx.transactionHash, web3.eth);
    
  } catch(err) {
    alert(err.message);
    return;
  }

  const button = document.getElementById('resultBtn');
  button.nextElementSibling.replaceWith(
    lib.createElementFromString(
      `<p> Result : ${result} </p>`
    )
  );
  console.log(result);

}

async function get_transaction_result(txn_hash, provider){
  const a = await provider.getTransaction(txn_hash);
  try {
      let r = await provider.call(a, a.blockNumber);
      return {'ok':true, 'result': r};
  } catch (err) {
      return {'ok':false, 'result': err};
  }
};

const spendnRedeem = async() => {
  if (account == null) {
    alert("Please connect wallet first");
    return;
  }

  const serialNo = lib.parseNestedTuple(document.getElementById('serialno').value);
  const zkp1 = lib.parseNestedTuple(document.getElementById('zkp1').value);
  const zkp2 = lib.parseNestedTuple(document.getElementById('zkp2').value);
  const nbits = lib.parseNestedTuple(document.getElementById('nbits').value);

  try {
    const tx = await zc.methods.spendnRedeem(
      serialNo, zkp1, zkp2, nbits
    ).send(
      {from: account, gas: 6721975, gasPrice: gasPrice});
  } catch(err) {
    alert(err.message);
    return;
  }

  alert("SpendnRedeem");
}

const spendnRemint = async() => {
  if (account == null) {
    alert("Please connect wallet first");
    return;
  }

  const serialNo = lib.parseNestedTuple(document.getElementById('serialno2').value);
  const zkp1 = lib.parseNestedTuple(document.getElementById('zkp12').value);
  const zkp2 = lib.parseNestedTuple(document.getElementById('zkp22').value);
  const nbits = lib.parseNestedTuple(document.getElementById('nbits2').value);
  const newcoin = lib.parseNestedTuple(document.getElementById('newcoin').value);

  try {
    const tx = await zc.methods.spendnRemint(
      serialNo, zkp1, zkp2, nbits, newcoin
    ).send(
      {from: account, gas: 6721975, gasPrice: gasPrice});
  } catch(err) {
    alert(err.message);
    return;
  }

  alert("SpendnRemint");

}

init();
