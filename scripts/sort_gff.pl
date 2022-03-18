#!/usr/bin/env perl
use strict;
#TODO: would it make more sense to just check parentage?
my %type_collate = (
    gene => 0,
    mRNA => 1,
    ncRNA => 1.5,
    rRNA => 1.75,
    tRNA => 1.875,
    exon => 2,
    three_prime_UTR => 3,
    CDS => 4,
    five_prime_UTR => 5,
    protein_match => 6,
    match_part => 7,
);
my $line;
while ($line = <>) {
   last unless $line =~ /^#/;
   print $line;
}
my @lines = ($line, <>);
@lines = map {my @a = split /\t/; \@a;} @lines;
@lines = sort {
    $a->[0] cmp $b->[0] || $a->[3] <=> $b->[3] || $type_collate{$a->[2]} cmp $type_collate{$b->[2]}
} @lines;
foreach my $line (@lines) {
    print join("\t", @$line);
}
