# Kaldi Tutorial [![Apache2](http://img.shields.io/badge/license-APACHE2-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0.html)

This tutorial will guide you some basic functionalities and operations of [Kaldi](http://kaldi-asr.org/) ASR toolkit.

Project Kaldi is released under the Apache 2.0 license, so is this tutorial.

## Requirements

Kaldi will run on POSIX systems, with these softwares pre-installed.

* `wget`
* GNU build tools: `libtoolize`, `autoconf`, `automake`
* `git`

This tutorial also uses Python code for text processing, so please have python on your side.
Also, the entire compilation can take a couple of hours and up to 8 GB of storage. Make sure you have enough resource before building Kaldi.

## Step 0 - Installation 

Once you have all required build tools, compiling Kaldi is pretty straightforward. First you need to download Kaldi from the repository.

```bash
git clone https://github.com/kaldi-asr/kaldi.git /path/you/want --depth 1
cd /path/you/want
```
(You might want to give `--depth 1` to shrink the entire history of the project into a single commit.)

Assuming you are in the directory where you downloaded Kaldi, you need to perform `make` in two directories: `tools`, and `src`

```bash
cd tools/
make
cd ../src
./configure
make depend
make
```

## Step 1 - Data preparation

This section will cover how to prepare data formats to train and test Kaldi recognizer.

### Data description

Our dataset for this tutorial has 60 `.wav` files, sampled at 8 kHz.
All audio files are recored by an anonymous male contributor of the Kaldi project and included in the project for a test purpose. 
We put them in [`waves_yesno`](waves_yesno) directory, but the dataset also can be found [here](http://openslr.org/resources/1/waves_yesno.tar.gz).
In each file, the individual says 8 words; each word is either *"ken"* or *"lo"* (*"yes"* and *"no"* in Hebrew), so each file is a random sequence of 8 yes's or no's.
The names of files represent the word sequence, with 1 for *yes* and 0 for *no*.

```bash
waves_yesno/1_0_1_1_1_0_1_0.wav
waves_yesno/0_1_1_0_0_1_1_0.wav
...
```
This is all we have as our raw data. Now we will deform these `.wav` files into data format that Kaldi can read in.


### Data preparation

Let's start with formatting data. We will split 60 wave files roughly in half: 29 for training, the rest for testing. Create a directory `data` and,then two subdirectories `train_yesno` and `test_yesno` in it. 

We will prototype a python script to generate necessary input files. Open `data_prep.py`. It 

1. reads up the list of files in `waves_yesno`.
1. generates two list, one stores names of files that start with 0's, the other keeps names starting with 1's, ignore the rest of files.

Now, for each dataset (train, test), we need to generate these input files.

* `text`
    * Essentially, transcriptions.
    * An utterance per line, `<(speaker_id-)utt_id> <transcription>` 
        * e.g. `0_0_1_1_1_1_0_0 NO NO YES YES YES YES NO NO`
    * We will use filenames without extensions as utt_ids
    * No speaker_id for now.
    * Although recordings are in Hebrew, we will use English words, YES and NO, to avoid complicating the problem.
* `wav.scp`
    * Indexing files to unique ids. 
    * `<recording_id> <wave filename with path OR command to get wave file>`
        * e.g. `0_1_0_0_1_0_1_1 waves_yesno/0_1_0_0_1_0_1_1.wav`
    * Again, we can use file names as recording_ids.
* `utt2spk`
    * For each utterance, mark which speaker spoke it.
    * `<utt_id> <speaker_id>`
        * e.g. `0_0_1_0_1_0_1_1 global`
    * Since we have only one speaker in this example, let's use "global" as speaker_id
    * **We found that,** in a later step, Kaldi data validation utility will add an empty line when mirroring `utt2spk`, if the file ends with a non-empty line (we believe this is a bug). To avoid false negative in validation, left (or add) an empty line at the end.
* ~~(optional) `segments`~~: beyond this tutorial's scope
* ~~(optional) `reco2file_and_channel`~~: beyond this tutorial's scope
* `spk2utt`
    * Simply reversing `utt2spk` (`<speaker_id> <all_hier_utterences>`)
    * Can use a Kaldi utility to generate
    * e.g. `utils/utt2spk_to_spk2utt.pl data/train_yesno/utt2spk > data/train_yesno/spk2utt`

Files starts with 0's are train set, and starts with 1's are test set.
`data_prep.py` skeleton includes reading-up part and a method to generate `text` file.
Finish the code to generate each set of 4 files, using the lists of file names, then put files in corresponding directories. (`data/train_yesno`, `data/test_yesno`)

**Note** all files should be sorted. It's Kaldi I/O requirement. Also if you're using unix `sort` (`sort file > file.sorted`), don't forget, before sorting, to set locale to `C` (`export LC_ALL=C`) for C/C++ compatibility (which is the default behavior in Python).

At this point, your data directory should look like this 
```
data
├───train_yesno
│   ├───text
│   ├───utt2spk
│   ├───spk2utt
│   └───wav.scp
└───test_yesno
    ├───text
    ├───utt2spk
    ├───spk2utt
    └───wav.scp
```

## Step 2 - Dictionary preparation

This section will cover how to build lexicon and phone dictionaries for Kaldi recognizer.

### Before moving on

From here, we will use several Kaldi utilities to process further. To do that, Kaldi binaries should be in your `$PATH`. 
Included `path.sh` will automatically do that work, and most Kaldi utilities call for it when it start. So all you need to do is to set a system environment variable `$KALDI` to where you download Kaldi in the first place.

```bash
export KALDI=/path/you/want
```

**Note** that this 'exporting' will last until you close current terminal windows. To make it permanently, use `~/.bashrc` (GNU/Linux, cygwin, msys) or `~/.profile` (OSX)

### Defining blocks of the toy language: Lexicon

Next we will build dictionaries. Let's start with creating intermediate `dict` directory at the root.

```bash
mkdir dict
```

In this toy language, we have only two words: YES and NO. For the sake of simplicity, we will just assume they are one-phone words: Y and N.

```bash
echo -e "Y\nN" > dict/phones.txt            # phones dictionary
echo -e "YES Y\nNO N" > dict/lexicon.txt    # word-pronunciation dictionary
```

Is that it? Aren't we missing anythin? How about pauses between each word? We need an additional phone "SIL" representing silence. And it can be optional.

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
**Note** that "\<SIL\>" will also be used as our OOV token later.

Your `dict` directory should end up with these 5 files:

* `lexicon.txt`: full list of lexeme-phone pairs
* `lexicon_words.txt`: list of word-phone pairs
* `silence_phones.txt`: list of silent phones
* `nonsilence_phones.txt`: list of non-silent phones
* `optional_silence.txt`: list of optional silent phones (here, this looks the same as `silence_phones.txt`)

Finally, we need to convert our dictionaries into what Kaldi would accept - finite state transducer (FST). Among many scripts Kaldi provides, we will use `utils/prepare_lang.sh` to generate FST to represent our language definition.

```bash
utils/prepare_lang.sh --position-dependent-phones false <RAW_DICT_PATH> <OOV> <TEMP_DIR> <OUTPUT_DIR>
```
We're using `--position-dependent-phones` flag to be false in our tiny, tiny toy language. There's not enough context, anyways. For required parameters we will use: 

* `<RAW_DICT_PATH>`: `dict`
* `<OOV>`: `"<SIL>"`
* `<TEMP_DIR>`: Could be anywhere, just put it inside `dict`, such as `dict/tmp`.
* `<OUTPUT_DIR>`: This output will be used in further training. Set it to `data/lang`.

That ends up with this line of command:

```bash 
utils/prepare_lang.sh --position-dependent-phones false dict "<SIL>" dict/tmp data/lang
```

### Defining sequence of the blocks: Language model

In this example, we will use a language model in test stage. For that, Kaldi comes with pre-built yes-no language model! We put it in `lm` directory. Run `lm/prepare_lm.sh` from the tutorial root directory, it will generate properly formatted LM FST and put it in `data/lang_test_tg`.

## Step 3 - Feature extraction and training

This section will cover how to perform MFCC feature extraction and GMM modeling.

### Feature extraction

Once we have all data ready, it's time to extract features for GMM training.

First extract mel-frequency cepstral coefficients.

```bash
steps/make_mfcc.sh --nj <N> <INPUT_DIR> <OUTPUT_DIR> mfcc
```

* `--nj <N>` : number of processors 
    * We only need one, because only one speaker appears in the dataset.
* `<INPUT_DIR>` : our training data is in `data/train_yesno`.
* `<OUTPUT_DIR>` : let's put output to `exp/make_mfcc/train_yesno`, following Kaldi recipes convention.

Now normalize cepstral features

```bash
steps/compute_cmvn_stats.sh <INPUT_DIR> <OUTPUT_DIR> mfcc
```
`<INPUT_DIR>` and `<OUTPUT_DIR>` are the same as above.

**Note** that these shell scripts (`.sh`) are all pipelines through Kaldi binaries. To see which commands were actually executed, see log files in `<OUTPUT_DIR>`. Or even better, see inside the scripts. For details on specific Kaldi commands, refer to [the official documentation](http://kaldi-asr.org/doc/tools.html).

### Monophone model training

We will train a monophone model, since we assume that, in our toy language, phones are not context-dependent. 

```bash 
steps/train_mono.sh --nj <N> --cmd <PIPELINE_SCRIPT> --totgauss <M> <DATA_DIR> <DICT_DIR> <OUTPUT_DIR>
```
* `--cmd <PIPELINE_SCRIPT>`: To use local machine resources, use `"utils/run.pl" pipeline.
* `--totgauss <M>`: target number of Gaussians. We'll try 400 here. Default is 1000.
* `<DATA_DIR>`: path to our training data, `data/train_yesno`.
* `<DCIT_DIR>`: path to our language definition, `data/lang`.
* `<OUTPUT_DIR>`: like the previous, use `exp/mono`.

This will generate FST-based lattice. Kaldi provides a tool to see inside the model.

```bash
/path/to/kaldi/src/fstbin/fstcopy 'ark:gunzip -c exp/mono/fsts.1.gz|' ark,t:- | head -n 20
```
This will print out first 20 lines of the lattice in human-readable format (Each column indicates: Q-from, Q-to, S-in, S-out, Cost)

## Step 4 - Decoding and testing

This section will cover decoding of the model we trained.

### Graph decoding

In step 1, we prepared separate testset in `data/test_yesno` to test our toy model. Now it's time to project it into the feature space as well.

```bash 
steps/make_mfcc.sh --nj 1 data/test_yesno exp/make_mfcc/test_yesno mfcc
steps/compute_cmvn_stats.sh data/test_yesno exp/make_mfcc/test_yesno mfcc
```

Then, we need to build a decode graph using language model: Language model will tell us most likely paths.

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
Or if you are interested in getting automatic transcriptions from the recognizer, take a look at `steps/get_ctm.sh` script.

## Putting all together...

So far, we looked at very simplified process to build a speech recognizer using Kaldi, from preparing training data, to decode HMM graphical model. This tutorial is, in fact, largely adopted from Kaldi *yesno* recipe. To see full recipe, go to Kaldi directory and go down to `egs/yesno/s5` (The original recipe most written in bash script). There you'll find `run.sh`, which is the uber script to pipeline all the steps we came over in this tutorial. Take a look at it to see how 'conventional' Kaldi recipe is written. Also, `egs` directory includes many other recipes for large corpora, so if interested, there should be your playground for now.
