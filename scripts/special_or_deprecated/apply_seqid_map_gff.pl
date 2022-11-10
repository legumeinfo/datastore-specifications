#!/usr/bin/env perl
use strict;
my $id_map_file = shift;
open(IM, $id_map_file) || die $!;
my %id_map = map {chomp; split /\t/;} <IM>;
close IM;
while (<>) {
	if (/^#/) {
		print;
		next;
	}
	my @data = split /\t/;
	my $id = $data[0];
	my $new_id = $id_map{$id}; 
	die "could not find $id\n" unless defined $new_id;
	$data[0] = $new_id;
	print join("\t", @data);
}
