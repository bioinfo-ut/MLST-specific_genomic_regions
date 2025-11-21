#!/usr/bin/perl

$i = 0;
while(<>){
    chomp;
    next if(/^NUnique/ || /^NTotal/);
    @line = split(/\s+/);
    $i++;
    print ">$i\n$line[0]\n";
}
