#!/usr/bin/perl
# The Legacy Compatibility Gateway.
#
# Migrates the bootstrap envelope from JSON to JSON, achieving full
# compatibility between the format and itself. The JSON is parsed WITH
# REGULAR EXPRESSIONS, the way the ancients did it, the way the wiki page
# specifically says not to, the way that has kept this department funded
# since the Clinton administration.
#
# A proper JSON module was available. It was not consulted. Modules retire;
# regexes are forever.
use strict;
use warnings;

my $void_dir = $ENV{VOID_DIR} // 'void';
my $source   = "$void_dir/envelope_01_bootstrap.json";
my $target   = "$void_dir/envelope_10_legacy_gateway.json";

print "   \x{c2}\x{bb} Legacy Gateway warming up (est. 1994, migrated 0 formats since)\n";
print "   \x{c2}\x{bb} Source system: $source\n";

open my $fh, '<', $source or die "the legacy system cannot find the modern system: $!";
my $json = do { local $/; <$fh> };
close $fh;

# ── The crime ───────────────────────────────────────────────────────────
# Extract every key-value pair with a regex. Nested objects? We flatten
# them with optimism. Escaped quotes? We have never received one and have
# a procedure ready for when we do (the procedure is to retire).
my %fields;
my $pairs_parsed = 0;
while ($json =~ /"([^"]+)"\s*:\s*("(?:[^"\\]|\\.)*"|-?\d+(?:\.\d+)?|true|false|null)/g) {
    $fields{$1} = $2;
    $pairs_parsed++;
}

print "   \x{c2}\x{bb} regex-parsed $pairs_parsed key-value pairs out of a format\n";
print "     designed to resist exactly this. confidence: unearned. results: perfect.\n";

# Sanity checks, legacy style.
die "the envelope has no checksum. modern people are sloppy.\n"
    unless exists $fields{checksum_first_opinion};
die "the checksums disagree, which we were told cannot happen\n"
    unless $fields{checksum_first_opinion} eq $fields{checksum_second_opinion};

print "   \x{c2}\x{bb} checksum opinions compared by regex: they agree (as always, but we check)\n";

# ── The migration ───────────────────────────────────────────────────────
# Re-emit the JSON byte-identical. The gateway's contract requires the
# output format to be "at least as modern" as the input; identical passes.
open my $out, '>', $target or die "cannot write to the future: $!";
print {$out} $json;
close $out;

# Verify the migration byte-for-byte, using cmp, because trust died in Y2K.
my $identical = system('cmp', '-s', $source, $target) == 0;
die "the migration changed something. migrations must change nothing.\n" unless $identical;

print "   \x{c2}\x{bb} migration complete: $target is byte-identical to the source.\n";
print "   \x{c2}\x{bb} MIGRATION SUCCESSFUL. formats bridged: JSON -> JSON. downtime: none.\n";
print "     the gateway returns to its long watch.\n";
exit 0;
