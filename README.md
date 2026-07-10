# deaconizer

Minimal nf-core-style Nextflow pipeline for paired-end reads:

1. `fastp` read cleaning
2. `deacon index build` once per reference FASTA
3. `deacon filter` per sample
4. `kraken2` on Deacon-filtered reads
5. `kraut make-table` to merge all Kraken2 reports into one abundance table
6. `kraut plot-multi` to plot all Kraken2 reports together
7. `multiqc` report aggregation

## Input

CSV with columns `sample_id,reads_r1,reads_r2`. Use only letters, numbers, dots, underscores, and hyphens in `sample_id`.

```csv
sample_id,reads_r1,reads_r2
sample_a,/path/sample_a_R1.fastq.gz,/path/sample_a_R2.fastq.gz
```

## Run

```bash
nextflow run . -profile docker \
  --input samples.csv --ref reference.fasta --db /path/to/kraken2db --outdir results
```

Provide exactly one of `--ref` (a FASTA, indexed on the fly with `deacon index build`) or `--index` (a pre-built Deacon index file, e.g. produced by [`makedb.nf`](#makedbnf-building-a-masked-deacon-index)) — passing both, or neither, is an error:

```bash
nextflow run . -profile docker \
  --input samples.csv --index reference.deacon.index --db /path/to/kraken2db --outdir results
```

Swap `-profile docker` for `-profile singularity,slurm` on HPC, or `-profile docker,k8s` on Kubernetes (add `--k8s_storage_claim_name`, `--k8s_storage_mount_path`; samplesheet/reads/ref/index/db/work/outdir must all sit under the mounted PVC path).

Stub test (no real tools, checks wiring only):

```bash
nextflow run . -profile test,docker -stub-run
```

## Outputs

```text
{outdir}/reads/*.gz        Final polished reads (fastp-cleaned, Deacon-filtered)
{outdir}/report/fastp/     fastp HTML and JSON reports
{outdir}/report/deacon/    Deacon JSON summaries
{outdir}/report/kraken2/   Kraken2 TSV reports and classification output
{outdir}/report/kraut/     kraut merged abundance table and multi-sample plot
{outdir}/report/           MultiQC report and data directory
{outdir}/pipeline_info/    Nextflow execution reports
```

## Key parameters

| Param(s) | Default | Notes |
|---|---|---|
| `--deacon_kmer_length` / `--deacon_window_size` / `--deacon_entropy_threshold` | `31` / `15` / `0.0` | index build |
| `--deacon_abs_threshold` / `--deacon_rel_threshold` / `--deacon_prefix_length` / `--deacon_deplete` | `1` / `0.0` / `0` / `true` | filter |
| `--kraut_rank` / `--kraut_metric` | `S` / `TOT` | table + plot |
| `--kraut_plot_kind` / `--kraut_plot_ext` | `` (bar) / `png` | set `bubble` / `html` for interactive plot |
| `--multiqc_config` | `assets/multiqc_config.yaml` | branding, section order, column selection |

Extra tool args: `--fastp_args`, `--deacon_index_args`, `--deacon_filter_args`, `--kraken2_args`, `--kraut_maketable_args`, `--kraut_plotmulti_args`, `--multiqc_args`.

Kraut table/plot defaults are `--kraut_rank S` and `--kraut_metric TOT`. `kraut plot-multi` writes a stacked-bar PNG by default (`--kraut_plot_ext png`); set `--kraut_plot_kind bubble --kraut_plot_ext html` for an interactive bubble chart.

Pass additional tool arguments with `--fastp_args`, `--deacon_index_args`, `--deacon_filter_args`, `--kraken2_args`, `--kraut_maketable_args`, `--kraut_plotmulti_args`, and `--multiqc_args`.

MultiQC report branding and section layout are controlled by `assets/multiqc_config.yaml` (passed to MultiQC via `--config`). Override with `--multiqc_config /path/to/your.yaml` to customize the title, logo, or column selection.

## makedb.nf: building a masked Deacon index

Separate entry point for building a Deacon minimizer index from a reference FASTA, optionally masking out the minimizers found in a set of other genomes (e.g. to remove sequences shared with a host or with the organisms of interest before using the index for depletion).

```bash
nextflow run makedb.nf -profile docker \
  --ref reference.fasta --list mask.csv --outdir results
```

`--list` is optional. Its CSV requires columns `id,fasta_path`:

```csv
id,fasta_path
genome_a,/path/genome_a.fasta
genome_b,/path/genome_b.fasta
```

For each row, `genome_a`/`genome_b` are indexed, combined with `deacon index union`, and subtracted from the reference index with `deacon index diff`. If `--list` is omitted, the plain reference index is published unchanged.

Outputs:

```text
{outdir}/reference.deacon.index   Final (masked) Deacon index
{outdir}/masking_report.txt       Minimizer counts before/after masking
{outdir}/pipeline_info/           Nextflow execution reports
```

Stub test (no real tools, checks wiring only):

```bash
nextflow run makedb.nf -profile docker --ref reference.fasta --outdir results -stub-run
```
