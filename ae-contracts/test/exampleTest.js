const {assert} = require('chai');
const {utils} = require('@aeternity/aeproject');

const test_public = require("./test_public.json");
const test_proof = require("./test_proof.json");

const VERIFIER_CONTRACT_SOURCE = './contracts/Verifier.aes';

describe('ExampleContract', () => {
    let aeSdk;
    let contract;

    before(async () => {
        aeSdk = utils.getSdk();

        // a filesystem object must be passed to the compiler if the contract uses custom includes
        const fileSystem = utils.getFilesystem(VERIFIER_CONTRACT_SOURCE);

        // get content of contract
        const sourceCode = utils.getContractContent(VERIFIER_CONTRACT_SOURCE);

        // initialize the contract instance
        contract = await aeSdk.initializeContract({sourceCode, fileSystem});
        await contract.$deploy([]);

        // create a snapshot of the blockchain state
        await utils.createSnapshot(aeSdk);
    });

    // after each test roll back to initial state
    afterEach(async () => {
        await utils.rollbackSnapshot(aeSdk);
    });

    it('verify', async () => {
        const input = test_public.map(i => BigInt(i));
        const proofInput = {
            a: [BigInt(test_proof.pi_a[0]), BigInt(test_proof.pi_a[1])],
            b: [
                [
                    BigInt(test_proof.pi_b[0][0]),
                    BigInt(test_proof.pi_b[0][1])
                ],
                [
                    BigInt(test_proof.pi_b[1][0]),
                    BigInt(test_proof.pi_b[1][1])
                ],
            ],
            c: [BigInt(test_proof.pi_c[0]), BigInt(test_proof.pi_c[1])],
        }

        const verify = await contract.verify(input, proofInput);
        assert.equal(verify.decodedResult, true);
    });
});
