#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { DEACON_INDEX                                  } from './modules/local/deacon/index/main'
include { DEACON_INDEX as DEACON_INDEX_MASK             } from './modules/local/deacon/index/main'
include { DEACON_INDEX_UNION                            } from './modules/local/deacon/index_union/main'
include { DEACON_INDEX_DIFF                             } from './modules/local/deacon/index_diff/main'
include { DEACON_INDEX_INFO as DEACON_INDEX_INFO_BEFORE } from './modules/local/deacon/index_info/main'
include { DEACON_INDEX_INFO as DEACON_INDEX_INFO_AFTER  } from './modules/local/deacon/index_info/main'
include { DEACON_MASKING_REPORT                         } from './modules/local/deacon/report/main'
include { DEACON_PUBLISH_INDEX                          } from './modules/local/deacon/publish/main'

workflow {
    if (!params.ref) {
        error 'Missing required parameter: --ref REFERENCE_FASTA'
    }

    def active_profiles = (workflow.profile ?: '').tokenize(',')*.trim()
    if (active_profiles.contains('k8s') && !params.k8s_storage_claim_name) {
        error 'The k8s profile requires --k8s_storage_claim_name NAME and a work directory on the mounted PVC, for example -w /workspace/work'
    }

    ref_ch = Channel.fromPath(params.ref, checkIfExists: true)
    DEACON_INDEX(ref_ch)
    ref_index_ch = DEACON_INDEX.out.index

    if (params.list) {
        Channel
            .fromPath(params.list, checkIfExists: true)
            .splitCsv(header: true)
            .map { row ->
                def required = ['id', 'fasta_path']
                required.each { column ->
                    if (!row.containsKey(column)) {
                        error "Mask list CSV must contain columns: ${required.join(', ')}"
                    }
                }

                def id         = row.id?.toString()?.trim()
                def fasta_path = row.fasta_path?.toString()?.trim()

                if (!id || !fasta_path) {
                    error "Invalid mask list row. Required non-empty fields: ${required.join(', ')}"
                }

                file(fasta_path, checkIfExists: true)
            }
            .ifEmpty { error "Mask list CSV contains no entries: ${params.list}" }
            .set { mask_fasta_ch }

        DEACON_INDEX_MASK(mask_fasta_ch)

        mask_indexes_ch = DEACON_INDEX_MASK.out.index.collect()

        DEACON_INDEX_UNION(mask_indexes_ch)
        DEACON_INDEX_DIFF(ref_index_ch.combine(DEACON_INDEX_UNION.out.index))

        final_index_ch = DEACON_INDEX_DIFF.out.index
    } else {
        final_index_ch = ref_index_ch
    }

    DEACON_INDEX_INFO_BEFORE(ref_index_ch.map { index -> tuple('reference', index) })
    DEACON_INDEX_INFO_AFTER(final_index_ch.map { index -> tuple('masked', index) })

    DEACON_MASKING_REPORT(
        DEACON_INDEX_INFO_BEFORE.out.info.map { label, info -> info },
        DEACON_INDEX_INFO_AFTER.out.info.map { label, info -> info }
    )

    DEACON_PUBLISH_INDEX(final_index_ch)
}

workflow.onComplete {
    if (workflow.success) {
        log.info "Pipeline completed successfully. Results: ${params.outdir}"
    } else {
        log.info "Pipeline completed with errors. Check the Nextflow log for details."
    }
}
