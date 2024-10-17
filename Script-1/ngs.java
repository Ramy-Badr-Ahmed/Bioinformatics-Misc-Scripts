import java.io.*;
import java.nio.file.*;
import java.security.MessageDigest;
import java.util.zip.GZIPInputStream;

public class FastaProcessor {

    public static void decompressGzFile(String gzPath, String outputPath)
    {
        System.out.println("\tDecompressing ... " + gzPath);

        try (GZIPInputStream gzipInputStream = new GZIPInputStream(new FileInputStream(gzPath));
             FileOutputStream fileOutputStream = new FileOutputStream(outputPath)) {

            byte[] buffer = new byte[1024 * 1024]; // 1 MiB chunks
            int bytesRead;

            while ((bytesRead = gzipInputStream.read(buffer)) != -1) {
                fileOutputStream.write(buffer, 0, bytesRead);
            }

            System.out.println("\tDecompressed .gz file to " + outputPath);

        } catch (IOException e) {
            System.err.println("\tAn error occurred while decompressing the .gz file: " + e.getMessage());
        }
    }

    public static void processFile(String inputFile, String outputFile, Integer maxPair)
    {
        try (BufferedReader reader = new BufferedReader(new FileReader(inputFile));
             BufferedWriter writer = new BufferedWriter(new FileWriter(outputFile))) {

            String line;
            int pairCount = 0;

            while ((line = reader.readLine()) != null) {
                if (maxPair != null && pairCount >= maxPair) {
                    break;
                }

                String headerVariant = line.trim();
                String dnaSequence = reader.readLine().trim();

                char variantNucleotide = headerVariant.charAt(headerVariant.length() - 1);

                if (dnaSequence.length() > 29) {
                    char replacedNucleotide = dnaSequence.charAt(29);
                    String modifiedSequence = replaceNthCharacter(dnaSequence, 29, variantNucleotide);

                    // Append the original character to the variant nucleotide
                    headerVariant = headerVariant.substring(0, headerVariant.length() - 1) + replacedNucleotide + variantNucleotide;
                }

                writer.write(headerVariant);
                writer.newLine();
                writer.write(dnaSequence);
                writer.newLine();

                pairCount++;
            }

        } catch (IOException e) {
            System.err.println("An error occurred while processing the FASTA file: " + e.getMessage());
        }
    }

    public static String replaceNthCharacter(String sequence, int index, char newChar)
    {
        return sequence.substring(0, index) + newChar + sequence.substring(index + 1);
    }

    public static String calculateMd5(String filePath)
    {
        try {
            MessageDigest md5Digest = MessageDigest.getInstance("MD5");
            byte[] buffer = new byte[4096];
            int bytesRead;

            try (InputStream inputStream = new FileInputStream(filePath)) {
                while ((bytesRead = inputStream.read(buffer)) != -1) {
                    md5Digest.update(buffer, 0, bytesRead);
                }
            }

            byte[] md5Bytes = md5Digest.digest();
            StringBuilder hexString = new StringBuilder();

            for (byte b : md5Bytes) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }

            return hexString.toString();

        } catch (Exception e) {
            System.err.println("An error occurred while calculating MD5 hash: " + e.getMessage());
            return null;
        }
    }

    public static void writeMd5ToFile(String md5Value, String md5File)
    {
        try (BufferedWriter writer = new BufferedWriter(new FileWriter(md5File))) {
            writer.write("MD5 hash: " + md5Value);
            writer.newLine();
        } catch (IOException e) {
            System.err.println("An error occurred while writing the MD5 hash: " + e.getMessage());
        }
    }

    public static void main(String[] args)
    {
        String extractTo = "data";
        String gzPath = Paths.get(extractTo, "ngs.fa.gz").toString();
        String uncompressedPath = Paths.get(extractTo, "ngs.fa").toString();
        String finalPath = Paths.get(extractTo, "ngs_variants.fa").toString();

        decompressGzFile(gzPath, uncompressedPath);
        processFile(uncompressedPath, finalPath, 250);

        String md5Result = calculateMd5(finalPath);
        System.out.println("MD5 hash of the output file: " + md5Result);

        String md5OutputFile = Paths.get(extractTo, "md5_ngs_variants.txt").toString();
        writeMd5ToFile(md5Result, md5OutputFile);
    }
}
