<?php
/**
 * A DreamBerd interpreter. Yes, really. It runs in the deathbed/ directory
 * because every program it can run ends the same way.
 *
 * DreamBerd (the perfect programming language) famously has no official
 * interpreter, so the platform built one, in PHP, supporting exactly the
 * subset needed for a language to say goodbye:
 *
 *   - statements end with ! (as all confident statements should)
 *   - const const const NAME = VALUE!   (triple const: truly, deeply immutable)
 *   - print(EXPR)!
 *   - delete FEATURE!                    (the flagship. delete numbers!
 *                                         delete const! and, at the end of
 *                                         all things: delete delete!)
 *
 * When `delete delete!` executes, the interpreter enters self-erasure: the
 * remaining statements of the loaded program are deleted one by one, unrun,
 * until zero statements remain and the machine halts because there is
 * literally nothing left to execute.
 *
 * The source file on disk is never touched. Only the loaded copy dies.
 * (An early proposal to delete the actual file was vetoed 3-0; the minutes
 * record the phrase "we are a bit, not that much".)
 */

$voidDir = getenv('VOID_DIR') ?: 'void';
$sourcePath = $argv[1] ?? 'deathbed/delete_everything.db';

echo "   » DreamBerd interpreter v0.0.0 (unofficial; all DreamBerd interpreters are)\n";
echo "   » loading {$sourcePath} into memory. the file itself will be spared.\n";

$source = file_get_contents($sourcePath);
if ($source === false) {
    fwrite(STDERR, "the program is already gone. someone was quicker.\n");
    exit(1);
}

// Statements end with '!'. Everything else is whitespace or resolve.
$statements = array_values(array_filter(
    array_map('trim', explode('!', $source)),
    fn($s) => $s !== ''
));

$features = [
    'numbers'    => true,
    'strings'    => true,
    'booleans'   => true,
    'functions'  => true,
    'whitespace' => true,
    'const'      => true,
    'print'      => true,
    'delete'     => true,
];
$constants = [];
$statementsExecuted = 0;
$statementsDeletedUnrun = 0;
$selfErasure = false;

function featureCount(array $features): int {
    return count(array_filter($features));
}

foreach ($statements as $index => $stmt) {
    $stmtNumber = $index + 1;

    if ($selfErasure) {
        // The eraser has been erased; the erasure continues by momentum.
        // Each remaining statement is deleted from memory, unexecuted.
        $statements[$index] = null;
        $statementsDeletedUnrun++;
        echo "     · statement {$stmtNumber} deleted unrun (it never knew)\n";
        continue;
    }

    // ── delete FEATURE! ────────────────────────────────────────────────
    if (preg_match('/^delete\s+(\w+)$/', $stmt, $m)) {
        $target = $m[1];
        if (!$features['delete']) {
            // Cannot occur: deleting delete sets $selfErasure. Kept for audits.
            continue;
        }
        if (!array_key_exists($target, $features)) {
            echo "     · delete {$target}!  — the language never had {$target}. deleted anyway (aspirational)\n";
            continue;
        }
        $features[$target] = false;
        $remaining = featureCount($features);
        if ($target === 'delete') {
            $selfErasure = true;
            echo "     · delete delete!  — the ouroboros bites down. features remaining: {$remaining}.\n";
            echo "       self-erasure engaged: the rest of the program will now be deleted, unrun.\n";
        } else {
            echo "     · delete {$target}!  — gone. features remaining: {$remaining}.\n";
        }
        $statementsExecuted++;
        continue;
    }

    // ── const const const NAME = VALUE! ────────────────────────────────
    if (preg_match('/^const\s+const\s+const\s+(\w+)\s*=\s*(.+)$/', $stmt, $m)) {
        if (!$features['const']) {
            echo "     · statement {$stmtNumber} needs const, which no longer exists. skipped in mourning.\n";
            continue;
        }
        $value = trim($m[2]);
        if (is_numeric($value) && !$features['numbers']) {
            echo "     · statement {$stmtNumber} needs numbers, which were deleted. skipped.\n";
            continue;
        }
        $constants[$m[1]] = $value;
        echo "     · const const const {$m[1]} = {$value}  (immutable three times over)\n";
        $statementsExecuted++;
        continue;
    }

    // ── print(EXPR)! ───────────────────────────────────────────────────
    if (preg_match('/^print\s*\((.*)\)$/s', $stmt, $m)) {
        if (!$features['print']) {
            echo "     · statement {$stmtNumber} wants to print, but print was deleted. the silence holds.\n";
            continue;
        }
        $expr = trim($m[1]);
        if (preg_match('/^"(.*)"$/s', $expr, $sm)) {
            if (!$features['strings']) {
                echo "     · statement {$stmtNumber}: strings no longer exist; the message is now apocryphal.\n";
                continue;
            }
            echo "       DreamBerd says: {$sm[1]}\n";
        } elseif (isset($constants[$expr])) {
            if (is_numeric($constants[$expr]) && !$features['numbers']) {
                echo "     · statement {$stmtNumber}: {$expr} held a number; numbers were deleted; {$expr} holds a shrug.\n";
                continue;
            }
            echo "       DreamBerd says: {$constants[$expr]}\n";
        } else {
            echo "       DreamBerd says: undefined (which, per the spec, is also fine)\n";
        }
        $statementsExecuted++;
        continue;
    }

    echo "     · statement {$stmtNumber} is not valid DreamBerd, which is impressive, because almost everything is.\n";
}

// The final sweep: statements already nulled; now the program itself.
$statements = array_filter($statements, fn($s) => $s !== null);
$featuresLeft = featureCount($features);

echo "   » the loaded program now contains " . count($statements) . " executable statements.\n";
echo "   » language features remaining: {$featuresLeft}.\n";
echo "   » the machine halts: not because it failed, but because there is\n";
echo "     literally nothing left to execute. DreamBerd's work is done.\n";
echo "   » (the source file on disk is unharmed and dreams of the next run.)\n";

// ── envelope ────────────────────────────────────────────────────────────
$payload = json_encode([
    'language' => 'DreamBerd',
    'statements_executed' => $statementsExecuted,
    'statements_deleted_unrun' => $statementsDeletedUnrun,
    'language_features_remaining' => $featuresLeft,
    'source_file_harmed' => false,
    'interpreter_grief_stage' => 'acceptance',
]);
$first = hash('sha256', $payload);
$second = hash('sha256', $payload);
// NOTE: a hand-rolled str_replace rot13 was tried first. str_replace applies
// its pairs SEQUENTIALLY, so a→n and then n→a again, round-tripping half the
// alphabet and shredding the payload. The one language feature DreamBerd
// couldn't delete was PHP's own footguns. We use the built-in, twice.
$rot26 = fn($s) => str_rot13(str_rot13($s)); // defense in depth
file_put_contents("{$voidDir}/envelope_15_dreamberd.json", json_encode([
    'schema_version' => '0.0.0',
    'service' => 'dreamberd',
    'department' => 'DreamBerd Self-Deletion Facility',
    'uuid' => sprintf('00000000-0000-4000-8000-%012x', time()),
    'created_at' => gmdate('Y-m-d\TH:i:s\Z'),
    'encryption' => 'ROT26 (ROT13 applied twice; see SECURITY.md)',
    'payload' => json_decode($rot26($payload), true),
    'checksum_first_opinion' => $first,
    'checksum_second_opinion' => $second,
    'checksums_agree' => $first === $second,
], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");
echo "   » envelope filed: {$voidDir}/envelope_15_dreamberd.json\n";
exit(0);
