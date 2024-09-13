# minigraph-cactus-nf

A nextflow pipeline for running minigraph-cactus

## Introduction

**Update (13 Sept 2024)** New versions of cactus are able to run the full minigraph-cactus pipeline with a single command. Therefore, a nextflow pipeline like this one is really not necessary. I do not recommend using my pipeline anymore as it is written for an older version of cactus and does not work with better more recent versions. It's better and simpler to use the most recent version of cactus with its nice single command instead.

[minigraph-cactus][mgc] is a pipeline for making a pangenome graph out of
assemblies of genomes with too much shared variation for a phylogeny to make
sense, e.g., a set of assemblies of different individuals in the same species.
This nextflow pipeline automates it into a single command.

## Setup
This pipeline uses [nextflow][nf]. To learn more about how to run nextflow
pipelines like this one, check out [this quick introduction][warren-nf].

## Running
You just need a `seqFile` containing a list of paths to genome assemblies to
run this pipeline, and to specify one of them as the reference. See
[here][seqfile] for the format of the seqFile.

```bash
nextflow run WarrenLab/minigraph-cactus-nf \
    --seqFile [seqFile] \
    --reference [refname]
```

If it gets interrupted, you can have it resume where it left off with the
`-resume` flag. It will put the final output in `out/pangenome/`. Read the
[docs][mgc] to learn about the different files that are output.

### Arguments reference
#### Mandatory
* `--seqFile`: a tab-separated file where the first column is the name of a
  sequence and the second column is the path to that sequence. See cactus docs.
* `--reference`: the name of one of the sequences to use as a backbone

#### Optional
* `--maxAlignLength`: maximum alignment length for `cactus-align-batch` step.
  If not specified, a default of 10000 is used based on cactus documentation.
* `--chromosomesFile`: a text file containing chromosome names, one per line,
  that are present in the sequence specified as the reference. This can be
  useful because if the reference has lots of unplaced sequences, cactus spawns
  a set of jobs for each one, no matter how small. If you give it a list of
  chromosome names, it will instead run all of the unplaced sequence together
  as a single set of jobs.
* `--scratch`: path to an existing directory for Toil job data.
* `--jobStore`: path to which minigraph-cactus commands will write job data. This directory is created by Toil and must not already exist!

[mgc]: <https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/pangenome.md>
[nf]: <https://www.nextflow.io/>
[warren-nf]: <https://github.com/WarrenLab/docs/blob/main/nextflow.md>
[seqfile]: <https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/pangenome.md#interface>
