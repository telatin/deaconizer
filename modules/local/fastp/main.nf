process FASTP {
    tag "${meta.id}"
    label 'process_medium'

    publishDir "${params.outdir}/reads/fastp", mode: params.publish_dir_mode, pattern: '*.fastp.R*.fastq.gz'
    publishDir "${params.outdir}/report/fastp", mode: params.publish_dir_mode, pattern: '*.fastp.{html,json}'

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/55/556474e164daf5a5e218cd5d497681dcba0645047cf24698f88e3e078eacbd09/data' :
        'community.wave.seqera.io/library/fastp:1.1.0--08aa7c5662a30d57' }"

    input:
    tuple val(meta), path(reads_r1), path(reads_r2)

    output:
    tuple val(meta), path("${meta.id}.fastp.R1.fastq.gz"), path("${meta.id}.fastp.R2.fastq.gz"), emit: reads
    tuple val(meta), path("${meta.id}.fastp.json"), emit: json
    tuple val(meta), path("${meta.id}.fastp.html"), emit: html
    path 'versions.yml', emit: versions

    script:
    def args = task.ext.args ?: params.fastp_args ?: ''
    """
    fastp \\
        -i "${reads_r1}" \\
        -I "${reads_r2}" \\
        -o "${meta.id}.fastp.R1.fastq.gz" \\
        -O "${meta.id}.fastp.R2.fastq.gz" \\
        --json "${meta.id}.fastp.json" \\
        --html "${meta.id}.fastp.html" \\
        --detect_adapter_for_pe \\
        -w ${task.cpus} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastp: \$(fastp --version 2>&1 | sed 's/^fastp //')
    END_VERSIONS
    """

    stub:
    """
    touch "${meta.id}.fastp.R1.fastq.gz"
    touch "${meta.id}.fastp.R2.fastq.gz"
    echo '{}' > "${meta.id}.fastp.json"
    echo '<html><body>fastp stub</body></html>' > "${meta.id}.fastp.html"
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastp: stub
    END_VERSIONS
    """
}
