const { expect } = require('chai');
const { ethers } = require('hardhat');
const UserWalletArtifact = require('../artifacts/contracts/v4/Controller.sol/UserWallet.json');

describe('BUP', async function () {
  // users
  let owner, addr1;
  // contracts
  let bup, controller;
  // functions
  let getBalance;
  // wallet address
  let walletAddress;

  before(async function () {
    const [ownerSigner, addr1Signer] = await ethers.getSigners();

    owner = ownerSigner;
    addr1 = addr1Signer;

    // --------------------------------------------------------------------------

    const BUP = await ethers.getContractFactory('BUP', { from: addr1.address });
    bup = await BUP.deploy();

    const Controller = await ethers.getContractFactory('Controller');
    controller = await Controller.deploy();

    // --------------------------------------------------------------------------

    getBalance = async (address) => {
      return (await bup.balanceOf(address)).toString();
    };

    // --------------------------------------------------------------------------

    console.log('  Controller Contract Address : ', controller.address);
    console.log('  BUP Contract Address        : ', bup.address);
    console.log('  Owner Address               : ', owner.address);
    console.log('  Address1 Address            : ', addr1.address);
    console.log(
      '\n  ------------------------------- Good luck! -------------------------------\n'
    );
  });

  it('#1 Create user wallet', async function () {
    const makeWallet = async () => {
      await controller.makeWallet();
      const receiver = await new Promise((resolve, reject) => {
        controller.on('LogNewWallet', (receiver) => {
          resolve(receiver);
        });
      });

      return receiver;
    };

    walletAddress = await makeWallet();

    console.log('Create wallet address: ', walletAddress);

    expect(walletAddress).but.not.an('null');
  });

  it('#2 Transfer token to new wallet', async function () {
    const amount = 1000;

    await bup.transfer(walletAddress, amount);

    const tknBalance = await getBalance(walletAddress);

    console.log(`TKN Balance of ${walletAddress}: `, tknBalance);
  });

  it('#3 Sweep token', async function () {
    const wallet = new ethers.Contract(
      walletAddress,
      UserWalletArtifact.abi,
      owner
    );

    await wallet.sweep(bup.address, 1000);

    const balance = await getBalance(walletAddress);

    expect(balance).to.equal('0');
  });
});
