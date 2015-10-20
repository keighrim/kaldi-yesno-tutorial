# Kaldi Tutorial

This tutorial will guide you some basic functionalities and operations of [Kaldi](http://kaldi-asr.org/) ASR toolkit.

## Step 1 - Data preparation

## Step 2 - Dictionary preparation

## Step 3 - Feature extraction and training

This section will cover how to perform MFCC feature extraction for GMM modeling

### Feature extraction

Once you have all data ready, it's time to extract features for GMM training.

First extract mel-frequency cepstral coefficients.

```bash
steps/make_mfcc.sh --nj <N> <INPUT_DIR> <OUTPUT_DIR> mfcc
```

* `--nj <N>` : number of processors 
    * Critical when using CUDA-based parallel computing (such as mining BitCoin).
    * Set 1~8 on personal laptops, depending on CPU.
* `<INPUT_DIR>` : out training data is in `data/train_yesno`.
* `<OUTPUT_DIR>` : let's put output to `exp/make_mfcc/train_yesno`, following Kaldi recipes convention.


Now normalize cepstral features
```bash
steps/compute_cmvn_stats.sh <INPUT_DIR> <OUTPUT_DIR> mfcc
```
`<INPUT_DIR>` and `<OUTPUT_DIR>` are the same as above.

**Note** that these commands are all pipelines through Kaldi binaries. To see which commands were actually excuted, see log files in `<OUTPUT_DIR>`. Or even better, see sinside the scripts. For details on specific Kaldi commands, refer to [the official documentation](http://kaldi-asr.org/doc/tools.html).

### Monophone model training

We will train a monophone model, since we assume that, in our toy language, phones are not context-dependent.


```bash 
steps/train_mono.sh --nj <N> --cmd <PIPELINE_SCRIPT> --totgauss <M> <DATA_DIR> <DICT_DIR> <OUTPUT_DIR>
```
* `--cmd <PIPELINE_SCRIPT>`: To use local machine resources, use `"utils/run.pl" pipeline.
* `--totgauss <M>`: target number of Gaussians.
* `<DATA_DIR>`: path to our training data.
* `<DCIT_DIR>`: path to our language definition, `data/lang`.
* `<OUTPUT_DIR>`: as previous, use `exp/mono`.

This will generate FST-based lattice. Kaldi provides a tool to see inside the model.
```bash
/path/to/kaldi/src/fstbin/fstcopy 'ark:gunzip -c exp/mono/fsts.1.gz|' ark,t:- | head -n 20
```
This will print out the lattice in human-readable format (Each column indicetes: Q-from, Q-to, S-in, S-out, Cost)

## Continue to next step