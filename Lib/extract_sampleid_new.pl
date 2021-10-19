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
 my $info=$obj->{'barcodeInfo'}->{$index}->{"sample"};
 my $info=Dumper($info);
 chomp($info);
 $info=~s/^\$VAR1//;
 $info=~s/[=';]//g;
 $info=~s/\s+//g;
 if($info ne "none"){
 my $des=$obj->{'sampleInfo'}->{$info}->{"description"};
 my $des=Dumper($des);
 chomp($des);
 $des=~s/^\$VAR1//;
 $des=~s/[=';]//g;
 $des=~s/\s+//g;
 print TO $index."\t".$info."\t".$des."\n";
 }
}

close(TO);
close(JFILE);


