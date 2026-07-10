process DEACON_INDEX_INFO {
    tag "${label}"
    label 'process_low'

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deacon:0.13.2--h7ef3eeb_1':
        'quay.io/biocontainers/deacon:0.13.2--h7ef3eeb_0' }"

    input:
    tuple val(label), path(index)

    output:
    tuple val(label), path("${label}.index_info.txt"), emit: info
    path 'versions.yml', emit: versions

    script:
    """
    deacon index info "${index}" > "${label}.index_info.txt" 2>&1

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deacon: \$(deacon --version 2>&1 || true)
    END_VERSIONS
    """

    stub:
    """
    cat <<-END_INFO > "${label}.index_info.txt"
    Index information:
      Format: exact (minimizer set)
      Format version: 1
      K-mer length (k): ${params.deacon_kmer_length}
      Window size (w): ${params.deacon_window_size}
      Distinct minimizer count: 0
    END_INFO

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deacon: stub
    END_VERSIONS
    """
}
