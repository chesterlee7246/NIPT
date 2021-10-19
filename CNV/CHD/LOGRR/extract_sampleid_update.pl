#!/usr/bin/perl
use JSON;
use Data::Dumper;

my $json = new JSON;

my $js;
open JFILE, "$ARGV[0]";
open TO,">$ARGV[1]";
while(<JFILE>) {
   $js .= "$_";
}
my $obj = $json->decode($js);

for(my $i=1;$i<=96;$i++)
{
 my $index="IonXpress_".sprintf("%03d",$i);
 my $info=$obj->{'barcodeInfo'}->{$index}->{'sample'};
 if($info ne "none"){
 my $objj=$obj->{'experimentAnalysisSettings'}->{'barcodedSamples'};
 my $des=$objj->{$info}->{'barcodeSampleInfo'}->{$index}->{'externalId'};
 chomp($des);
 if($des eq "" || $des eq "undef")
 {$des=$obj->{'sampleInfo'}->{$info}->{'externalId'};
 }
 $YY=$obj->{'sampleInfo'}->{$info}->{'description'};
 if($des eq "") {$des="null";}
 if($YY eq "") {$YY="null";}

 print TO $index."\t".$info."\t".$des."\t".$YY."\n";
 }
}

close(TO);
close(JFILE);
