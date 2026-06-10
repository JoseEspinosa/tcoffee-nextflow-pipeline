process TCOFFEE {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/t-coffee_tmalign_pigz:f861f2f8f266c2fe':
        'community.wave.seqera.io/library/t-coffee_tmalign_pigz:be7dac2ae6aba380' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("${prefix}.aln"),             emit: alignment
    tuple val(meta), path("${prefix}.score_ascii"),     emit: score_ascii, optional: true
    tuple val(meta), path("${prefix}.html"),            emit: html,        optional: true
    tuple val(meta), path("${prefix}.dnd"),             emit: guide_tree,  optional: true

    tuple val("${task.process}"), val('tcoffee'), eval('t_coffee -version | awk \'{gsub("Version_", ""); print \\$3}\''), emit: versions_tcoffee, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    prefix     = task.ext.prefix ?: "${meta.id}"
    """
    export TEMP='./'
    export TMP_4_TCOFFEE="./"
    export HOME="./"

    t_coffee \\
        -in ${fasta} \\
        -outfile ${prefix}.aln \\
        -quiet=stdout

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tcoffee: \$(t_coffee -version 2>&1 | grep 'Version_' | head -1 | sed 's/.*Version_//;s/ .*//')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Otherwise, tcoffee will crash when calling its version
    export TEMP='./'
    export TMP_4_TCOFFEE="./"
    export HOME="./"

    touch ${prefix}.aln
    touch ${prefix}.score_ascii
    touch ${prefix}.html
    touch ${prefix}.dnd
    """
}
