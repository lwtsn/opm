.PHONY : typechain compile test compile-clean console run prettier integration

typechain:
	./node_modules/.bin/typechain --target ethers-v5 --outDir typechain './artifacts/*.json'

compile:
	npx hardhat compile
	make typechain

compile-clean:
	npx hardhat clean
	rm -r ./typechain/*
	make compile

test:
	npm run-script test test/job/JobTest.ts

run-node:
	@npx hardhat node

prettier:
	@npx prettier --write **/*.sol
	@npx prettier --write "{**/*,*}.{js,ts,jsx,tsx}"

coverage:
	npx hardhat coverage
