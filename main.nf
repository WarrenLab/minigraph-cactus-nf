#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

params.seqFile = ""
params.maxAlignLength = 10000
params.reference = ""
params.extraSplitArgs = ""

seqFile = file(params.seqFile)

process CACTUS_MINIGRAPH {
    input:
    path(seqFile)

    output:
    path("seqFile"), emit: modifiedSeqFile
    path("graph.gfa"), emit: graphGfa

    """
    cp $seqFile ./seqFile
    cactus-minigraph ./jobStore ./seqFile graph.gfa \
        --reference $params.reference --mapCores $task.cpus
    """
}

process CACTUS_GRAPHMAP {
    input:
    path(seqFile)
    path(graphGfa)

    output:
    path("alignment.paf"), emit: alignmentPaf
    path("graph.gfa.fa"), emit: graphFasta

    """
    cactus-graphmap ./jobStore $seqFile $graphGfa alignment.paf \
        --outputFasta graph.gfa.fa \
        --reference $params.reference --mapCores $task.cpus
    """
}

process CACTUS_GRAPHMAP_SPLIT {
    input:
    path(seqFile)
    path("graph.gfa")
    path("graph.gfa.fa")
    path("alignment.paf")

    output:
    path("chroms/")

    """
    cactus-graphmap-split ./jobStore $seqFile graph.gfa alignment.paf \
        --reference $params.reference --outDir chroms $params.extraSplitArgs
    """
}

process CACTUS_ALIGN_BATCH {
    input:
    path(chromsDir)

    output:
    path("chrom-alignments/")

    """
    cactus-align-batch ./jobStore ${chromsDir}/chromfile.txt chrom-alignments \
        --alignCores $task.cpus \
        --alignOptions "--pangenome --reference $params.reference \
                        --outVG --maxLen $params.maxAlignLength"
    """
}

process CACTUS_GRAPHMAP_JOIN {
    input:
    path(chromAlignments)

    output:
    path("pangenome/")

    """
    cactus-graphmap-join ./jobStore \
        --vg $chromAlignments/*.vg \
        --hal $chromAlignments/*.hal \
        --outDir ./pangenome --outName pangenome \
        --reference $params.reference --vcf --giraffe \
        --indexCores ${task.cpus - 1}
    """
}

workflow {
    CACTUS_GRAPHMAP(CACTUS_MINIGRAPH(seqFile))
    CACTUS_GRAPHMAP_SPLIT(
        CACTUS_MINIGRAPH.out.modifiedSeqFile,
        CACTUS_MINIGRAPH.out.graphGfa,
        CACTUS_GRAPHMAP.out.graphFasta,
        CACTUS_GRAPHMAP.out.alignmentPaf
    )
    CACTUS_ALIGN_BATCH(CACTUS_GRAPHMAP_SPLIT.out)
    CACTUS_GRAPHMAP_JOIN(CACTUS_ALIGN_BATCH.out)
}
