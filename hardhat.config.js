require('@nomiclabs/hardhat-waffle');
const fs = require('fs');

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

task('deploy', 'Deploys contract, and outputs files', async (taskArgs, hre) => {
  // 컨트랙트 컴파일 및 생성
  const BUP = await hre.ethers.getContractFactory('BUP');
  const bup = await BUP.deploy();
  // 컨트랙트 배포
  await bup.deployed();

  // 컨트랙트 주소 기록
  fs.writeFileSync('./.contracts', controller.address);
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
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
