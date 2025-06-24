configfile: "config.yaml"

RAW_DIR   = config["raw_dir"]
THREADS   = config["threads"]
MEM_MB    = config["mem_mb"]
SRR_LIST  = config["srr_list_file"]

with open(SRR_LIST) as f:
    SAMPLES = [line.strip() for line in f if line.strip()]


rule all:
    input:
        # compressed FASTQs
        expand(f"{RAW_DIR}/{{srr}}_1.fastq.gz", srr=SAMPLES),
        expand(f"{RAW_DIR}/{{srr}}_2.fastq.gz", srr=SAMPLES),

        # fastp outputs (cleaned FASTQs + QC reports)
        expand("results/fastp/{srr}_1.clean.fastq.gz", srr=SAMPLES),
        expand("results/fastp/{srr}_2.clean.fastq.gz", srr=SAMPLES),
        expand("results/fastp/{srr}_fastp.html",     srr=SAMPLES),
        expand("results/fastp/{srr}_fastp.json",     srr=SAMPLES),

        # final aggregated report
        "results/multiqc/multiqc_report.html",
        expand("results/metaphlan/{srr}_profile.txt", srr=SAMPLES)



rule prefetch:
    output:
        temp("data/sra/{srr}/{srr}.sra")
    shell:
        """
        prefetch {wildcards.srr} -O data/sra
        """


rule fasterq_dump:
    input:
        "data/sra/{srr}/{srr}.sra"
    output:
        temp("data/fq/{srr}_1.fastq"),
        temp("data/fq/{srr}_2.fastq")
    threads: THREADS
    resources:
        mem_mb=MEM_MB
    shell:
        """
        fasterq-dump --split-files --threads {threads} {input} -O data/fq
        """


rule compress:
    input:
        r1="data/fq/{srr}_1.fastq",
        r2="data/fq/{srr}_2.fastq"
    output:
        r1=f"{RAW_DIR}/{{srr}}_1.fastq.gz",
        r2=f"{RAW_DIR}/{{srr}}_2.fastq.gz"
    shell:
        """
        pigz -p 2 -1 {input.r1}
        pigz -p 2 -1 {input.r2}
        mv {input.r1}.gz {output.r1}
        mv {input.r2}.gz {output.r2}
        """


rule fastp:
    input:
        r1 = f"{RAW_DIR}/{{srr}}_1.fastq.gz",
        r2 = f"{RAW_DIR}/{{srr}}_2.fastq.gz"
    output:
        r1   = "results/fastp/{srr}_1.clean.fastq.gz",
        r2   = "results/fastp/{srr}_2.clean.fastq.gz",
        html = "results/fastp/{srr}_fastp.html",
        json = "results/fastp/{srr}_fastp.json"
    threads: THREADS
    shell:
        """
        fastp \
            -i {input.r1} -I {input.r2} \
            -o {output.r1} -O {output.r2} \
            --html {output.html} --json {output.json} \
            -w {threads}
        """

rule multiqc:
    input:
        # gather all per-sample fastp reports
        expand("results/fastp/{srr}_fastp.json", srr=SAMPLES)+
        expand("results/fastp/{srr}_fastp.html", srr=SAMPLES)
    output:
        html="results/multiqc/multiqc_report.html"
    shell:
        """multiqc results/fastp \
            -o results/multiqc \
            --filename multiqc_report.html \
            --force 
        """
rule metaphlan:
    input:
        r1 = f"{RAW_DIR}/{{srr}}_1.fastq.gz",
        r2 = f"{RAW_DIR}/{{srr}}_2.fastq.gz"
    output:
        "results/metaphlan/{srr}_profile.txt"
    threads: THREADS
    shell:
        """
        metaphlan {input.r1}, {input.r2} \
        --input_type fastq \
        --bowtie2out results/metaphlan/{wildcards.srr}_bowtie2.bz2 \
        --nproc {threads} > {output}
        """

