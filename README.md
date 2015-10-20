# Kaldi Tutorial

This tutorial will guide you some basic functionalities and operations of [Kaldi](http://kaldi-asr.org/) ASR toolkit.

## Step 1 - Data preparation

This section will cover how to prepare data formats to train and test Kaldi recognizer.

### Data description

Our dataset for this tutorial has 60 `.wav` files, sampled at 8 kHz.
All audio files are recored by an anonymous male contributor of Kaldi project and included in the project for a test purpose. 
We put them in [`waves_yesno`](waves_yesno) directory, but the dataset also can be found [here](http://openslr.org/resources/1/waves_yesno.tar.gz).
In each file, the individual says 8 words; each word is either "ken" or "lo" ("yes" and "no" in Hebrew), so each file is a random sequence of 8 yes-es or noes.  
Although no separate transcription is provided, the names of files represent the sequence, with 1 for yes and 0 for no.

```bash
waves_yesno/1_0_1_1_1_0_1_0.wav
waves_yesno/0_1_1_0_0_1_1_0.wav
...
```
This is all we have as our raw data. Now we will deform these `.wav` files into data format that Kaldi can read in.


### Data preparation

Let's start with formatting data. We will split 60 wave files roughly into half, 29 for training, the rest for testing. Create a directory `data` and put two subdirectories `train_yesno` and `test_yesno` in it. 

We will prototype a python script to generate necessary input files. Start a python script in tutorial root directory, that 

1. reads up the list of files in `waves_yesno`.
1. generates two list, one stores names of files that start with 0's, the other keeps names starting with 1's, ignore the rest of files.

Now, for each dataset, we need to generate these input files.

* `text`
    * Essentially, transcriptions.
    * An utternace per line, `<(speaker_id-)utt_id> <transcription>` 
    * We will use filenames without extensions as utt_ids
    * No speaker_id for now.
    * Although recordings are in Hebrew, we will use English words, YES and NO, to avoid comlicating the problem.
* `wav.scp`
    * Indexing files to unique ids. 
    * `<recording_id> <wave filename with path OR command to get wave file>`
    * Again, we can use file names as recording_ids.
* `utt2spk`
    * For each utterance, mark which speaker spoke it.
    * `<utt_id> <speaker_id>`
    * Since we have only one speaker in this example, let's use "global" as speaker_id
* ~~(optional) `segments`~~: beyond this tutorial's scope
* ~~(optional) `reco2file_and_channel`~~: beyond this tutorial's scope
* `spk2utt`
    * simply reversing `utt2spk` (`<speaker_id> <all_utterences>`)
    * can use a Kaldi util to generate
    * e.g. `utils/utt2spk_to_spk2utt.pl data/train_yesno/utt2spk > data/train_yesno/spk2utt`

Write methods to generate each set of 4 files, using the lists of file names, put files in corresponding directories. (`data/train_yesno`, `data/test_yesno`)

**Note** all files should be sorted. (`sort file > file.sorted`) It's Kaldi I/O requirement. Also if you're using unix `sort`, don't forget, before sorting, to set locale to `C` (`export LC_ALL=C`) for C/C++ compatibility (This is default behavior in Python).

## Continue to next step