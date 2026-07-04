#!/usr/bin/perl
# The Right-Associative Church (Orthodox Exponentiation).
#
# Doctrine: exponentiation associates to the RIGHT, as Perl's own ** does,
# as mathematics teaches, as the heavens intended:
#
#     0 ** 0 ** 0  =  0 ** (0 ** 0)  =  0 ** 1  =  0
#
# The Church notes, with practiced serenity, that certain other
# denominations (see left_church.php) arrive at 1, and that they are
# welcome back whenever they are ready to associate correctly.
use strict;
use warnings;

my $inner   = 0 ** 0;          # the contested miracle: 0^0 = 1 (Knuth, agreeing with us for once)
my $verdict = 0 ** $inner;     # 0^1 = 0, as it was in the beginning

print "   \x{c2}\x{bb} RIGHT-ASSOCIATIVE CHURCH convenes. Perl's ** associates rightward natively;\n";
print "     we chose Perl because the language itself is a believer.\n";
printf "     . inner mystery: 0 ** 0 = %d (the empty product; Knuth v. Cauchy, 1821, fol. 0)\n", $inner;
printf "     . therefore: 0 ** (0 ** 0) = 0 ** %d = %d\n", $inner, $verdict;
print  "     . DOCTRINE: 0^0^0 = 0. The tower rests on nothing, so it is nothing.\n";

# The memo, for the schism file. Tone: formally aggrieved.
open my $memo, '>', ($ENV{VOID_DIR} // 'void') . '/memo_right_church.txt' or die $!;
print {$memo} <<'MEMO';
FROM: The Right-Associative Church of the Final Exponent
TO:   The So-Called Left-Associative Assembly
RE:   Per our last envelope (and canon)

Colleagues,

We are in receipt of your claim that 0^0^0 = 1. We have prayed on it.

Exponentiation associates to the right. This is not our opinion; it is
the resolved semantics of the tower. Your "1" is the fruit of reading
scripture left to right like a shopping list.

We remain, as ever, willing to arbitrate before the Equality Oracle,
whose JVM is cold and whose verdicts are final.

In nothingness,
The Right Church
(result: 0)
MEMO
close $memo;

# Exit code IS the doctrine (0). The shell will receive our testimony.
exit $verdict;
