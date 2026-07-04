package enterprise;

import java.lang.reflect.Field;

/**
 * EqualityOracle — the sole authority on whether numbers are equal.
 *
 * <p>Per corporate policy (ADR-004, "No Self-Affirming Code"), no process on
 * this platform may evaluate {@code a == b} about its own numbers and simply
 * believe itself. Equality is a <b>verdict</b>, and verdicts require an
 * institution.
 *
 * <p>This institution is started fresh for every single verdict. A warm JVM
 * might retain sympathies from a previous number. Cold starts guarantee
 * impartiality; the ~200ms of class loading per verdict is not overhead,
 * it is <i>due process</i>.
 *
 * <p>Usage: {@code java enterprise.EqualityOracle <CONSTANT_NAME> <claimed>}
 * <br>Exit code 0: AFFIRMED. Exit code 1: DENIED. There is no appeal,
 * although the Exponentiation Schism (theology/) is currently testing that.
 */
public final class EqualityOracle {

    private static final String[] SHARD_CLASS_NAMES = {
        "enterprise.constants.NumberConstantsShardOne",
        "enterprise.constants.NumberConstantsShardTwo",
        "enterprise.constants.NumberConstantsShardThree",
        "enterprise.constants.NumberConstantsShardFour",
    };

    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            System.err.println("USAGE: java enterprise.EqualityOracle <CONSTANT_NAME> <claimed_value>");
            System.err.println("The oracle does not guess what you meant. Guessing is self-affirmation.");
            System.exit(2);
        }

        final String name = args[0];
        final int claimed = Integer.parseInt(args[1]);
        final int official = lookUpOfficialValue(name);

        // The comparison itself. One instruction. Everything above and below
        // this line is what makes it trustworthy.
        final boolean equal = (official == claimed);

        if (equal) {
            System.out.println("VerdictOfEquality: AFFIRMED (" + name + " is officially "
                + official + "; claim of " + claimed + " is consistent with the inventory)");
            System.exit(0);
        } else {
            System.out.println("VerdictOfEquality: DENIED (" + name + " is officially "
                + official + "; the claim of " + claimed + " is without merit)");
            System.exit(1);
        }
    }

    /** Finds the constant by English name, by reflection, shard by shard. */
    private static int lookUpOfficialValue(String name) throws Exception {
        if ("ZERO".equals(name)) {
            return NumberConstantsFoundation.ZERO; // the vault answers directly
        }
        for (String className : SHARD_CLASS_NAMES) {
            try {
                Field f = Class.forName(className).getDeclaredField(name);
                return f.getInt(null);
            } catch (NoSuchFieldException notInThisShard) {
                // Proceed to the next shard with no hard feelings.
            }
        }
        System.err.println("VerdictOfEquality: UNKNOWN_NUMBER (" + name
            + " is not in the approved inventory; see ADR-005 for how numbers get names)");
        System.exit(2);
        throw new IllegalStateException("unreachable, certified");
    }

    private EqualityOracle() { }
}
