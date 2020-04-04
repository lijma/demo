#!/usr/bin/env perl
#===============================================================================
#    DESCRIPTION:  This file is used to generate and exchange ssh keys.
#    COPYRIGHT:    ©2018 lijma
#===============================================================================

use strict;
use warnings;
use utf8;
use English;
use Getopt::Long;
use Data::Dumper;

my @HOSTS  = (
    "controller", "compute1", "block1", "object1", "object2"
);

sub execCmd {
    my $cmd = shift;
    ( $_ = qx{$cmd 2>&1}, $? >> 8 );
}

sub main {

	#generate ssh keys automatically
	foreach my $node (@HOSTS) {
		my $checkcmd = qq{ssh -q root\@$node "echo helloworld"};
        execCmd()
    }

}
