#!/usr/bin/perl -w
use strict;

open(FH,$ARGV[0]); ## All_Real_Useful_Bin
open(BIN,$ARGV[1]); ## Nbin文件
my $to=$ARGV[1];$to=~s/MAPQ60_Nbin.txt$/MAPQ60_Fbin_Autosomal.txt/;
open(TO,">$to");
my $gc=$to; $gc=~s/MAPQ60_Fbin_Autosomal.txt$/MAPQ60_Fbin_GC.txt/;
my $path=$ARGV[2]; ## 脚本目录
# 匹配m//(可简写为//) 替换s/// 转化tr///
# =~ 表示相匹配，!~ 表示不匹配

#读取Autosomal_Evenness_Info_FNAN_ChrXY.txt文件
#创建哈希变量%ref: ref{'chr1'}{43}，储存所有useful的bin:文件中所有useful的bin赋值为1
my %ref=();
while(<FH>)
{
 if($_=~/^##/) {next;}
 else
 {
  chomp($_);#去除末尾换行符
  my @tmp=split /\t/,$_;
  $ref{$tmp[0]}{$tmp[1]}=1;
 }
}
close(FH);

# ne 字符串的逻辑运算符，意思是不等于
print TO "Chromosome	Bin	GC	ReadsNumber\n";
while(<BIN>) #遍历Nbin文件
{
 if($_=~/^##/) {next;}
 else
 {
  chomp($_);
  my @tmp=split /\t/,$_;
  if($tmp[0] ne "chrX" && $tmp[0] ne "chrY" && $tmp[0] ne "chrM"){
  if((exists $ref{$tmp[0]}{$tmp[1]}) && ($tmp[3]!=0)) {print TO $_."\n";}
  #如果这个bin是useful的，且reads数不等于0，输出到MAPQ60_Fbin_Autosomal.txt文件中
  }
 }
}
close(BIN);
close(TO);

#使用R中的loess回归做GC校正
#读取MAPQ60_Fbin_Autosomal.txt文件，输出MAPQ60_Fbin_GC.txt文件(第五列是fit,第六列是WeightValue，第七列是RCgc)
my $s1=$path."/GCBiasCorrect.R"; $s1=~s/\/\//\//;
system("Rscript $s1 $to $gc");

#打开MAPQ60_Fbin_GC.txt,创建WeightValue哈希变量（GC含量与WeightValue为什么可以绑定？）
open(GC,$gc);
my %WeightValue=();
while(<GC>)
{
 next if $_=~/^Chromosome/;
 my @tmp=split /\t/,$_;
 $tmp[2]=sprintf("%.3f",$tmp[2]);
 if($tmp[6]>0) {$WeightValue{$tmp[2]}=$tmp[5];} #如果校正后的reads数为正，则$WeightValue{GC}=WeightValue
 else {$WeightValue{$tmp[2]}=1;} #如果校正后reads数为负，则$WeightValue{GC}=1
}
close(GC);
system("cp $gc $gc.aaa");#看文件内容是啥
system("rm $gc");
system("cp $to $to.aaa");
system("rm $to");

#打开Nbin文件，新建gc文件，
open(GC,">$gc");
open(BIN,$ARGV[1]);
print GC "Chromosome	Bin	GC	ReadsNumber	WeightValue	RCgc\n";
while(<BIN>)
{
 if($_=~/^##/) {next;}
 else
 {
  chomp($_);
  my @tmp=split /\t/,$_;
  if($tmp[0] ne "chrM"){
  if((exists $ref{$tmp[0]}{$tmp[1]}) && ($tmp[3]!=0)) {
  print GC $_;
  if(exists $WeightValue{$tmp[2]}){
  my $RCgc=$tmp[3]*$WeightValue{$tmp[2]}; #校正reads数等于实际reads数乘以权重值
  print GC "\t$WeightValue{$tmp[2]}	$RCgc\n";
  }
  else{
  my $RCgc=$tmp[3]*1;
  print GC "\t1	$RCgc\n";
  }
  }
  }
 }
}
close(GC);
close(BIN);
