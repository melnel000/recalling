#!/usr/bin/env nextflow

in_files = params.in_files
out_dir = file(params.out_dir)

Channel.fromFilePairs(in_files)
        { file ->
          b = file.baseName
          m = b =~ /(.*)\.vcf.*/
          return m[0][1]
        }.into { vcfs1 ; vcfs2 }


process filter_short_snps_indels {
    tag { "${params.project_name}.${params.cohort_id}.fSSI" }
    publishDir "${out_dir}/${params.cohort_id}/filter-vcf", mode: 'copy', overwrite: false
    input:
      set val (file_name), file (vcf) from vcfs1
    output:
    file("${filebase}.filter-pass.vcf.gz") into vcf_short_out

    script:
    filebase = (file(vcf[0].baseName)).baseName
    """
    ${params.bcftools_base}/bcftools view \
    --include "FILTER='PASS'" \
    -O z \
    -o "${filebase}.filter-pass.vcf.gz" \
    ${vcf[0]} 
    """
}

process filter_other {
    tag { "${params.project_name}.${params.cohort_id}.fO" }
    publishDir "${out_dir}/${params.cohort_id}/filter-vcf", mode: 'copy', overwrite: false
    input:
      set val (file_name), file (vcf) from vcfs2
    output:
    file("${filebase}.filter-other.vcf.gz") into vcf_long_out

    script:
    filebase = (file(vcf[0].baseName)).baseName
    """
    ${params.bcftools_base}/bcftools view \
    --include "FILTER='.'" \
    -O z \
    -o "${filebase}.filter-other.vcf.gz" \
    ${vcf[0]}
    """
}


workflow.onComplete {

    println ( workflow.success ? """
        Pipeline execution summary
        ---------------------------
        Completed at: ${workflow.complete}
        Duration    : ${workflow.duration}
        Success     : ${workflow.success}
        workDir     : ${workflow.workDir}
        exit status : ${workflow.exitStatus}
        """ : """
        Failed: ${workflow.errorReport}
        exit status : ${workflow.exitStatus}
        """
    )
}