<?php
# The Left-Associative Assembly (Reformed Exponentiation).
#
# Doctrine: expressions are evaluated in the order a reasonable person
# reads them, left to right, the way ledgers are kept and hallways walked:
#
#     0 ** 0 ** 0  =  (0 ** 0) ** 0  =  1 ** 0  =  1
#
# The Assembly acknowledges that PHP's own ** operator associates to the
# right (a wound inflicted by the standards committee), and therefore
# performs its liturgy WITH EXPLICIT PARENTHESES, as all honest people do.

$inner   = (0 ** 0);           // the shared miracle: 0^0 = 1 (on this, even the Right agrees)
$verdict = ($inner ** 0);      // 1^0 = 1: anything to the zeroth is 1. ANYTHING. even our critics.

echo "   » LEFT-ASSOCIATIVE ASSEMBLY convenes. PHP was chosen because it, too,\n";
echo "     has been told it associates wrongly, and it, too, kept going.\n";
printf("     · shared miracle: (0 ** 0) = %d (the empty product; we cite the same folio)\n", $inner);
printf("     · therefore: (0 ** 0) ** 0 = %d ** 0 = %d\n", $inner, $verdict);
echo "     · DOCTRINE: 0^0^0 = 1. The tower is read as it is built: from the ground.\n";

$void = getenv('VOID_DIR') ?: 'void';
file_put_contents("$void/memo_left_church.txt", <<<MEMO
FROM: The Left-Associative Assembly of the Grounded Tower
TO:   The Right-Associative Church (registered mail)
RE:   RE: Per our last envelope (and canon)

Esteemed adversaries,

Your memo arrived right-associated: we read it from the end, as you would
apparently prefer, and found it concluded before it began — much like
your argument.

(0^0)^0 = 1^0 = 1. Anything to the zeroth power is 1. Your own doctrine
grants this in its inner mystery and forgets it one step later. We have
enrolled you in our thoughts and, pending arbitration, our prayers.

The tower is climbed from the ground,
The Left Assembly
(result: 1)
MEMO);

// Exit code IS the doctrine (1). Yes, the shell will call this a failure.
// The shell is right-associated. History will absolve us.
exit($verdict);
