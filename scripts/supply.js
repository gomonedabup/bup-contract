const hre = require('hardhat');

async function main() {
  const BUP = await hre.ethers.getContractFactory('BUP');
  const bup = await BUP.attach('0x5FbDB2315678afecb367f032d93F642f64180aa3');

  const [owner] = await hre.ethers.getSigners();
  const supply = (await bup.balanceOf(owner.address)).toString();

  console.log(supply);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
