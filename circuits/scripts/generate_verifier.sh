#!/bin/bash

VERIFICATION_KEYS=$1

if [ ! -f "${VERIFICATION_KEYS}" ]; then
  echo "Usage: $0 <verification.keys>"
fi

get_xs() {
  local VAR=$1
  STR=`cat ${VERIFICATION_KEYS} | jq -r ".${VAR}" | tr -d '\n' | sed -e 's/ //g; s/"//g; s/]//g; s/\[//g'`
  IFS=',' read -r -a RES <<< "${STR}"
}

show_g1() {
  local JSON=$1
  local VAR=$2
  local IND=$3
  local TRAIL=$4
  get_xs ${JSON}
  printf "%${IND}s%s = BLS12_381.mk_g1(%s,\n" '' ${VAR} ${RES[0]}
  printf "%$(( $IND + 19 + ${#VAR} ))s%s,\n" '' ${RES[1]}
  printf "%$(( $IND + 19 + ${#VAR} ))s%s)%s\n" '' ${RES[2]} ${TRAIL}
}

show_g2() {
  local JSON=$1
  local VAR=$2
  local IND=$3
  local TRAIL=$4
  get_xs "${JSON}[0]"
  XS1=( "${RES[@]}" )
  get_xs "${JSON}[1]"
  XS2=( "${RES[@]}" )
  printf "%${IND}s%s = BLS12_381.mk_g2(%s,\n" '' ${VAR} ${XS1[0]}
  printf "%$(( $IND + 19 + ${#VAR} ))s%s,\n" '' ${XS1[1]}
  printf "%$(( $IND + 19 + ${#VAR} ))s%s,\n" '' ${XS2[0]}
  printf "%$(( $IND + 19 + ${#VAR} ))s%s,\n" '' ${XS2[1]}
  printf "%$(( $IND + 19 + ${#VAR} ))s1, 0)%s\n" '' ${TRAIL}
}

show_g1s() {
  local JSON=$1
  local VAR=$2
  local IND=$3
  local TRAIL=$4

  N=`cat ${VERIFICATION_KEYS} | jq -r ".${JSON} | length"`

  I=0
  printf "%${IND}s%s = \n" '' ${VAR}
  printf "%$(( $IND + 2 ))s[\n" ''
  while [ "${I}" -lt "${N}" ]; do
    get_xs "${JSON}[${I}]"
    printf "%$(( $IND + 4 ))sBLS12_381.mk_g1(%s,\n" '' ${RES[0]}
    printf "%$(( $IND + 20 ))s%s,\n" '' ${RES[1]}
    printf "%$(( $IND + 20 ))s1)" ''
    I=$(( ${I} + 1 ))
    if [ "${I}" -eq "${N}" ]; then
      printf "\n"
    else
      printf ",\n"
    fi
  done

  printf "%$(( $IND + 2 ))s]%s\n" '' ${TRAIL}
}


cat << EOF
include "List.aes"
include "BLS12_381.aes"

contract Verifier =
  record proof = {a : BLS12_381.g1, b : BLS12_381.g2, c : BLS12_381.g1}
  record proofInput = {a : int * int, b : (int * int) * (int * int), c : int * int}
  record verifying_key = {alpha : BLS12_381.g1, beta : BLS12_381.g2, gamma : BLS12_381.g2,
                          delta : BLS12_381.g2, gamma_abc : list(BLS12_381.g1)}

  entrypoint verify(input : list(int), proof_in : proofInput) : bool =
    let snark_scalar_field = 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001
    let proof = mk_proof(proof_in)
    let vk = verifying_key()
    require(List.length(input) + 1 == List.length(vk.gamma_abc), "invalid input")
    [ require(i =< snark_scalar_field, "invalid input") | i <- input ]
    let (g0 :: gs) = vk.gamma_abc
    let vk_x = List.foldl(addAndScalarMul, g0, List.zip(input, gs))
    BLS12_381.pairing_check([proof.a, BLS12_381.g1_neg(vk_x), BLS12_381.g1_neg(proof.c), BLS12_381.g1_neg(vk.alpha)],
                            [proof.b, vk.gamma, vk.delta, vk.beta])

  private function addAndScalarMul(x : BLS12_381.g1, (i, g) : int * BLS12_381.g1) =
    BLS12_381.g1_add(x, BLS12_381.g1_mul(BLS12_381.int_to_fr(i), g))

  private function mk_proof({a = (ax, ay), b = ((bx1, bx2), (by1, by2)), c = (cx, cy)} : proofInput) : proof =
    {a = BLS12_381.mk_g1(ax, ay, 1),
     b = BLS12_381.mk_g2(bx1, bx2, by1, by2, 1, 0),
     c = BLS12_381.mk_g1(cx, cy, 1)}

  private function verifying_key() : verifying_key = {
EOF

show_g1 "vk_alpha_1" "alpha" 6 ","
show_g2 "vk_beta_2" "beta" 6 ","
show_g2 "vk_gamma_2" "gamma" 6 ","
show_g2 "vk_delta_2" "delta" 6 ","
show_g1s "IC" "gamma_abc" 6 ""

echo "    }"