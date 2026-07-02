process DEACON_INDEX {
    tag "${fasta.baseName}"
    label 'process_high'

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deacon:0.13.2--h7ef3eeb_1':
        'quay.io/biocontainers/deacon:0.13.2--h7ef3eeb_0' }"

    input:
    path fasta

    output:
    path 'deacon_reference.idx', emit: index
    path 'versions.yml', emit: versions

    script:
    def args = task.ext.args ?: params.deacon_index_args ?: ''
    """
    deacon \\
        index \\
        build \\
        --threads ${task.cpus} \\
        ${args} \\
        "${fasta}" \\
        ${params.deacon_kmer_length} \\
        ${params.deacon_window_size} \\
        ${params.deacon_entropy_threshold} \\
        > deacon_reference.idx

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deacon: \$(deacon --version 2>&1 || true)
    END_VERSIONS
    """

    stub:
    """
    echo 'stub-index' > deacon_reference.idx
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deacon: stub
    END_VERSIONS
    """
}
