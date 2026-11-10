#!/bin/bash
# Copyright © 2026 Jack Lusher. All rights reserved.
# Usage: scripts/loc-lint.sh [--write]   Lists each line of Sources/*.swift that scripts/loc-lint/patterns.txt flags
# and scripts/loc-lint/baseline.txt doesn't hold (an escape), and each baseline line no longer flagged (fixed: take
# it out), and fails on either. --write rewrites the baseline from what is flagged now. CatalogTests runs the same
# check in the test suite.
set -euo pipefail
cd "$(dirname "$0")/.."
perl -CSD -e '
use strict; use warnings;
my ($write, $patterns, $baseline, @files) = @ARGV;
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
if ($write) {
    open my $b, ">:encoding(UTF-8)", $baseline or die;
    print $b "# Player text that escapes the String Catalog today, one flagged line each (scripts/loc-lint.sh). Each fix\n";
    print $b "# takes its line out; the migration ends with this file deleted.\n";
    print $b "$_\n" for @found;
    printf "%d lines in the baseline\n", scalar @found;
    exit 0;
}
my %left;
if (open my $b, "<:encoding(UTF-8)", $baseline) {
    while (<$b>) { chomp; $left{$_}++ unless /^#/ || !/\S/; }
}
my $status = 0;
for (@found) {
    if ($left{$_}) { $left{$_}--; } else { print "escape: $_\n"; $status = 1; }
}
for my $line (sort keys %left) { for (1 .. $left{$line}) { print "fixed: $line (take it out of the baseline)\n"; $status = 1; } }
exit $status;
' "$( [[ "${1:-}" == --write ]] && echo 1 || echo 0 )" scripts/loc-lint/patterns.txt scripts/loc-lint/baseline.txt Sources/*.swift
