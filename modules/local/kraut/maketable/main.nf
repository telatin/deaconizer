process KRAUT_MAKETABLE {
    label 'process_low'

    publishDir "${params.outdir}/report/kraut", mode: params.publish_dir_mode, pattern: 'kraut_table.tsv'

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kraut%3A0.7.0--pyhdfd78af_0':
        'quay.io/biocontainers/kraut:0.7.0--pyhdfd78af_0' }"

    input:
    path(reports)

    output:
    path 'kraut_table.tsv', emit: table
    path 'versions.yml', emit: versions

    script:
    def args = task.ext.args ?: params.kraut_maketable_args ?: ''
    """
    kraut \\
        make-table \\
        --rank ${params.kraut_rank} \\
        --metric ${params.kraut_metric} \\
        --output kraut_table.tsv \\
        ${args} \\
        ${reports}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kraut: \$(kraut --version 2>&1 | sed 's/^kraut, version //' || true)
    END_VERSIONS
    """

    stub:
    """
    touch kraut_table.tsv
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kraut: stub
    END_VERSIONS
    """
}
