# Kaldi Tutorial

This tutorial will guide you some basic functionalities and operations of [Kaldi](http://kaldi-asr.org/) ASR toolkit.

## Requirements

Kaldi will run on POSIX systems, with these softwares installed.

* `wget`
* GNU build tools: `libtoolize`, `autoconf`, `automake`
* `git`

This tutorial also includes a number of python code.

## Installation 

Once you have all required build tools, compiling Kaldi is pretty straightforward. First you need to download Kaldi from the repository.

```bash
git clone https://github.com/kaldi-asr/kaldi.git kaldi-trunk /path/you/want
cd /path/you/want
```

Assuming you are in the downloaded directory, you need to perform `make` in two directories: `tools`, and `src`

```bash
cd tools/
make
cd ../src
./configure
make depend
make
```

