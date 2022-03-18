#!/usr/bin/env perl
my %ids;
while (<>) {
	chomp;
	my ($id) = /ID=([^;]+)/;
	if (defined $id) {
		$ids{$id} = 1;
	}
	my ($parent) = /Parent=([^;]+)/;
	if (defined $parent) {
        my @parents = split /,/, $parent;
        foreach my $parent (@prents) {
            if (!defined $ids{$parent}) {
                print "$parent did not appear as ID\n";
            }
        }
	}
}
