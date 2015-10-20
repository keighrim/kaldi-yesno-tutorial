#! /bin/bash
if [ $# -ne 1 ]; then
    echo "usage: path /path/to/kaldi"
fi
KALDI=$1



export PATH=$(pwd)/utils/:\
$KALDI/src/bin:\
$KALDI/tools/openfst/bin:\
$KALDI/src/fstbin/:\
$KALDI/src/gmmbin/:\
$KALDI/src/featbin/:\
$KALDI/src/lm/:\
$KALDI/src/sgmmbin/:\
$KALDI/src/fgmmbin/:\
$KALDI/src/latbin/:\
$KALDI:\
$PATH
export LC_ALL=C