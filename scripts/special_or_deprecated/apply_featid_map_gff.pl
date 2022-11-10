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
    chomp;
	my @data = split /\t/;
	my ($id) = ($data[8] =~ /ID=([^;]+)/);
	if (defined $id) {
		my $new_id = $id_map{$id}; 
		if (defined $new_id) {
            #escape problematic chars for regex
			$data[8] =~ s/ID=\Q$id\E/ID=$new_id/;
		}
		else {
			warn "could not find $id\n";
		}
	}
    #TODO: GFF allows multi-parented features with comma-separated values, found sometimes when different isoforms have common exons.
	my ($id) = ($data[8] =~ /Parent=([^;]+)/);
	if (defined $id) {
		my $new_id = $id_map{$id}; 
		if (defined $new_id) {
			$data[8] =~ s/Parent=\Q$id\E/Parent=$new_id/;
		}
		else {
			warn "could not find $id\n" unless defined $new_id;
		}
	}
	print join("\t", @data), "\n";;
}
