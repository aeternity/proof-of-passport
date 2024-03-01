#!/bin/bash

mkdir -p bls12_381

circom circuits/proof_of_passport.circom -l node_modules --prime bls12381 --r1cs --wasm --output bls12_381 --O2

yarn snarkjs groth16 setup bls12_381/proof_of_passport.r1cs pot20_final.ptau bls12_381/proof_of_passport.zkey

yarn snarkjs zkey export verificationkey bls12_381/proof_of_passport.zkey bls12_381/verification_key.json

node bls12_381/proof_of_passport_js/generate_witness.js bls12_381/proof_of_passport_js/proof_of_passport.wasm bls12_381/test_input.json bls12_381/test.wtns

snarkjs wtns check bls12_381/proof_of_passport.r1cs bls12_381/test.wtns

snarkjs groth16 prove bls12_381/proof_of_passport.zkey bls12_381/test.wtns bls12_381/test_proof.json bls12_381/test_public.json

cp bls12_381/test_proof.json ../ae-contracts/test/test_proof.json
cp bls12_381/test_public.json ../ae-contracts/test/test_public.json