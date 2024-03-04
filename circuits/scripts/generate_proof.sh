#!/bin/bash

echo "generating proof"
node build/proof_of_passport_js/generate_witness.js build/proof_of_passport_js/proof_of_passport.wasm build/test_input.json build/test.wtns

snarkjs wtns check build/proof_of_passport.r1cs build/test.wtns

snarkjs groth16 prove build/proof_of_passport_final.zkey build/test.wtns build/test_proof.json build/test_public.json

cp build/test_proof.json ../ae-contracts/test/test_proof.json
cp build/test_public.json ../ae-contracts/test/test_public.json

echo "generated proof"
