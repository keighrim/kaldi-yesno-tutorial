# Kaldi Tutorial

This tutorial will guide you some basic functionalities and operations of [Kaldi](http://kaldi-asr.org/) ASR toolkit.

## Step 1 - Data preparation

## Step 2 - Dictionary preparation

## Step 3 - Feature extraction and training

## Step 4 - Decoding and tesing

This section will cover decoding of the model we trained.

### Graph decoding

To test our toy model, we prepared separate testset in `data/test_yesno`. Not it's time to transform it into feature space.

```bash 
steps/make_mfcc.sh --nj 1 data/test_yesno exp/make_mfcc/test_yesno mfcc
steps/compute_cmvn_stats.sh data/test_yesno exp/make_mfcc/test_yesno mfcc
```

Then, we need to build a decode graph using language model.

```bash
utils/mkgraph.sh --mono data/lang_test_tg exp/mono exp/mono/graph_tgpr
```

Finally, run decode script, write the results in `exp/mono/decode_test_yesno`.

```bash 
steps/decode.sh --nj 1 --cmd "utils/run.pl" exp/mono/graph_tgpr data/test_yesno exp/mono/decode_test_yesno
```

### Looking at results

Included scoring script will compute word error rate (WER) of the testset. See `exp/mono/decode_test_yesno` to look at them.
```bash
for x in exp/mono/decode_test_yesno/wer*; do echo $x; grep WER $x;  done
```

## Putting all together...


