async function main() {
  const [deployer] = await ethers.getSigners();

  console.log('Deploying contracts with the account:', deployer.address);

  console.log('Account balance:', (await deployer.getBalance()).toString());

  const BUP = await hre.ethers.getContractFactory('BUP');
  const bup = await BUP.deploy();
  await bup.deployed();

  console.log('BUP address:', bup.address);

  const Controller = await hre.ethers.getContractFactory('Controller');
  const controller = await Controller.deploy();
  await controller.deployed();

  console.log('Controller address:', controller.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
