require('@nomiclabs/hardhat-waffle');
const fs = require('fs');

function getContractAddress() {
  const contracts = require('./.contracts.json');

  return contracts;
}

task('contracts', '컨트랙트 주소 정보', async () => {
  const contracts = getContractAddress();

  const keys = Object.keys(contracts);

  keys.forEach((key) => {
    console.log(`${key}: ${contracts[key]}`);
  });
});

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', '사용자 정보', async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

task(
  'deploy',
  '컨트랙트 배포 및 주소 저장(.account, .contract)',
  async (taskArgs, hre) => {
    // 컨트랙트 컴파일 및 생성
    const BUP = await hre.ethers.getContractFactory('BUP');
    const bup = await BUP.deploy();
    // 컨트랙트 배포
    await bup.deployed();

    // 컨트랙트 컴파일 및 생성
    const Controller = await hre.ethers.getContractFactory('Controller');
    const controller = await Controller.deploy();
    // 컨트랙트 배포

    await controller.deployed();

    // 컨트랙트 주소 json 파일로 저장
    const contracts = {
      BUP: bup.address,
      Controller: controller.address,
    };

    fs.writeFileSync('./.contracts.json', JSON.stringify(contracts));
  }
);

task('transfer', 'BUP 전송')
  .addParam('account', '사용자 주소')
  .addParam('amount', '수량')
  .setAction(async (taskArgs, hre) => {
    const { account, amount } = taskArgs;

    if (!amount) throw new Error('잘못된 수량 입니다.');

    const isAddress = hre.ethers.utils.isAddress(account);

    if (!isAddress) throw new Error('잘못된 주소 입니다.');

    const { BUP: bupAddress } = getContractAddress();
    const BUP = await hre.ethers.getContractFactory('BUP');
    const bup = await BUP.attach(bupAddress);

    try {
      await bup.transfer(account, amount);

      const balance = (await bup.balanceOf(account)).toString();

      console.log(`Transfer done! balance of target: ${balance}`);
    } catch (e) {
      console.log('BUP 전송 중 오류가 발생했습니다: ', e);
    }
  });

task('balance', 'BUP 보유 수량 확인')
  .addParam('account', '사용자 주소')
  .setAction(async (taskArgs, hre) => {
    const { account } = taskArgs;
    const isAddress = hre.ethers.utils.isAddress(account);

    if (!isAddress) throw new Error('잘못된 주소 입니다.');

    const { BUP: bupAddress } = getContractAddress();
    const BUP = await hre.ethers.getContractFactory('BUP');
    const bup = await BUP.attach(bupAddress);

    const balance = (await bup.balanceOf(account)).toString();

    console.log(balance);
  });

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: 'localhost',
  networks: {
    hardhat: {},
    localhost: {
      url: 'http://localhost:8545',
    },
  },
  solidity: { compilers: [{ version: '0.4.11' }, { version: '0.5.0' }] },
  overrides: {
    'contracts/v4/*.sol': {
      version: '0.4.11',
    },
    'contracts/v5/*.sol': {
      version: '0.5.0',
    },
  },
};
