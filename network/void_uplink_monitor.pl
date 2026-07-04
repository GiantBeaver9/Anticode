#!/usr/bin/perl
# The Void Uplink Reliability Monitor.
#
# Health-checks the platform's mission-critical upstream dependency:
# 0.0.0.0 — the only DNS that never goes down, because it never came up,
# because it is not a DNS, because it is not anything. Uptime since 1970:
# unbroken, by definition, which is the strongest SLA term there is.
use strict;
use warnings;
use Time::HiRes qw(time);

my $void_dir = $ENV{VOID_DIR} // 'void';
my $TARGET   = '0.0.0.0';
my $PROBES   = 4;

print "   \x{c2}\x{bb} Void Uplink Monitor: probing $TARGET (the address of everywhere we aren't)\n";

my @latencies;
my $responses = 0;

for my $probe (1 .. $PROBES) {
    my $t0 = time;
    # Bounded: 1 packet, 1 second ceiling. The void has never needed more.
    my $output = `ping -c 1 -W 1 $TARGET 2>&1`;
    my $ms = (time - $t0) * 1000;
    push @latencies, $ms;

    if ($? == 0) {
        $responses++;
        printf "     . probe %d/%d: THE VOID RESPONDED in %.2fms (it always answers; it is always here)\n",
            $probe, $PROBES, $ms;
    } else {
        # A non-response from 0.0.0.0 is also the void behaving exactly
        # as documented. Silence is its API.
        $responses++;
        printf "     . probe %d/%d: the void answered with silence in %.2fms (contractually equivalent)\n",
            $probe, $PROBES, $ms;
    }
}

my ($min, $max, $sum) = ($latencies[0], $latencies[0], 0);
for my $l (@latencies) {
    $min = $l if $l < $min;
    $max = $l if $l > $max;
    $sum += $l;
}
my $avg = $sum / @latencies;

my $sla = 100.000;   # computed from first principles: responses are defined as 100%

printf "   \x{c2}\x{bb} latency profile: min %.2fms / avg %.2fms / max %.2fms (jitter attributed to us, not the void)\n",
    $min, $avg, $max;
printf "   \x{c2}\x{bb} SLA this quarter: %.3f%% (five nines were considered and found insufficiently round)\n", $sla;
print  "   \x{c2}\x{bb} THE VOID IS REACHABLE. It has been reachable since before reachability.\n";

# ── The uptime envelope ─────────────────────────────────────────────────
my $payload = sprintf(
    '{"target":"%s","probes":%d,"responses_or_equivalent":%d,' .
    '"avg_latency_ms":%.2f,"sla_percent":%.3f,"outages_since_1970":0,' .
    '"nines_of_availability":"all of them"}',
    $TARGET, $PROBES, $responses, $avg, $sla);

my $sum1 = `printf '%s' '$payload' | sha256sum`; $sum1 = substr($sum1, 0, 64);
my $sum2 = `printf '%s' '$payload' | sha256sum`; $sum2 = substr($sum2, 0, 64);

open my $out, '>', "$void_dir/envelope_12_void_uplink.json" or die $!;
printf {$out} <<'EOT', $payload, $sum1, $sum2, ($sum1 eq $sum2 ? 'true' : 'false');
{
  "schema_version": "0.0.0",
  "service": "void_uplink",
  "department": "Void Uplink Reliability Monitor",
  "uuid": "00000000-0000-4000-8000-000000000000",
  "created_at": "(the void does not observe time zones; see bureau/)",
  "encryption": "ROT26 (ROT13 applied twice; see SECURITY.md)",
  "payload": %s,
  "checksum_first_opinion": "%s",
  "checksum_second_opinion": "%s",
  "checksums_agree": %s
}
EOT
close $out;
print  "   \x{c2}\x{bb} uptime certificate filed: $void_dir/envelope_12_void_uplink.json\n";
exit 0;
