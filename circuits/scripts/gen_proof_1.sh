#!/bin/bash

PROOF=$1

if [ ! -f "${PROOF}" ]; then
  echo "Usage: $0 <verification.keys>"
fi

get_xs() {
  local VAR=$1
  STR=`cat ${PROOF} | jq -r ".${VAR}" | tr -d '\n' | sed -e 's/ //g; s/"//g; s/]//g; s/\[//g'`
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

  N=`cat ${PROOF} | jq -r ".${JSON} | length"`

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
include "BLS12_381.aes"

contract Proof =
  record proof = {a : BLS12_381.g1, b : BLS12_381.g2, c : BLS12_381.g1}
  record proofInput = {a : int * int, b : (int * int) * (int * int), c : int * int}
  record verifying_key = {alpha : BLS12_381.g1, beta : BLS12_381.g2, gamma : BLS12_381.g2,
                          delta : BLS12_381.g2, gamma_abc : list(BLS12_381.g1)}

  entrypoint the_proof() : proof = {
EOF

show_g1 "pi_a" "a" 6 ","
show_g2 "pi_b" "b" 6 ","
show_g1 "pi_c" "c" 6 ""

echo "    }"