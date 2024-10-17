use strict;
use warnings;
use Compress::Zlib;
use Digest::MD5;
use File::Spec;

# Decompress a .gz file to a specified output path.
sub decompress_gz_file {
    my ($gz_path, $output_path) = @_;

    print "\tDecompressing ... $gz_path\n";

    eval {
        my $buffer;
        my $gz = gzopen($gz_path, "rb") or die "Cannot open gz file: $gz_path";
        open(my $output_fh, '>', $output_path) or die "Cannot open output file: $output_path";

        while ($gz->gzread($buffer)) {
            print $output_fh $buffer;
        }
        $gz->gzclose();
        close $output_fh;

        print "\tDecompressed .gz file to $output_path\n";
    };
    if ($@) {
        print "\tAn error occurred while decompressing the .gz file: $@\n";
    }
}

# Process the FASTA file by substituting the 30th nucleotide.
sub process_file {
    my ($input_file, $output_file, $max_pair) = @_;
    $max_pair = undef unless defined $max_pair;

    open(my $infile, '<', $input_file) or die "Cannot open input file: $input_file";
    open(my $outfile, '>', $output_file) or die "Cannot open output file: $output_file";

    my @lines = <$infile>;
    my $pair_count = 0;

    for (my $i = 0; $i < @lines; $i += 2) {
        last if defined($max_pair) && $pair_count >= $max_pair;

        my $header_variant = $lines[$i];
        chomp($header_variant);
        my $dna_sequence = $lines[$i + 1];
        chomp($dna_sequence);

        # Get the last character of the header identifier (e.g., "G" from ">chr1_70_G")
        my $variant_nucleotide = substr($header_variant, -1);

        if (length($dna_sequence) > 29) {
            my $replaced_nucleotide = substr($dna_sequence, 29, 1);
            my $modified_sequence = replace_nth_character($dna_sequence, 29, $variant_nucleotide);
            $header_variant = substr($header_variant, 0, -1) . $replaced_nucleotide . $variant_nucleotide;
        }

        print $outfile "$header_variant\n";
        print $outfile "$modified_sequence\n";
        $pair_count++;
    }

    close $infile;
    close $outfile;
}

# Replace the character at the specified index with the new character
sub replace_nth_character {
    my ($sequence, $index, $new_char) = @_;
    substr($sequence, $index, 1, $new_char);
    return $sequence;
}

# Calculate the MD5 hash of the file content
sub calculate_md5 {
    my ($file_path) = @_;
    open(my $file, '<', $file_path) or die "Cannot open file: $file_path";
    binmode($file);

    my $md5 = Digest::MD5->new;
    $md5->addfile($file);

    close $file;
    return $md5->hexdigest;
}

# Write the MD5 hash value to the specified text file
sub write_md5_to_file {
    my ($md5_value, $md5_file) = @_;
    open(my $f, '>', $md5_file) or die "Cannot open file: $md5_file";
    print $f "MD5 hash: $md5_value\n";
    close $f;
}


my $extract_to = 'data';
my $gz_path = File::Spec->catfile($extract_to, 'ngs.fa.gz');
my $uncompressed_path = File::Spec->catfile($extract_to, 'ngs.fa');
my $final_path = File::Spec->catfile($extract_to, 'ngs_variants.fa');

decompress_gz_file($gz_path, $uncompressed_path);
process_file($uncompressed_path, $final_path, 250);

my $md5_result = calculate_md5($final_path);
print "MD5 hash of the output file: $md5_result\n";

my $md5_output_file = File::Spec->catfile($extract_to, 'md5_ngs_variants.txt');
write_md5_to_file($md5_result, $md5_output_file);
