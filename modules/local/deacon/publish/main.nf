process DEACON_PUBLISH_INDEX {
    tag "${index.baseName}"
    label 'process_low'

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deacon:0.13.2--h7ef3eeb_1':
        'quay.io/biocontainers/deacon:0.13.2--h7ef3eeb_0' }"

    publishDir "${params.outdir}", mode: params.publish_dir_mode

    input:
    path index

    output:
    path 'reference.deacon.index', emit: index

    script:
    """
    cp -f "${index}" reference.deacon.index
    """

    stub:
    """
    cp -f "${index}" reference.deacon.index
    """
}
