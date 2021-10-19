#!/usr/bin/perl -w
use strict;

my $rg=$ARGV[0]; ##refGene
my $og=$ARGV[1]; ##omim Gene
my $of=$ARGV[2]; ##omim Gene Function
my $f1=$ARGV[3]; ##CNV file
my $t1=$f1; $t1=~s/.txt$/_OMIM_Annotation.txt/;
my $t2=$t1; $t2=~s/.txt$/_Gene_Function.txt/; $t2=~s/_DGV_Filted_DS_Filted_DI_Filted//;
open(T1,">$t1");
open(T2,">$t2");

print T2 "CNV.Region.All.Gene	CNV.Region.Gene	genes	hgnc_synonyms	hgnc_genes	phenotype	phenotypeInheritance	geneMimNumber	phenotypeMimNumber	chromosome	comments\n";

open(OG,$og);
my %omim=();
while(<OG>)
{
 next if $_=~/^##/;
 my @tmp=split /\t/,$_;
 if(exists $omim{$tmp[3]}) {$omim{$tmp[3]}.=";".$tmp[1] 
 #print $_."\n"; exit(1);
 }
 else{
 $omim{$tmp[3]}=$tmp[1];
 }
}
close(OG);

open(RG,$rg);
my %refGene=();
while(<RG>)
{
 next if $_=~/^name/;
 chomp($_);
 my @tmp=split /\t/,$_;
 if(exists $omim{$tmp[-1]})
 {
  my $tp=$tmp[0]."_".$tmp[2];
  if(exists $refGene{$tmp[1]}{$tp}) {print $_."\n"; exit(1);}
  $refGene{$tmp[1]}{$tp}=$_;
 }
}
close(RG);

my %function=();
open(OF,$of);
my $Label_Line=0;
while(<OF>)
{ $Label_Line+=1;
  my @tmp=split /\t/,$_;
  my @temp=split /\,/,$tmp[2];
  for(my $i=0;$i<=$#temp;$i++)
  {
   $function{$temp[$i]}{$Label_Line}=$_;
  }
}
close(OF);

open(F1,$f1);
my $Record=0;
while(<F1>)
{
 next if $_=~/^ID/;
 chomp($_);
 my @tmp=split /\t/,$_;
 my $chr=$tmp[1];
 my $start=$tmp[2];
 my $end=$tmp[3];
 my %Gene=();
 foreach my $id (sort {$a cmp $b} keys %{$refGene{$chr}})
 {
  my @temp=split /\t/,$refGene{$chr}{$id};
  my $p1=$temp[2];  #one coordinate
  my $p2=$temp[3];
  my $gn=$temp[-1];
  if(($p1>=$start && $p2<=$end) || ($p1<=$start && $p2>=$end) || ($p1<=$start && $p2<=$end && $p2>=$start) || ($p1>=$start && $p1<=$end && $p2>=$end))
  {
  $Gene{$gn}+=1;
  }
 }
 if(%Gene){
 my @SGene=sort {$a cmp $b} keys %Gene;
 my $info=join ";",@SGene;
 print T1 $_."\tOmimGene\t".$info."\n";
 $Record+=1;
  for(my $i=0;$i<=$#SGene;$i++)
  {
   if(exists $function{$SGene[$i]})
   {
   foreach my $nums (sort {$a<=>$b} keys %{$function{$SGene[$i]}})
   {
    print T2 $info."\t".$SGene[$i]."\t".$function{$SGene[$i]}{$nums};
   }
   }
  }
 }
 else{
 print T1 $_."\tNoOmimGene\n";
 }
}
close(F1);
close(T1);
close(T2);

if($Record==0) {system("rm $t2");}
