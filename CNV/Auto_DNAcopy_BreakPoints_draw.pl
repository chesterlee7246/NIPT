#!/usr/bin/perl -w
use strict;

opendir(P1,$ARGV[0]);
my $p2=$ARGV[1];
my $p3=$ARGV[2]; ##database annotation
my $site=(split(/\//,$ARGV[0]))[5];

 my $index2id=$ARGV[0]."/index2id.txt";
 my %id=();
 my %id1=();
 my %id2=();
 if(-e $index2id){
 open(FH,$index2id);
 while(<FH>)
 {
  chomp($_);
  my @tmp=split /\t/,$_;
  $id{$tmp[0]}=$tmp[1];
  $id1{$tmp[0]}=$tmp[2];
  $id2{$tmp[0]}=$tmp[3];
 }
 close(FH);
 }else{
die "lack of index2id.txt file !";
}

while(my $file=readdir(P1))
{
 if($file=~/_Normalized_LogRR.txt$/)
 {
 print $file."\n";
 my $index=substr($file,0,13);
 my $INDEX="";
 if(exists $id{$index}) {if($id1{$index} ne "null" && $id1{$index} ne "undef") {$INDEX=$id1{$index};} elsif($id1{$index} eq "null" || $id1{$index} eq "undef") {$INDEX=$id{$index};}}
 else{$INDEX=$index;}
 my $name=$ARGV[0]."/".$file;
 my $MAPD=`perl $p2/Calculate_MAPD.pl $name`;
 my $info="";
 if($file=~/Merge/)
 {$info=$ARGV[0]."/".$index."_100Kb_DNAcopy_Info.txt";}
 else
 {$info=$ARGV[0]."/".$index."_20Kb_DNAcopy_Info.txt";}
 #system("Rscript $p2/DNAcopy.r $name $INDEX $info 1.00");
 my $info1=$info; $info1=~s/.txt$/_CNV.txt/;
 #system("perl $p2/Extract_DNAcopy_Analysis_Info.pl $info $info1");
 
 my $Minfo=$info1; $Minfo=~s/.txt$/_MergeCNV.txt/;
 #system("perl $p2/BreakPoints_Max_Pvalue.pl $name $info1 >$Minfo");
 
 my $info2=$info1; $info2=~s/.txt$/_RealCNV.txt/;
 #system("Rscript $p2/Real_CNV_Value.r $Minfo $info2");
 
 my $Linfo=$info2; $Linfo=~s/.txt$/_LogRR.txt/;
 #system("perl $p2/Extract_DNAcopy_Analysis_ZScore_TO_LogRR.pl $info2 $name $Linfo");

 my $f1=$Linfo; $f1=~s/_20Kb_DNAcopy_Info_CNV_RealCNV_LogRR.txt$/_rawlib_rmdup_MAPQ10_Fbin_GC_All.txt/; $f1=~s/_100Kb_DNAcopy_Info_CNV_RealCNV_LogRR.txt$/_rawlib_rmdup_MAPQ10_Fbin_GC_All_Merge.txt/;
 my $to=$Linfo; $to=~s/.txt$/_Effective.txt/;
 ##print "$Linfo	$name	$f1	$to\n";
 #system("perl $p2/calulate_cnv_size_length.pl $Linfo $name $f1 $p2/cytoband_effective_length.txt $p2/cytoband_masker.txt >$to");
 my $title=$ARGV[0]."/".$index."_rawlib_rmdup_MAPQ10_Fbin_GC_All_Merge_Normalized_LogRR_Extract_CNV_ConvertValue_newXY";
 my $title1=$ARGV[0]."/".$index."_rawlib_rmdup_MAPQ10_Fbin_GC_All_Merge_Normalized_LogRR_Extract_CNV_ConvertValue_new_no_XY";
 my $title2=$ARGV[0]."/".$index."_rawlib_rmdup_MAPQ10_Fbin_GC_All_Merge_Normalized_LogRR_Extract_CNV_ConvertValue_newX";
 #my $title3=$ARGV[0]."/".$index."_rawlib_rmdup_MAPQ10_Fbin_GC_All_Merge_Normalized_LogRR_Extract_CNV_ConvertValue_newXY6";
 my $rscript="Rscript --no-save --no-restore --verbose";
 my $condition=$ARGV[0]."/output.Rout 2>& 1";

 if(-e "$p2/scatter1_new_xy_height.R" && $site ne "SYTH"){
 system("$rscript $p2/scatter1_new_xy_height.R $name $to $title $INDEX > $condition");}
 if(-e "$p2/scatter1_new_xy_height_SYTH.R" && $site eq "SYTH"){
 system("$rscript $p2/scatter1_new_xy_height_SYTH.R $name $to $title $INDEX > $condition");}
 if(-e "$p2/scatter1_new_no_xy.R" && $site eq "XiangYa"){
 system("$rscript $p2/scatter1_new_no_xy.R $name $to $title1 $INDEX > $condition");}
 if(-e "$p2/scatter1_new_x.R"){
 system("$rscript $p2/scatter1_new_x.R $name $to $title2 $INDEX > $condition");}
 #if(-e "$p2/scatter1_new_xy.R"){
 #system("$rscript $p2/scatter1_new_xy.R $name $to $title3 $INDEX > $condition");}

 if(-e "$p2/LogRR2LogRRCytband.py"){
 system("python $p2/LogRR2LogRRCytband.py $name $p2/cytoBand.txt");}
 my $file_cytBand=$name;
 $file_cytBand=~s/.txt$/_cytband.txt/;

 my $CNVMAPD=`perl $p2/Calculate_CNV_LogRR_MAPD.pl $to`;

 ##system("rm $info"); system("rm $info1"); 
 #system("rm $Minfo"); system("rm $info2");

 my $t1=$to; $t1=~s/.txt$/_Extract_Abnormal_CNV.txt/;
 if($site eq "SYTH"){
 system("perl $p2/extract_abnormal_cnv_bin_SYTH.pl $to $p2/cytoBand.txt");}
 else{
 system("perl $p2/extract_abnormal_cnv_bin.pl $to $p2/cytoBand.txt");}

 my $t2=$t1; $t2=~s/.txt$/_Merge_1Mb.txt/;
 my $t3=$t1; $t3=~s/.txt$/_Merge_100Kb.txt/;
 if($site eq "SYTH"){
 system("perl $p2/merge_extract_abnormal_cnv_SYTH.pl $t1");}
 else{
 system("perl $p2/merge_extract_abnormal_cnv.pl $t1");}

 my $t4=$t2; $t4=~s/.txt$/_Cytoband.txt/;
 my $t5=$t3; $t5=~s/.txt$/_Cytoband.txt/;

 system("perl $p2/cytoband_cnv_results.pl $t2");
 system("perl $p2/cytoband_cnv_results.pl $t3");

 system("python $p2/CytBand_new_anno.py $t4 $p2");
 system("python $p2/CytBand_new_anno.py $t5 $p2");
 
 system("perl $p2/Each_Bin_CNV_info.pl $to $name");
 
 #system("perl $p2/Annotat_DGV_Info.pl $YF $p2/All_Chromosome_DGV_Info.txt");
 #system("perl $p2/Annotat_DECIPHER_Info.pl $YF $p2/All_Chromosome_DECIPHER_Info.txt");
 #system("perl $p2/Annotat_ISCA_Info.pl $YF $p2/All_Chromosome_ISCA_Info.txt");
 #system("perl $p3/Auto_CNV_Annotation.pl $YF $p3");
 if(-e $t4) {system("perl $p3/Auto_CNV_Annotation.pl $t4 $p3");}
 # if(-e $t4) {print("perl $p3/Auto_CNV_Annotation.pl $t4 $p3");}
 if(-e $t5) {system("perl $p3/Auto_CNV_Annotation.pl $t5 $p3");}
 # if(-e $t5) {print("perl $p3/Auto_CNV_Annotation.pl $t5 $p3");}
 
 my $t6=$t4; $t6=~s/.txt$/_Frequency.txt/;
 my $t7=$t5; $t7=~s/.txt$/_Frequency.txt/;
 my $t8=$t4; $t8=~s/.txt$/_new_anno.txt/;
 my $t9=$t5; $t9=~s/.txt$/_new_anno.txt/;
 if(-e $t8) {system("python3 $p3/build_pop_cnv.py $t4 $t6 $t8 $p3/Population_CNV.txt");}
 if(-e $t9) {system("python3 $p3/build_pop_cnv.py $t5 $t7 $t9 $p3/Population_CNV.txt");}
 # print "python3 $p3/build_pop_cnv.py $t5 $t7 $t9 $p3/Population_CNV.txt";
 
 my $label=0; ##my $YF=$t4; ##1Mb ##my $YF=$t5; ##100Kb
 my $labelX=0;
 my $YF=$t4; ##1Mb
 my $YFF=$YF; $YFF=~s/.txt$/_Annotation_Report.txt/;
 if(-e "$p2/Report1Mb2Cytband.py"){
 system("python $p2/Report1Mb2Cytband.py $YFF $file_cytBand");}

# my $YF="";
 if($file=~/Merge/)
 {$YF=$t5;
  my $YFF=$YF; $YFF=~s/.txt$/_Annotation_Report.txt/;
  if(-e $YFF) {$YF=$YFF};
 }
 else
 {$YF=$t4;
  my $YFF=$YF; $YFF=~s/.txt$/_Annotation_Report.txt/;
  if(-e $YFF) {$YF=$YFF};
 }
 open(LB,$YF);
 while(<LB>)
 {
 my @tmp=split /\t/,$_;
 if($tmp[1] eq "chrY"){$label+=1;}
 if($tmp[1] eq "chrX"){$labelX+=1;}
 }
 close(LB);
 
 my $info4=$name; $info4=~s/.txt$/_Extract_CNV.txt/;
 system("perl $p2/LogRR2CNValue.pl $info4");
 my $CNValue=$info4; $CNValue=~s/.txt$/_ConvertValue.txt/;
 my $PID="";
 if($INDEX!~/IonXpress/) {$PID=$INDEX;}#{$PID=substr($INDEX,3,1);}
 else {$PID=$INDEX;}
 my $info5_mosaic=$name; $info5_mosaic=~s/.txt$/_CytoBand_Mosaic.svg/;
 my $info5_mosaic_new=$name; $info5_mosaic_new=~s/.txt$/_CytoBand_Mosaic_new.svg/;
 my $info5_mosaic_new_png=$info5_mosaic_new; $info5_mosaic_new_png=~s/.svg$/.png/;
 my $genderfile=$name; $genderfile=~s/_rawlib_rmdup_MAPQ10_Fbin_GC_All_Merge_Normalized_LogRR.txt$/_rawlib_rmdup_MAPQ10_Fbin_GC_All.txt/; $genderfile=~s/_rawlib_rmdup_MAPQ10_Fbin_GC_All_Normalized_LogRR.txt$/_rawlib_rmdup_MAPQ10_Fbin_GC_All.txt/;
 my $gender=`perl $p2/Calculate_ChrY_Percentage.pl $genderfile`;

 if($site eq "XiangYa" && -e "$p2/plot_chromosome22.pl" && -e "$p2/CytoBand_CNV_TO_SVG22.pl"){
 system("perl $p2/plot_chromosome22.pl $info4 $PID $p2 $label $labelX");
 my $info5_mosaic_noXY=$name; $info5_mosaic_noXY=~s/.txt$/_CytoBand_Mosaic.noXY.svg/;
 my $info5_mosaic_new_noXY=$name; $info5_mosaic_new_noXY=~s/.txt$/_CytoBand_Mosaic_new.noXY.svg/;
 my $info5_mosaic_new_noXY_png=$info5_mosaic_new_noXY; $info5_mosaic_new_noXY_png=~s/.svg$/.png/;

 system("perl $p2/CytoBand_CNV_TO_SVG22.pl $p2/cytoBand.txt $YF $PID $info5_mosaic_noXY");
 system("python3 $p2/ideomgram2.py $p2/cytoband.hg19.550.txt $YF $PID 22 > $info5_mosaic_new_noXY");
 system("rsvg-convert -w 2400 -h 1120 -o $info5_mosaic_new_noXY_png $info5_mosaic_new_noXY");}

 system("perl $p2/plot_chromosome_CNValue.pl $CNValue $PID $p2");
 system("perl $p2/plot_chromosome.pl $info4 $PID $p2 $label $id2{$index} $gender");
 if($site eq "SYTH"){
 system("perl $p2/CytoBand_CNV_TO_SVG_SYTH.pl $p2/cytoBand.txt $YF $PID $info5_mosaic $id2{$index} $gender");}
 else{
 system("perl $p2/CytoBand_CNV_TO_SVG.pl $p2/cytoBand.txt $YF $PID $info5_mosaic $id2{$index} $gender");}
 
 if($id2{$index} eq "Y" && `grep "chrY" $to`){
 system("python3 $p2/ideomgram2.py $p2/cytoband.hg19.550.txt $YF $PID 24 > $info5_mosaic_new");}
 else{
 system("python3 $p2/ideomgram2.py $p2/cytoband.hg19.550.txt $YF $PID 23 > $info5_mosaic_new");}
 system("rsvg-convert -w 2400 -h 1120 -o $info5_mosaic_new_png $info5_mosaic_new");
 }
}
closedir(P1);
