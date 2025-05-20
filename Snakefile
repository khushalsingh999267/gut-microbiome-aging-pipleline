# Snakefile

# 1) Tell Snakemake where to load config from
configfile: "config.yaml"

# 2) Read config parameters
RAW    = config["raw_dir"]
THREADS = int(config["threads"])
MEM_MB  = int(config["mem_mb"])

# 3) Load your SRR IDs
with open(config["srr_list_file"]) as fh:
    SAMPLES = [l.strip() for l in fh if l.strip()]

# 4) all → both R1 and R2 for every sample
rule all:
    input:
        expand("{raw}/{srr}_{pair}.fastq.gz",
               raw=RAW,
               srr=SAMPLES,
               pair=[1,2])

# 5) Download .sra (almost no RAM)
rule prefetch:
    output: f"{RAW}/{{srr}}.sra"
    resources:
        mem_mb=MEM_MB
    shell:
        """
        prefetch --max-size 50G \
                 --output-file {output} \
                 {wildcards.srr}
        """

# 6) Convert to paired FASTQ + gzip (capped at MEM_MB, THREADS)
rule fasterq_dump:
    input:  f"{RAW}/{{srr}}.sra"
    output:
        r1=f"{RAW}/{{srr}}_1.fastq.gz",
        r2=f"{RAW}/{{srr}}_2.fastq.gz"
    threads: THREADS
    resources:
        mem_mb=MEM_MB
    shell:
        r"""
        fasterq-dump {input} \
            --split-files \
            --threads {threads} \
            --mem {resources.mem_mb}000000 \
            -O {RAW}

        pigz -p {threads} -1 {RAW}/{wildcards.srr}_1.fastq
        pigz -p {threads} -1 {RAW}/{wildcards.srr}_2.fastq

        mv {RAW}/{wildcards.srr}_1.fastq.gz {output.r1}
        mv {RAW}/{wildcards.srr}_2.fastq.gz {output.r2}
        """
