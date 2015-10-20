#! /bin/bash

KALDI=/PATH/TO/KALDI

export PATH=\
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
