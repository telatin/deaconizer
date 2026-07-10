process DEACON_INDEX_UNION {
    tag "union"
    label 'process_medium'

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deacon:0.13.2--h7ef3eeb_1':
        'quay.io/biocontainers/deacon:0.13.2--h7ef3eeb_0' }"

    input:
    path indexes

    output:
    path 'all-masked.deacon.index', emit: index
    path 'versions.yml', emit: versions

    script:
    """
    deacon \\
        index \\
        union \\
        ${indexes.collect { '"' + it + '"' }.join(' ')} \\
        > all-masked.deacon.index

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deacon: \$(deacon --version 2>&1 || true)
    END_VERSIONS
    """

    stub:
    """
    echo 'stub-union' > all-masked.deacon.index
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deacon: stub
    END_VERSIONS
    """
}
