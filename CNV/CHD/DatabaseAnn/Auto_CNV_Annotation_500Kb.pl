#!/usr/bin/perl -w
use strict;

my $f1=$ARGV[0]; ##CNV results file;
my $p1=$ARGV[1]; ##scripts pathway

open(F1,$f1);
my @info=<F1>;
close(F1);
if($#info>=1){
 chomp($info[0]);
 my $header=$info[0]."	Ann.Info\n";
 my $HF=$f1; $HF=~s/.txt$/_header.txt/;
 open(HD,">$HF");
 print HD $header;
 close(HD);
 
 my $t1=$f1; $t1=~s/.txt$/_DGV_Annotation.txt/;
 my $t2=$f1; $t2=~s/.txt$/_DGV_Filted.txt/;
 my $t3=$f1; $t3=~s/.txt$/_Aneuploid.txt/;
 system("perl $p1/1.DGV_Gene_Annotation.pl $p1/RefSeqGene_Extract.txt $p1/OMIM_Gene.txt $p1/dgvMerged_Extract.txt $p1/dgvMerged_Extract_OMIM_Gene.txt $f1");
 my $t4=$t2; $t4=~s/.txt$/_DS_Annotation.txt/;
 my $t5=$t2; $t5=~s/.txt$/_DS_Filted.txt/;
 
 my $t6=$t5; $t6=~s/.txt$/_DI_Annotation.txt/;
 my $t7=$t5; $t7=~s/.txt$/_DI_Filted.txt/;
 
 my $t8=$t7; $t8=~s/.txt$/_OMIM_Annotation.txt/;
 
 if(-e $t2){
 system("perl $p1/2.Decipher_Syndrome_Gene_Annotation.pl $p1/RefSeqGene_Extract.txt $p1/OMIM_Gene.txt $p1/Decipher_Syndrome_E2C.txt $p1/Decipher_Syndrome_OMIM_Gene.txt $t2");
  if(-e $t5){
  system("perl $p1/3.Decipher_ISCA_Gene_Annotation.pl $p1/RefSeqGene_Extract.txt $p1/OMIM_Gene.txt $p1/Decipher_Patient_Info_E2C.txt $p1/Decipher_Patient_Info_OMIM_Gene.txt $p1/ISCA_Extract_Info_E2C.txt $p1/ISCA_Extract_Info_OMIM_Gene.txt $t5");
  }
   if(-e $t7){
     system("perl $p1/4.OMIM_RefGene_Annotation.pl $p1/RefSeqGene_Extract.txt $p1/OMIM_Gene.txt $p1/full_omim_table.txt $t7");
   }
 }
 my @TF=();
 if(-e $t1) {push(@TF,$t1);}
 if(-e $t3) {push(@TF,$t3);}
 if(-e $t4) {push(@TF,$t4);}
 if(-e $t6) {push(@TF,$t6);}
 if(-e $t8) {push(@TF,$t8);}
 my $merge=join " ",@TF;
 my $MF=$f1; $MF=~s/.txt$/_Annotation.txt/;
 system("cat $HF $merge >$MF");
 system("rm $HF");
 if(-e $t1) {system("rm $t1");}
 if(-e $t2) {system("rm $t2");}
 if(-e $t3) {system("rm $t3");}
 if(-e $t4) {system("rm $t4");}
 if(-e $t5) {system("rm $t5");}
 if(-e $t6) {system("rm $t6");}
 if(-e $t7) {system("rm $t7");}
 if(-e $t8) {system("rm $t8");}
 system("perl $p1/5.Report_CNV_Info_500Kb.pl $MF");
}
