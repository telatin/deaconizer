process DEACON_FILTER {
    tag "${meta.id}"
    label 'process_medium'

    publishDir "${params.outdir}/reads/deacon", mode: params.publish_dir_mode, pattern: '*.deacon.R*.fq.gz'
    publishDir "${params.outdir}/report/deacon", mode: params.publish_dir_mode, pattern: '*.deacon.json'

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deacon:0.13.2--h7ef3eeb_1':
        'quay.io/biocontainers/deacon:0.13.2--h7ef3eeb_0' }"

    input:
    tuple val(meta), path(reads_r1), path(reads_r2), path(index)

    output:
    tuple val(meta), path("${meta.id}.deacon.R1.fq.gz"), path("${meta.id}.deacon.R2.fq.gz"), emit: reads
    tuple val(meta), path("${meta.id}.deacon.json"), emit: summary
    path 'versions.yml', emit: versions

    script:
    def extra_args = task.ext.args ?: params.deacon_filter_args ?: ''
    def deplete = params.deacon_deplete ? '--deplete' : ''
    def read_type = params.deacon_read_type ?: ''
    def args = [
        "--abs-threshold ${params.deacon_abs_threshold}",
        "--rel-threshold ${params.deacon_rel_threshold}",
        "--prefix-length ${params.deacon_prefix_length}",
        deplete,
        extra_args
    ].findAll { it?.toString()?.trim() }.join(' ')
    """
    deacon \\
        filter \\
        --threads ${task.cpus} \\
        ${args} \\
        --summary "${meta.id}.deacon.json" \\
        --output "${meta.id}.deacon.R1.fq.gz" \\
        --output2 "${meta.id}.deacon.R2.fq.gz" \\
        "${index}" \\
        "${reads_r1}" \\
        "${reads_r2}" ${read_type}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deacon: \$(deacon --version 2>&1 || true)
    END_VERSIONS
    """

    stub:
    """
    touch "${meta.id}.deacon.R1.fq.gz"
    touch "${meta.id}.deacon.R2.fq.gz"
    echo '{}' > "${meta.id}.deacon.json"
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deacon: stub
    END_VERSIONS
    """
}
