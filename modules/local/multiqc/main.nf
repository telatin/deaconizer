process MULTIQC {
    label 'process_low'

    publishDir "${params.outdir}/report", mode: params.publish_dir_mode, pattern: 'multiqc*'

    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/12/1297c0f5075c19486da167ebf1b6136907d6b5339697b87b29fda335221785b3/data'
        : 'community.wave.seqera.io/library/multiqc:1.35--839587b417d23042'}"

    input:
    path multiqc_files
    path multiqc_config

    output:
    path 'multiqc_report.html', emit: report
    path 'multiqc_report_data', emit: data
    path 'versions.yml', emit: versions

    script:
    def args = task.ext.args ?: params.multiqc_args ?: ''
    """
    multiqc . \\
        --filename multiqc_report.html \\
        --outdir . \\
        --config "${multiqc_config}" \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$(multiqc --version 2>&1 | sed 's/^multiqc, version //')
    END_VERSIONS
    """

    stub:
    """
    mkdir -p multiqc_report_data
    echo '<html><body>MultiQC stub</body></html>' > multiqc_report.html
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: stub
    END_VERSIONS
    """
}
