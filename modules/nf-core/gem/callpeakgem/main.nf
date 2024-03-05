process GEM_CALLPEAK {
    tag "$meta.id"
    label 'process_low'


    input:
    tuple val(meta), path(ipbam), path(controlbam)
    val   macs2_gsize
    path sizes
    path chrms

    output:
    tuple val(meta), path("*.GEM_events.narrowPeak"), emit: peak
    tuple val(meta), path("*results.htm")           , emit: gemhtml
    tuple val(meta), path("*_outputs")           , emit: gemfolder
    tuple val(meta), path("*.GEM_events.txt")           , emit: events


    path  "versions.yml"                             , emit: versions


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args_list = args.tokenize()
    def format    = meta.single_end ? 'BAM' : 'BAMPE'
    def control   = controlbam ? "--control $controlbam" : ''
    if(args_list.contains('--format')){
        def id = args_list.findIndexOf{it=='--format'}
        format = args_list[id+1]
        args_list.remove(id+1)
        args_list.remove(id)
    }
    """
    java -jar /home/joaquin/projects/methylation/programs/gem/gem.jar \\
            --d /home/joaquin/projects/methylation/programs/gem/Read_Distribution_default.txt \\
                 --g $sizes --genome $chrms \\
                 --s $macs2_gsize \\
                 --expt $ipbam --ctrl $controlbam\\
                 --out $prefix --f SAM --outNP --range 200 \\
                 --smooth 0 --mrc 1 --fold 2 --q 1.301029996 \\
                 --k_min 6 --k_max 20 --k_seqs 600 --k_neg_dinu_shuffle \\
                 --pp_nmotifs 1 --t 1

    mv $prefix/* . 

    cat ${prefix}.GEM_events.narrowPeak | \\
     sed -e 's/chr//g' | awk 'BEGIN {FS = "\t"; OFS = "\t"; counter = 1} \\
     { \$4 = "${prefix}_peak_" counter; counter++; print \$0 }' > temp1 && \\
     cat temp1 >${prefix}.GEM_events.narrowPeak && rm temp1
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        GEM: CUSTOM
    END_VERSIONS
    """
}
