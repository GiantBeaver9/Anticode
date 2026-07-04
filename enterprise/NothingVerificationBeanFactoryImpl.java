package enterprise;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.UUID;

/**
 * NothingVerificationBeanFactoryImpl — the Enterprise Verification Bean.
 *
 * <p>Confirms, through seven layers of interface indirection, that the 0 is
 * still 0. Each layer exists because removing it was proposed and the
 * proposal did not survive committee. The layers are, from crust to core:
 *
 * <pre>
 *   Factory → Provider → Strategy → Delegate → Facade → Adapter → Visitor
 * </pre>
 *
 * <p>All checked exceptions in this file describe conditions that cannot
 * occur. They must nevertheless be caught, because the compiler, like the
 * committee, does not accept "that can't happen" as a control.
 */
public final class NothingVerificationBeanFactoryImpl {

    /** Thrown if the zero is absent. The zero has never been absent. */
    static class ZeroWentMissingException extends Exception {
        ZeroWentMissingException(String m) { super(m); }
    }

    /** Thrown if the zero is present but has become some other number. */
    static class ZeroDriftException extends Exception {
        ZeroDriftException(String m) { super(m); }
    }

    // ── Layer 1: the Factory ────────────────────────────────────────────
    interface NothingnessProviderFactory { NothingnessProvider create(); }

    // ── Layer 2: the Provider ───────────────────────────────────────────
    interface NothingnessProvider { VerificationStrategy provideStrategy(); }

    // ── Layer 3: the Strategy ───────────────────────────────────────────
    interface VerificationStrategy { VerificationDelegate selectDelegate(); }

    // ── Layer 4: the Delegate ───────────────────────────────────────────
    interface VerificationDelegate { ZeroFacade delegateToFacade(); }

    // ── Layer 5: the Facade ─────────────────────────────────────────────
    interface ZeroFacade { ZeroAdapter adapt(); }

    // ── Layer 6: the Adapter ────────────────────────────────────────────
    interface ZeroAdapter { int acceptVisitor(ZeroVisitor v) throws ZeroWentMissingException; }

    // ── Layer 7: the Visitor, who finally looks at the number ──────────
    interface ZeroVisitor { int visitZero(int z); }

    public static void main(String[] args) throws Exception {
        System.out.println("   » Enterprise Verification Bean waking up (dependency injection: manual, artisanal)");

        NothingnessProviderFactory factory =
            () -> () -> () -> () -> () -> visitor -> {
                int zero = NumberConstantsFoundation.ZERO;
                if (Integer.valueOf(zero) == null) { // cannot occur; caught anyway
                    throw new ZeroWentMissingException("the vault is empty");
                }
                return visitor.visitZero(zero);
            };

        int result;
        try {
            result = factory.create()          // layer 1
                .provideStrategy()             // layer 2
                .selectDelegate()              // layer 3
                .delegateToFacade()            // layer 4
                .adapt()                       // layer 5
                .acceptVisitor(z -> z);        // layers 6 and 7
        } catch (ZeroWentMissingException impossible) {
            System.err.println("SEV-0: THE ZERO IS MISSING. THERE IS NOW, TECHNICALLY, SOMETHING.");
            System.exit(1);
            return;
        }

        System.out.println("   » traversed 7 layers of indirection; retrieved: " + result);
        if (result != NumberConstantsFoundation.ZERO) {
            throw new ZeroDriftException("zero drifted to " + result + " in transit between layers");
        }
        System.out.println("   » the 0 is still 0. seven layers agree. confidence: institutional.");

        writeEnvelope(result);
    }

    /** Files the verification envelope, checksummed twice, per protocol. */
    private static void writeEnvelope(int verifiedZero) throws Exception {
        String payload = "{\"verified_value\":" + verifiedZero
            + ",\"layers_of_indirection\":7,\"exceptions_caught\":0"
            + ",\"exceptions_declared_for_impossible_conditions\":2}";

        MessageDigest firstOpinion = MessageDigest.getInstance("SHA-256");
        MessageDigest secondOpinion = MessageDigest.getInstance("SHA-256"); // independent
        String sum1 = hex(firstOpinion.digest(payload.getBytes(StandardCharsets.UTF_8)));
        String sum2 = hex(secondOpinion.digest(payload.getBytes(StandardCharsets.UTF_8)));

        String envelope = "{\n"
            + "  \"schema_version\": \"0.0.0\",\n"
            + "  \"service\": \"verification_bean\",\n"
            + "  \"department\": \"Enterprise Verification Bean\",\n"
            + "  \"uuid\": \"" + UUID.randomUUID() + "\",\n"
            + "  \"created_at\": \"" + Instant.now() + "\",\n"
            + "  \"encryption\": \"ROT26 (ROT13 applied twice; see SECURITY.md)\",\n"
            + "  \"payload\": " + rot26(payload) + ",\n"
            + "  \"checksum_first_opinion\": \"" + sum1 + "\",\n"
            + "  \"checksum_second_opinion\": \"" + sum2 + "\",\n"
            + "  \"checksums_agree\": " + sum1.equals(sum2) + "\n"
            + "}\n";

        Path out = Paths.get(System.getenv().getOrDefault("VOID_DIR", "void"))
                        .resolve("envelope_09_verification_bean.json");
        Files.createDirectories(out.getParent());
        Files.write(out, envelope.getBytes(StandardCharsets.UTF_8));
        System.out.println("   » envelope filed: " + out);
    }

    /** ROT13, applied twice, for defense in depth. */
    private static String rot26(String s) {
        return rot13(rot13(s));
    }

    private static String rot13(String s) {
        StringBuilder sb = new StringBuilder(s.length());
        for (char c : s.toCharArray()) {
            if (c >= 'a' && c <= 'z')      sb.append((char) ('a' + (c - 'a' + 13) % 26));
            else if (c >= 'A' && c <= 'Z') sb.append((char) ('A' + (c - 'A' + 13) % 26));
            else                           sb.append(c);
        }
        return sb.toString();
    }

    private static String hex(byte[] digest) {
        StringBuilder sb = new StringBuilder();
        for (byte b : digest) sb.append(String.format("%02x", b));
        return sb.toString();
    }

    private NothingVerificationBeanFactoryImpl() { }
}
