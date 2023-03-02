# minigraph-cactus-nf

A nextflow pipeline for running cactus-minigraph.

## Introduction

[minigraph-cactus][mgc] is a pipeline for making a pangenome graph out of
assemblies of genomes with too much shared variation for a phylogeny to make
sense, e.g., a set of assemblies of different individuals in the same species.
This nextflow pipeline automates it into a single command.

## Setup

You only need [nextflow][nf] to run this pipeline. You *do not* need to
clone this repository or otherwise download the code to run it. Nextflow does
that for you. To install nextflow, just run
`curl -s https://get.nextflow.io | bash` and put the binary it creates
somewhere in your path.

If you are running this on the lewis cluster at MU, the default configuration
should work. Otherwise, you will have to write your own configuration file to
give nextflow some basic details about your setup (e.g., cluster or local?
docker or singularity?). You can use `nextflow.config` in this repository as a
starting point and read about configuring nextflow in its
[documentation][nf-config].

## Running

You just need a `seqFile` containing a list of paths to genome assemblies to
run this pipeline, and to specify one of them as the reference. See
[here][seqfile] for the format of the seqFile.

```bash
nextflow run WarrenLab/minigraph-cactus-nf -latest \
    --seqFile [seqFile] \
    --reference [refname]
```

If it gets interrupted, you can have it resume where it left off with the
`-resume` flag. It will put the final output in `out/pangenome/`. Read the
[docs][mgc] to learn about the different files that are output.

[mgc]: <https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/pangenome.md>
[nf]: <https://www.nextflow.io/>
[nf-config]: <https://www.nextflow.io/docs/latest/config.html>
[seqfile]: <https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/pangenome.md#interface>
