# Kaldi Tutorial

This tutorial will guide you some basic functionalities and operations of [Kaldi](http://kaldi-asr.org/) ASR toolkit.

## Step 1 - Data preparation

## Step 2 - Dictionary preparation

This section will cover how to build lexicon and phones for Kaldi recognizer.

### Defining our toy language

Next we will build dictionaries. Let's start with creating `dict` directory at the root.

In this toy language, we have only two lexemes: YES and NO. For the sake of simplicity, we will just assume two phones for each lexeme: Y and N.

```bash
echo -e "Y\nN" > dict/phones.txt
echo -e "YES Y\nNO N" > dict/lexicon.txt
```

Wait, really? How about pauses between each word? We need an additional phone "SIL" representing silence. And it can be optional.

```bash
echo "SIL" > dict/silence_phones.txt
echo "SIL" > dict/optional_silence.txt
mv dict/phones.txt dict/nonsilence_phones.txt
```

Now amend lexicon to include silence as well.

```bash
cp dict/lexicon.txt dict/lexicon_words.txt
echo "<SIL> SIL" >> dict/lexicon.txt 
```
"<SIL\>" will be used as our OOV token in further procedures

Your `dict` directory should end up with these files:

* `lexicon.txt`: full list of lexicon-phone pairs
* `lexicon_words.txt`: list of non-silient lexicon-phone pairs
* `nonsilence_phones.txt`: list of non-silient phones
* `silence_phones.txt`: list of silient phones
* `optional_silence.txt`: list of optional silient phones (here, this is the same as `silence_phones.txt`)

Finally, we need to convert our dictionaries into what Kaldi would accept. Kaldi provides a script among many others to do that. Let's use `utils/prepare_lang.sh`.

```bash
utils/prepare_lang.sh --position-dependent-phones false <RAW_DICT_PATH> <OOV> <TEMP_DIR> <OUTPUT_DIR>
```
We're using `--position-dependent-phones` flag to be false in out tiny, tiny toy language. There's not enough context, anyways. For required params: 

* `<RAW_DICT_PATH>`: `dict`
* `<OOV>`: `"<SIL>"`
* `<TEMP_DIR>`: could be anywhere, just put it inside `dict`, such as `dict/tmp`.
* `<OUTPUT_DIR>`: This output will be used in further training. Set it to `data/lang`.

### Language model

In this example, we will use a language model in test stage. For that, Kaldi comes with pre-built yes-no language model! We put it in `lm` directory. Run `lm/prepare_lm.sh` from the tutorial root directory, it will generate properly formatted LM and put it in `data/lang_test_tg`.



* feates.scp




### Feature extraction
Once you have all data ready, it's time to extract features for GMM training.

First extract mel-frequency cepstral coefficients.
```bash
steps/make_mfcc.sh --nj <N> <INPUT_DIR> <OUTPUT_DIR> mfcc
```

* `--nj <N>` : number of processors 
    * Critical when using CUDA-based parallel computing (such as mining BitCoin).
    * Set 1~8 on personal laptops, depending on CPU.
* `<INPUT_DIR>` : here we have two inputs, `data/train_yesno`, `data/test_yesno`
* `<OUTPUT_DIR>` : let's put output to `exp/make_mfcc/train_yesno`, `exp/make_mfcc/test_yesno`

Now normalize cepstral features
```bash
steps/compute_cmvn_stats.sh <INPUT_DIR> <OUTPUT_DIR> mfcc
```





### Training


### Decoding