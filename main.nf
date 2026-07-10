#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { FASTP        } from './modules/local/fastp/main'
include { DEACON_INDEX } from './modules/local/deacon/index/main'
include { DEACON_FILTER } from './modules/local/deacon/filter/main'
include { KRAKEN2      } from './modules/local/kraken2/main'
include { KRAUT_MAKETABLE } from './modules/local/kraut/maketable/main'
include { KRAUT_PLOTMULTI } from './modules/local/kraut/plotmulti/main'
include { MULTIQC      } from './modules/local/multiqc/main'

workflow {
    if (!params.input) {
        error 'Missing required parameter: --input CSV_FILE'
    }
    if (!params.ref) {
        error 'Missing required parameter: --ref REFERENCE_FASTA'
    }
    if (!params.db) {
        error 'Missing required parameter: --db KRAKEN2_DB'
    }

    def active_profiles = (workflow.profile ?: '').tokenize(',')*.trim()
    if (active_profiles.contains('k8s') && !params.k8s_storage_claim_name) {
        error 'The k8s profile requires --k8s_storage_claim_name NAME and a work directory on the mounted PVC, for example -w /workspace/work'
    }

    Channel
        .fromPath(params.input, checkIfExists: true)
        .splitCsv(header: true)
        .map { row ->
            def required = ['sample_id', 'reads_r1', 'reads_r2']
            required.each { column ->
                if (!row.containsKey(column)) {
                    error "Input CSV must contain columns: ${required.join(', ')}"
                }
            }

            def sample_id = row.sample_id?.toString()?.trim()
            def reads_r1  = row.reads_r1?.toString()?.trim()
            def reads_r2  = row.reads_r2?.toString()?.trim()

            if (!sample_id || !reads_r1 || !reads_r2) {
                error "Invalid input row. Required non-empty fields: ${required.join(', ')}"
            }
            if (!(sample_id ==~ /^[A-Za-z0-9_.-]+$/)) {
                error "Invalid sample_id '${sample_id}'. Use only letters, numbers, dots, underscores, and hyphens."
            }

            tuple([id: sample_id], file(reads_r1), file(reads_r2))
        }
        .ifEmpty { error "Input CSV contains no samples: ${params.input}" }
        .set { reads_ch }

    ref_ch = Channel.fromPath(params.ref, checkIfExists: true)
    db_ch  = Channel.fromPath(params.db, checkIfExists: true, type: 'any')

    FASTP(reads_ch)
    DEACON_INDEX(ref_ch)
    DEACON_FILTER(FASTP.out.reads.combine(DEACON_INDEX.out.index))
    KRAKEN2(DEACON_FILTER.out.reads.combine(db_ch))

    kraken2_reports_ch = KRAKEN2.out.report
        .toSortedList { a, b -> a[0].id <=> b[0].id }
        .map { pairs -> pairs.collect { meta, report -> report } }

    KRAUT_MAKETABLE(kraken2_reports_ch)
    KRAUT_PLOTMULTI(kraken2_reports_ch)

    FASTP.out.json
        .map { meta, json -> json }
        .mix(FASTP.out.html.map { meta, html -> html })
        .mix(DEACON_FILTER.out.summary.map { meta, summary -> summary })
        .mix(KRAKEN2.out.report.map { meta, report -> report })
        .collect()
        .set { multiqc_files_ch }

    multiqc_config_ch = Channel.fromPath(params.multiqc_config, checkIfExists: true)

    MULTIQC(multiqc_files_ch, multiqc_config_ch)
}

workflow.onComplete {
    if (workflow.success) {
        log.info "Pipeline completed successfully. Results: ${params.outdir}"
    } else {
        log.info "Pipeline completed with errors. Check the Nextflow log for details."
    }
}
