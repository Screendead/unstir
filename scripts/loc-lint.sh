#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/loc-lint.sh   Lists each line of Sources/*.swift that scripts/loc-lint/patterns.txt flags (an escape)
# and fails on any. CatalogTests runs the same check in the test suite.
set -euo pipefail
cd "$(dirname "$0")/.."
perl -CSD -e '
use strict; use warnings;
my ($patterns, @files) = @ARGV;
my (@call, @allow, @any);
open my $p, "<:encoding(UTF-8)", $patterns or die;
while (<$p>) {
    chomp;
    next if /^#/ || !/\S/;
    my ($kind, $re) = /^(\w+) (.+)$/ or die "bad line: $_\n";
    push @{ { call => \@call, allow => \@allow, any => \@any }->{$kind} // die "bad kind: $kind\n" }, $re;
}
my $calls = "(?:" . join("|", @call) . ")(?!" . join("|", @allow) . ")";
my $flag = join("|", $calls, @any);
my @found;
for my $file (sort @files) {
    open my $f, "<:encoding(UTF-8)", $file or die;
    (my $name = $file) =~ s{.*/}{};
    while (my $line = <$f>) {
        $line =~ s/^\s+|\s+$//g;
        next if $line =~ m{^//} || $line =~ m{// loc: verbatim};
        push @found, "$name: $line" if $line =~ /$flag/;
    }
}
print "escape: $_\n" for @found;
exit(@found ? 1 : 0);
' scripts/loc-lint/patterns.txt Sources/*.swift
