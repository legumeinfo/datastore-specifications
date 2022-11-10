#!/usr/bin/env perl
use strict;
my $id_map_file = shift;
open(IM, $id_map_file) || die $!;
my %id_map = map {chomp; split /\t/;} <IM>;
close IM;
$/="\n>";
while (<>) {
	chomp;
	s/^>//;
	my ($id, $desc, $seq) = /(\S+)([^\n]*)\n(.*)/s;
	my $new_id = $id_map{$id}; 
	die "could not find $id\n" unless defined $new_id;
	print ">$new_id$desc\n$seq\n";
}
