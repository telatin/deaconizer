process DEACON_MASKING_REPORT {
    tag "masking_report"
    label 'process_low'

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deacon:0.13.2--h7ef3eeb_1':
        'quay.io/biocontainers/deacon:0.13.2--h7ef3eeb_0' }"

    publishDir "${params.outdir}", mode: params.publish_dir_mode

    input:
    path before_info
    path after_info

    output:
    path 'masking_report.txt', emit: report

    script:
    """
    extract_count() {
        grep -oP '(Distinct minimizer count|Key count):\\s*\\K[0-9]+' "\$1" | head -n1 || true
    }

    before_count=\$(extract_count "${before_info}")
    after_count=\$(extract_count "${after_info}")
    before_count=\${before_count:-0}
    after_count=\${after_count:-0}

    removed=\$(( before_count - after_count ))
    if [ "\${before_count}" -gt 0 ]; then
        pct=\$(awk -v b="\${before_count}" -v r="\${removed}" 'BEGIN { printf "%.2f", (r / b) * 100 }')
    else
        pct="0.00"
    fi

    {
        echo "Deacon masking report"
        echo "======================"
        echo ""
        echo "Reference index (before masking):"
        sed 's/^/  /' "${before_info}"
        echo ""
        echo "Reference index (after masking):"
        sed 's/^/  /' "${after_info}"
        echo ""
        echo "Summary:"
        echo "  Minimizers before masking: \${before_count}"
        echo "  Minimizers after masking:  \${after_count}"
        echo "  Minimizers removed:        \${removed} (\${pct}%)"
    } > masking_report.txt
    """

    stub:
    """
    cat <<-END_REPORT > masking_report.txt
    Deacon masking report
    ======================
    stub run - no real counts computed
    END_REPORT
    """
}
