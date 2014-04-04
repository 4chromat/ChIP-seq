#/bin/bash

usage() { echo "Usage: $0 [-e <raw file(s) extension>]";}

help="
# 
# Run inside a folder with unzipped raw sequencing files which 
# extension is given through command line with -e.
# If no args are given the default extension is txt.
#
# Obtain SAM alignments to UCSC mm9, BAM (+ index) of sorted-
# non redundant tags and TDF file.
#
# Needs: Bowtie, Samtools and igvtools. 
#        Bowtie index files and chromosome sizes file. 
#
# Infiles: At least one raw sequencing data file with the 
#	   given extension.
# Outfiles:
#	sample.mm9USCSalign.sam = Bowtie alignment SAM format
#	sample.mm9USCSalign.sorted.nonred.bam = Bowtie 
#		alignment BAM format, of sorted, non redundant
#               tags. 
#	sample.mm9USCSalign.sorted.nonred.bam.bai = BAM index
#	sample.mm9USCSalign.sorted.nonred.tdf = tdf file ready 
#       	for igv.
#
#		        	     Cynthia Alexander 2014-03"

# Get arguments
while getopts ":e:h" o; do
	case "${o}" in
                h)
                 echo "$help"
	         flag=1
                 ;;
		e) 
	         ext=${OPTARG}
		 ;;
	esac
done

# Print description if program called with -h
if [ $flag ]; then
        exit 1;
fi

# Set default extension if no arguments are given
if [ -z "$ext" ]; then
	usage
	echo "WARNING: Will run using files with default extension 'txt'"
	ext="txt";
fi

for sample in $(ls *\.$ext)

do
	echo " ===== START processing $sample===="

	# Get SAM files, Bowtie params to get best alignment for uniquely mapping reads. 
        bowtie -t -v 2 -a -m 1 -k 1 -S --best --strata --chunkmbs 200 /data/cynthia/IndexBowtie_mm9/mm9 $sample temp_${sample/\.$ext/}.sam &> Log_bowtie_${sample/\.$ext/}.txt

	# Filter aligned reads
        grep "\b255\b" temp_${sample/\.$ext/}.sam > ${sample/\.$ext/}.mm9USCSalign.sam
	if [ ! -f temp_${sample/\.$ext/}.sam ]; then { echo "No Bowtie output?"; break; } fi

	# Get BAM file
        samtools view -bS -t /data/cynthia/mm9.chrom.sizes ${sample/\.$ext/}.mm9USCSalign.sam > temp_${sample/\.$ext/}.mm9USCSalign.bam

        # Sort BAM file, remove redundant reads and get BAM index
	samtools sort temp_${sample/\.$ext/}.mm9USCSalign.bam temp_${sample/\.$ext/}.mm9USCSalign.sorted
        samtools rmdup -s temp_${sample/\.$ext/}.mm9USCSalign.sorted.bam ${sample/\.$ext/}.mm9USCSalign.sorted.nonred.bam
        samtools index ${sample/\.$ext/}.mm9USCSalign.sorted.nonred.bam

	# Get a TDF file ready for igv
	igvtools count ${sample/\.$ext/}.mm9USCSalign.sorted.nonred.bam ${sample/\.$ext/}.mm9USCSalign.sorted.nonred.tdf /data/cynthia/mm9.chrom.sizes

	# Clean your mess. 
	rm temp_${sample/\.$ext/}*

	echo " =====DONE for $sample===="
done

