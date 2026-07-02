process KRAKEN2 {
    tag "${meta.id}"
    label 'process_high'

    publishDir "${params.outdir}/report/kraken2", mode: params.publish_dir_mode, pattern: '*.kraken2.*'

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/0f/0f827dcea51be6b5c32255167caa2dfb65607caecdc8b067abd6b71c267e2e82/data' :
        'community.wave.seqera.io/library/kraken2_coreutils_pigz:920ecc6b96e2ba71' }"

    input:
    tuple val(meta), path(reads_r1), path(reads_r2), path(db)

    output:
    tuple val(meta), path("${meta.id}.kraken2.report.tsv"), emit: report
    tuple val(meta), path("${meta.id}.kraken2.output.txt"), emit: output
    path 'versions.yml', emit: versions

    script:
    def args = task.ext.args ?: params.kraken2_args ?: ''
    """
    kraken2 \\
        --db "${db}" \\
        --threads ${task.cpus} \\
        --paired \\
        --gzip-compressed \\
        --report "${meta.id}.kraken2.report.tsv" \\
        --output "${meta.id}.kraken2.output.txt" \\
        ${args} \\
        "${reads_r1}" "${reads_r2}"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kraken2: \$(kraken2 --version 2>&1 | sed -n 's/^Kraken version //p' || true)
    END_VERSIONS
    """

    stub:
    """
    echo -e '100.00\\t0\\t0\\tU\\t0\\tunclassified' > "${meta.id}.kraken2.report.tsv"
    touch "${meta.id}.kraken2.output.txt"
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kraken2: stub
    END_VERSIONS
    """
}
