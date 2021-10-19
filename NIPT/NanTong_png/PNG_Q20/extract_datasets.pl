#!/usr/bin/perl
use JSON;
use Data::Dumper;


open JS1, "$ARGV[0]";
my $js1;
while(<JS1>) {
   $js1 .= "$_";
}
close(JS1);
my $json = new JSON;
my $obj = $json->decode($js1);
my $runid=$obj->{'expmeta'}->{"runid"};
#print "$runid\n";

open JS2, "$ARGV[1]";
my $js2;
while(<JS2>) {
   $js2 .= "$_";
}
close(JS2);
my $Datasets_json = new JSON;
my $Datasets_obj = $Datasets_json->decode($js2);
my $all=0;
my $q20=0;
for(my $i=1;$i<=96;$i++)
{
 my $index=$runid."\."."IonXpress_".sprintf("%03d",$i);
 my $info1=$Datasets_obj->{'read_groups'}->{$index}->{"total_bases"}; $all+=$info1;
 my $info2=$Datasets_obj->{'read_groups'}->{$index}->{"Q20_bases"}; $q20+=$info2;
 #print "$index	$info1	$info2\n";
}

my $per=($q20/$all)*100;
my $Per=sprintf("%.1f",$per)."%";
#print "$all	$q20	$per\n";
print "$Per\n";
