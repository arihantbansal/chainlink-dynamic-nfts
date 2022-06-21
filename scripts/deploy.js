const main = async () => {
	const dynamicContractFactory = await hre.ethers.getContractFactory(
		"BullBear"
	);
	const dynamicContract = await dynamicContractFactory.deploy(
		21600,
		"0x8a753747a1fa494ec906ce90e9f37563a8af630e",
		"0x6168499c0cffcacd319c818142124b7a15e857ab"
	);
	await dynamicContract.deployed();

	console.log("Contract deployed to: ", dynamicContract.address);
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
