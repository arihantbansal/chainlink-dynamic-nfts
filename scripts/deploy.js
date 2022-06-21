const main = async () => {
	const nftContractFactory = await hre.ethers.getContractFactory("BullBear");
	const nftContract = await nftContractFactory.deploy(
		21600,
		0x8a753747a1fa494ec906ce90e9f37563a8af630e,
		0x6168499c0cffcacd319c818142124b7a15e857ab
	);
	await nftContract.deployed();

	console.log("Contract deployed to: ", nftContract.address);
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
