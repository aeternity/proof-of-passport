#!/bin/bash

# Check if the first argument is "app-only"
if [ "$1" == "app-only" ]; then
    echo "Building only for the app"
    APP_ONLY=1
else
    APP_ONLY=0
fi

mkdir -p build
cd build    

cd ..

echo "compiling circuit"
circom circuits/proof_of_passport.circom -l node_modules -p bls12381 --r1cs --wasm --sym --output build

mkdir -p ../app/ark-circom-passport/passport/
cp build/proof_of_passport.r1cs ../app/ark-circom-passport/passport/
cp build/proof_of_passport_js/proof_of_passport.wasm ../app/ark-circom-passport/passport/
echo "copied proof_of_passport.r1cs and proof_of_passport.wasm to ark-circom-passport"
echo "file sizes:"
echo "Size of proof_of_passport.r1cs: $(wc -c <../app/ark-circom-passport/passport/proof_of_passport.r1cs) bytes"
echo "Size of proof_of_passport.wasm: $(wc -c <../app/ark-circom-passport/passport/proof_of_passport.wasm) bytes"

echo "building zkey"
yarn snarkjs groth16 setup build/proof_of_passport.r1cs pot20_final.ptau build/proof_of_passport.zkey

echo "building vkey"
echo "test random" | yarn snarkjs zkey contribute build/proof_of_passport.zkey build/proof_of_passport_final.zkey
yarn snarkjs zkey export verificationkey build/proof_of_passport_final.zkey build/verification_key.json

yarn snarkjs zkey export solidityverifier build/proof_of_passport_final.zkey build/Verifier.sol
cp build/Verifier.sol ../contracts/contracts/Verifier.sol
echo "copied Verifier.sol to contracts"

npm i -g @aeternity/snarkjs -f
snarkjs zkey export sophiaverifier build/proof_of_passport_final.zkey build/Verifier.aes
cp build/Verifier.aes ../ae-contracts/contracts/Verifier.aes
echo "copied Verifier.aes to contracts"
