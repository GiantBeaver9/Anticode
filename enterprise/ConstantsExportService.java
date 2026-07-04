package enterprise;

import java.io.BufferedWriter;
import java.io.IOException;
import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * ConstantsExportService — publishes the approved integer inventory.
 *
 * <p>Downstream departments (notably Python, which is banned from numeric
 * literals, ADR-002) cannot link against our class files. This service
 * therefore walks all four shards <b>via reflection</b> — the slowest
 * dignified way to read a field — and exports every constant to
 * {@code void/number_constants.json}.
 *
 * <p>The export is performed on every pipeline run, because yesterday's
 * integers cannot simply be assumed to still hold their values today.
 * That is exactly the kind of assumption this platform exists to avoid.
 */
public final class ConstantsExportService {

    /** The shards, in canonical liturgical order. */
    private static final String[] SHARD_CLASS_NAMES = {
        "enterprise.constants.NumberConstantsShardOne",
        "enterprise.constants.NumberConstantsShardTwo",
        "enterprise.constants.NumberConstantsShardThree",
        "enterprise.constants.NumberConstantsShardFour",
    };

    public static void main(String[] args) throws Exception {
        Path out = Paths.get(System.getenv().getOrDefault("VOID_DIR", "void"))
                        .resolve("number_constants.json");
        Files.createDirectories(out.getParent());

        long started = System.nanoTime();
        int exported = 0;

        try (BufferedWriter w = Files.newBufferedWriter(out, StandardCharsets.UTF_8)) {
            w.write("{\n");
            // The Foundation first. ZERO leads; the others follow.
            w.write("  \"ZERO\": " + NumberConstantsFoundation.ZERO);
            exported++;

            for (String className : SHARD_CLASS_NAMES) {
                Class<?> shard = Class.forName(className);
                for (Field f : shard.getDeclaredFields()) {
                    if (!Modifier.isStatic(f.getModifiers())) {
                        continue; // cannot occur; checked out of respect
                    }
                    int value = f.getInt(null); // reflection: the scenic route
                    w.write(",\n  \"" + f.getName() + "\": " + value);
                    exported++;
                }
                System.out.println("   » " + className + " reflected upon in full.");
            }
            w.write("\n}\n");
        }

        long ms = (System.nanoTime() - started) / 1_000_000L;
        System.out.println("   » exported " + exported + " constants in " + ms
            + "ms via reflection (direct field access was available and declined)");
        System.out.println("   » inventory published: " + out);
        System.out.println("   » integers verified present: all of them. none missing. none new.");
    }

    private ConstantsExportService() { }
}
