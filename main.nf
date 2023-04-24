#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

/*
 * Parameters
 */
// Mandatory parameters
params.seqFile = ""
params.reference = ""

// Optional parameters
params.maxAlignLength = 10000
params.chromosomesFile = ""
params.scratch = ""
params.additionalToilParams = ""

if (params.seqFile == "" || params.reference == "")
{
    println "Must specify --seqFile and --reference. See README for details."
    System.exit(1)
}

seqFile = file(params.seqFile)

extraSplitArgs = ""
if (params.chromosomesFile != "")
{
    chromosomesFile = file(params.chromosomesFile)
    extraSplitArgs = "--refContigsFile $chromosomesFile --otherContig Un"
}

additionalToilParams = "$params.additionalToilParams"
if (params.scratch != "")
{
    additionalToilParams += " --workDir $params.scratch"
}

process CACTUS_MINIGRAPH {
    input:
    path(seqFile)

    output:
    path("seqFile"), emit: modifiedSeqFile
    path("graph.gfa"), emit: graphGfa

    """
    cp $seqFile ./seqFile
    cactus-minigraph ./jobStore ./seqFile graph.gfa \
        $additionalToilParams \
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
        $additionalToilParams \
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
        $additionalToilParams \
        --reference $params.reference --outDir chroms $extraSplitArgs
    """
}

process CACTUS_ALIGN_BATCH {
    input:
    path(chromsDir)

    output:
    path("chrom-alignments/")

    """
    cactus-align-batch ./jobStore ${chromsDir}/chromfile.txt chrom-alignments \
        $additionalToilParams \
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
        $additionalToilParams \
        --vg $chromAlignments/*.vg \
        --hal $chromAlignments/*.hal \
        --outDir ./pangenome --outName pangenome \
        --reference $params.reference --vcf --giraffe \
        --indexCores ${task.cpus - 1} \
        --giraffe full clip filter
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
