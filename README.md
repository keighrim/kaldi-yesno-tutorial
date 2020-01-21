# Kaldi Tutorial [![Apache2](http://img.shields.io/badge/license-APACHE2-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0.html)

This tutorial will guide you through some basic functionalities and operations of [Kaldi](http://kaldi-asr.org/) ASR toolkit.

(Project Kaldi is released under the Apache 2.0 license, so is this tutorial.)

In the end of the tutorial, you'll be assigned with the first programming assignment. In this assignment we will test your 
* familiarity with version controlling with Git
* understanding of Unix shell environment (particularly, bash) and scripting 
* ability to read and write Python code

## Step 0 - Installing Kaldi  

## Requirements

The Kaldi will run on POSIX systems, with these software/libraries pre-installed.
(If you don't know how to use a package manager on your computer to install these libraries, this tutorial might not be for you.)

* [GNU build tools](https://en.wikipedia.org/wiki/GNU_Build_System#Components)
* [`wget`](https://www.gnu.org/software/wget/)
* [`git`](https://git-scm.com/)
* (optional) [`sox`](http://sox.sourceforge.net/)

Also, later in this tutorial, we'll write a short Python program for text processing, so please have python on your side.

The entire compilation can take a couple of hours and up to 8 GB of storage depending on your system specification and configuration. Make sure you have enough resource before start compiling.

## Compilation 

Once you have all required build tools, compiling the Kaldi is pretty straightforward. First you need to download it from the repository.

```bash
git clone https://github.com/kaldi-asr/kaldi.git /path/you/want --depth 1
cd /path/you/want
```
(`--depth 1`: You might want to give this option to shrink the entire history of the project into a single commit to save your storage and bandwidth.)

Assuming you are in the directory where you cloned (downloaded) Kaldi, now you need to perform `make` in two subdirectories: `tools`, and `src`

```bash
cd tools/
make
cd ../src
./configure
make depend
make
```
If you need more detailed install instructions or having trouble/errors while compiling, please check out the official documentation: [tools/INSTALL](https://github.com/kaldi-asr/kaldi/blob/master/tools/INSTALL), [src/INSTALL](https://github.com/kaldi-asr/kaldi/blob/master/src/INSTALL)

Now all the Kaldi tools should be ready to use. 

## Step 1 - Data preparation

This section will cover how to prepare your data to train and test a Kaldi recognizer.

### Data description

Our toy dataset for this tutorial has 60 `.wav` files, sampled at 8 kHz.
All audio files are recorded by an anonymous male contributor of the Kaldi project and included in the project for a test purpose. 
We put them in [`waves_yesno`](waves_yesno) directory, but the dataset also can be found at [its original location](http://openslr.org/resources/1/waves_yesno.tar.gz).
In each file, the individual says 8 words; each word is either "*ken*" or "*lo*" ( "*yes*" and "*no*" in Hebrew), so each file is a random sequence of 8 yes's or no's.
The names of files represent the word sequence, with 1 for *ken/yes* and 0 for *lo/no*, that is, a file name will serve as transcript for each sequence. 

```bash
waves_yesno/1_0_1_1_1_0_1_0.wav
waves_yesno/0_1_1_0_0_1_1_0.wav
...
```
This is all we have as our raw data: audio and transcript. Now we will deform these `.wav` files into data format that Kaldi can read in.


### Data preparation

Let's start with formatting data. We will split 60 wave files roughly in half: 31 for training, the rest for testing. Create a directory `data` and its two subdirectories `train_yesno` and `test_yesno`.

Now we will write a python script to generate necessary input files. Open `data_prep.py` and . It 

1. reads up the list of files in `waves_yesno`.
1. generates two lists, one with names of files that start with 0, the other with names starting with 1, ignoring else. 

Now, for each dataset (train, test), we need to generate following Kaldi input files representing our data.

* `text`
    * Essentially, transcripts of the audio files.
    * Write an utterance per line, formatted in `<utt_id> <transcript>` 
        * e.g. `0_0_1_1_1_1_0_0 NO NO YES YES YES YES NO NO`
    * We will use filenames without extensions as `utt_id`s for now.
        * Note that an id needs to be a single token (no whitespace inside allowed).
    * Although recordings are in Hebrew, we will use English words, `YES` and `NO`, just for the sake of readibility.
* `wav.scp`
    * Indexing files to unique ids. 
    * `<file_id> <path of wave filenames OR command to get wave file>`
        * e.g. `0_1_0_0_1_0_1_1 waves_yesno/0_1_0_0_1_0_1_1.wav`
    * Again, we can use file names as `file_id`s.
    * Paths can be absolute or relative. Using relative path will make the code portable, while absolute paths are more robust. Remember when submitting code, the portability is very important.
    * Note that here we have a single utterance in each wave file, in turn we have 1-to-1 & onto mapping between `utt_id`s and `file_id`s. 
* `utt2spk`
    * For each utterance, mark which speaker spoke it.
        * Since we have only one speaker in this example, let's use `global` as `speaker_id`
    * `<utt_id> <speaker_id>`
        * e.g. `0_0_1_0_1_0_1_1 global`
* `spk2utt`
    * Simply inverse-indexed `utt2spk` (`<speaker_id> <all_hier_utterences>`)
    * Instead of writing Python code to re-index utterances and speakers, you can also use a Kaldi utility to do it.
        * e.g. `utils/utt2spk_to_spk2utt.pl data/train_yesno/utt2spk > data/train_yesno/spk2utt`
        * However, since we are writing a Python program, you might want to call the Kaldi utility from within Python code. See [subprocess](https://docs.python.org/3/library/subprocess.html) or [os.system()](https://docs.python.org/3/library/os.html#os.system).
    * Or, of course, you can write Python code to index utterances by speakers. 
* (optional) `segments`: *not used for this data *
    * Contains mappings between utterance segmentation/alignment information and recording files. 
    * Only required when a file contains multiple utterances, which is not this case.
* (optional) `reco2file_and_channel`: *not used for this data *
    * Only required when audios were recorded in dual channels (e.g. for telephony conversational setup - one speaker on each side).
* (optional) `spk2gender`: *not used for this data *
    * Map from speakers to their gender information. 
    * Used in vocal tract length normalization step, if needed. 

As mentioned, files start with 0 compose the train set, and those start with 1 compose the test set.
`data_prep.py` skeleton includes reading-up part and a function to generate `text` file.
Now *finish the code* to generate each set of 4 files using the lists of file names in corresponding directories. (`data/train_yesno`, `data/test_yesno`)

**Note** all files should be carefully sorted in C/C++ compatible way as required by the Kaldi.
 If you're calling unix [`sort`](http://man7.org/linux/man-pages/man1/sort.1.html), don't forget, before sorting, to set locale to `C` (`LC_ALL=C sort ...`) for C/C++ compatibility.
 In Python, you might want to look at [this document](https://wiki.python.org/moin/HowTo/Sorting#Odd_and_Ends) from the Python wiki.
 Or you can use the Kaldi built-in fix script at your convenience after all data files are prepared. For example, 

```bash
utils/fix_data_dir.sh data/train_yesno/
utils/fix_data_dir.sh data/test_yesno/
```

If you're done with the code, your `data` directory should look like this at this point. 
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

You can't proceed the tutorial unless you properly generated these files. Please finish `data_prep.py` to generate them.

## Step 2 - Dictionary preparation

This section will cover how to build language knowledge - lexicon and phone dictionaries - for a Kaldi recognizer.

### Before continuing

From here, we will use several Kaldi utilities (included in [`steps`](steps) and [`utils`](utils) directories) to process further. To do that, Kaldi binaries should be in your `$PATH`. 
However, Kaldi is a fairly large toolkit, and there are a number of binaries distributed over many different directories, depending on their purpose. 
So, we will use `path.sh` (provided in this repository) to add all of Kaldi directories with binaries to `$PATH` to the subshell when a script runs (we will see this later).
All you need to do right now is to open the `path.sh` file and edit the `$KALDI_ROOT` variable to point your Kaldi installation location, and then [`source`](http://tldp.org/LDP/abs/html/special-chars.html#DOTREF) that file to expand `$PATH` in the current shell instance. 

### Defining building blocks for the toy language: Lexicon

Next we will build dictionaries. Let's start with creating intermediate `dict` directory at the project root.

In this toy language, we have only two words: `YES` and `NO`. For the sake of simplicity, we will just assume they are one-phone words and each pronounced only in a way, represented `Y` and `N` symbols.

```bash
printf "Y\nN\n" > dict/phones.txt            # list of phonetic symbols
printf "YES Y\nNO N\n" > dict/lexicon.txt    # word-to-pronunciation dictionary
```

However, in real speech, there are not only human sounds that contributes to a linguistic expression, but also pauses/silence and environmental noises from things.
Kaldi calls all those non-linguistic sounds "*silence*".
For example, even in this small, controlled recordings, we have pauses between each word. 
Thus we need an additional phone "`SIL`" representing such *silence*. And it can be happening at end of of all words. Kaldi calls this kind of silence "*optional*".

```bash
echo "SIL" > dict/silence_phones.txt        # list of silence symbols
echo "SIL" > dict/optional_silence.txt      # list of optional silence symbols 
mv dict/{phones,nonsilence_phones}.txt      # list of non-silence symbols
# note that we no longer use simple `phones.txt` list
```

Now amend the lexicon to include the silence as well.

```bash
cp dict/lexicon.txt dict/lexicon_words.txt  # word-to-sound dictionary
echo "<SIL> SIL" >> dict/lexicon.txt        # union with nonword-to-silence dictionary 
# again note that we use `lexicon.txt` list as the union set, unlike above 
```
**Note** that the token "\<SIL\>" will also be used as our out-of-vocabulary (unknown) token later.

Your `dict` directory should end up with these 5 dictionaries:

* `lexicon.txt`: full list of lexeme-phone pairs including *silences*
* `lexicon_words.txt`: list of word-phone pairs (no silence)
* `silence_phones.txt`: list of silent phones
* `nonsilence_phones.txt`: list of non-silent phones
* `optional_silence.txt`: list of optional silent phones (here, this looks the same as `silence_phones.txt`)

Finally, we need to convert our dictionaries into a data structure that Kaldi would accept - weighted finite state transducer (WFST). Among many scripts Kaldi provides, we will use `utils/prepare_lang.sh` to generate FST-ready data formats to represent our toy language.

```bash
utils/prepare_lang.sh --position-dependent-phones false $RAW_DICT_PATH $OOV $TEMP_DIR $OUTPUT_DIR
```
We're using `--position-dependent-phones` flag to be false in our tiny, tiny toy language. There's not enough context, anyways. For required parameters we will use: 

* `$RAW_DICT_PATH`: `dict`
* `$OOV`: `"<SIL>"` out-of-vocabulary token. Notice that quotation 
* `$TEMP_DIR`: Could be anywhere. I'll just put a new directory `tmp` inside `dict`.
* `$OUTPUT_DIR`: This output will be used in further training. Set it to `data/lang`.


### Building with the blocks: Language model

We provide a sample uni-gram language model for the yesno data. 
You'll find a `arpa` formatted [language model](lm/yesno-unigram.arpabo) inside `lm` directory (we'll learn more about language model formats later this semester).
However, again, the language model also needs to be converted into a WFST.
For that, Kaldi (specifically OpenFST library) also comes with a number of programs.
In this example, we will use `arpa2fst` program for conversion. We need to run 

```bash
arpa2fst --disambig-symbol="#0" --read-symbol-table=$WORDS_TXT $ARPA_LM $OUTPUT_FILE
```

with arguments, 
* `$WORDS_TXT`: path to the `words.txt` generated from `prepare_lang.sh`; `data/lang/words.txt`
* `$ARPA_LM`: the language model (arpa) file; `lm/yesno-unigram.arpabo`
* `$OUTPUT_FILE`: `data/lang/G.fst` G stands for *grammar*. 

## Step 3 - Feature extraction and training

This section will cover how to perform MFCC feature extraction and GMM-HMM modeling.

### Feature extraction

Once we have all data ready, it's time to extract features for acoustic model training.

First to extract mel-frequency cepstral coefficients.

```bash
steps/make_mfcc.sh --nj $N $INPUT_DIR $OUTPUT_DIR 
```

* `--nj $N` : number of processors, defaults to 4
* `$INPUT_DIR` : where we put our Kaldi-formatted 'data' of training set; `data/train_yesno`
* `$LOG_DIR` : let's put output to `exp/log/make_mfcc/train_yesno`, following Kaldi recipes convention.

Then normalize cepstral features

```bash
steps/compute_cmvn_stats.sh $INPUT_DIR $OUTPUT_DIR
```
Use `$INPUT_DIR` and `$OUTPUT_DIR` as the same as above.

**Note** that these shell scripts (`.sh`) are all utilizing Kaldi binaries with trivial text processing on the fly. To see which commands were actually executed, see log files in `<OUTPUT_DIR>`. Or even better, see inside the scripts. For details on specific Kaldi commands, refer to [the official documentation](http://kaldi-asr.org/doc/tools.html).

### Monophone model training

We will train a monophone model. In Kaldi, you always start GMM-HMM training with a monphone model to get a "*rough*" alignment between phones and their timing. This rough alignment will be used for accelerating triphone model training process. However with this toy language with 2 words (`YES`/`NO`) and 2 phone (`Y`/`N`), we don't go for triphone training. 

```bash 
steps/train_mono.sh --nj $N --cmd $MAIN_CMD $DATA_DIR $LANG_DIR $OUTPUT_DIR
```
* `--nj $N`: Utterances from a speaker cannot be processed in parallel. Since we have only one, we must use 1 job only. 
* `--cmd $MAIN_CMD`: To use local machine resources, use `"utils/run.pl"` pipeline.
* `$DATA_DIR`: Path to our 'training data'
* `$LANG_DIR`: Path to language definition (output from `prepare_lang` script)
* `$OUTPUT_DIR`: like the above, let's use `exp/mono`.

This will generate FST-based lattice for acoustic model. Kaldi provides a tool to see inside the model (which may not make much sense now).

```bash
/path/to/kaldi/src/fstbin/fstcopy 'ark:gunzip -c exp/mono/fsts.1.gz|' ark,t:- | head -n 20
```
This will print out first 20 lines of the lattice in human-readable(!!) format (Each column indicates: Q-from, Q-to, S-in, S-out, Weigh)

## Step 4 - Decoding and testing

This section will cover decoding of the model we trained.

### Merging all FST graphs for a decoder

Now we're done with acoustic model training. 
For testing, we need a new set of input that goes over our lattices of AM & LM. 
In step 1, we prepared separate testset in `data/test_yesno` for this purpose. 
Now it's time to project it into the feature space as well.
Use `steps/make_mfcc.sh` and `steps/compute_cmvn_stats.sh`.

Then, we need to build a fully connected FST network. 

```bash
utils/mkgraph.sh --mono data/lang exp/mono exp/mono/graph
```
This will build a connected HCLG (HMM + Context + Lexicon + Grammar) decoder in `exp/mono/graph` directory. 

Finally, we need to find the best paths for utterances in the test set, using decode script. Look inside the decode script, figure out what to give as its parameter, and run it. Write the decoding results in `exp/mono/decode_test_yesno`.

```bash 
steps/decode.sh SOME ARGUMENTS YOU NEED
```

This will end up with `lat.N.gz` files in the output directory, where N goes from 1 up to the number of jobs you used (which must be 1 for this task). These files contain lattices from utterances that were processed by N’th thread of your decoding operation.


### Looking at results

If you look inside the decoding script, it ends with calling the scoring script (`local/score.sh`), which generates hypotheses and computes word error rate of the testset. 
See `exp/mono/decode_test_yesno/wer_X` files to look the WER's, and `exp/mono/decode_test_yesno/scoring/X.tra` files for transcripts. 
`X` here indicates language model weight, *LMWT*, that scoring script used at each iteration to interpret the best paths for utterances in `lat.N.gz` files into word sequences.
(Remember `N` is #thread during decoding operation)
Transcripts (`.tra` files) are written with word symbols, not actual words. See `data/lang/words.txt` file for word-symbol mappings. 
You can deliberately specify the weight using `--min_lmwt` and `--max_lmwt` options when `score.sh` is called, if you want 
(Again, we'll cover what the LMWT and what it does later in the semester).

Or if you are interested in getting word-level alignment information for each recording file, take a look at `steps/get_ctm.sh` script.

## Programming Assignment #1

* Due: 1/24/2020 23:55
* Submit via github classroom
* No late submission accepted 

### Part 1 

* Finish [`data_prep.py`](#data-preparation)
* Write a *uber* script `run_yesno.sh` that runs the entire pipeline from running `data_prep.py` to running `decode.sh` and run it.
    * If you'd like, it's okay to write smaller scripts for sub-tasks then call them in the `run_yesno.sh` (use any language of your choice)
    * Make sure the pipeline script runs flawlessly and generates proper transcripts. You might want to write something to "*reset*" the working directory and call it first in the `run_yesno.sh` during debugging your script. 
* Commit your 
    * `data_prep.py`
    * `run_yesno.sh`
    * `path.sh`
    * Any other scripts you wrote as part of `run_yesno.sh`, if any
    * All files in `exp/mono/decode_test_yesno` after running `run_yesno.sh`
    * DO NOT commit other files (e.g. in `exp`, `data`, or `dict`). It will be wasting bandwidth, energy, and grader's hard drive space. 
* When ready, tag the commit as `part1` and push to `master`. 

### Part 2

* Modify any relevant part of you pipeline to use actual phonetic notations (with 5 phones) for these two Hebrew words, instead of dummy Y/N phones. For orthographic notation, use "*ken*" and "*lo*" (Let's not worry about unicode right now). This will also require editing the `arpabo` file. 
    * Pronunciations can be found on various resources, for example, [wiktionary](https://en.wiktionary.org/wiki/Wiktionary:Main_Page) can be helpful. 
* Figure out how to use `get_ctm.sh` to get alignment as well as hypotheses & WER scores, and add it to the pipeline script (`run_yesno.sh`). 
* Commit
    * Any changes in the pipeline and arpa
    * All files in `exp/mono/decode_test_yesno` after running the new pipeline. 
* When ready, tag the commit as `part2` and push to `master`. 


## Final notes on grading
* Don't forget to tag your commits. You can make as many commits as you like, however only two commits tagged as `part1` and `part2` will be graded. If the grader cannot checkout the tags, namely `git checkout part1` or `git checkout part2` returns non-zero, the part will not be graded. 
* Graders will use `bash` to run scripts. Make sure your `.sh` scripts are portable and bash compatible. [`shebang`](https://en.wikipedia.org/wiki/Shebang_(Unix)) line could be helpful. 
