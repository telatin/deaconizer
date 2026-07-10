process DEACON_INDEX_DIFF {
    tag "diff"
    label 'process_medium'

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deacon:0.13.2--h7ef3eeb_1':
        'quay.io/biocontainers/deacon:0.13.2--h7ef3eeb_0' }"

    input:
    tuple path(ref_index), path(mask_index)

    output:
    path 'reference.masked.deacon.idx', emit: index
    path 'versions.yml', emit: versions

    script:
    """
    deacon \\
        index \\
        diff \\
        --threads ${task.cpus} \\
        "${ref_index}" \\
        "${mask_index}" \\
        > reference.masked.deacon.idx

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deacon: \$(deacon --version 2>&1 || true)
    END_VERSIONS
    """

    stub:
    """
    echo 'stub-diff' > reference.masked.deacon.idx
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deacon: stub
    END_VERSIONS
    """
}
