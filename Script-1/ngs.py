#  Created by: Ramy-Badr-Ahmed (https://github.com/Ramy-Badr-Ahmed)
#  Please open any issue or pull request to address bugs/corrections to this file.
#  Thank you!

import gzip
import os
import logging
import hashlib


def decompress_gz_file(gz_path, output_path):
    """
    Decompress a .gz file to a specified output path.
    Parameters:
    - gzPath (str): Path to the .gz file.
    - outputPath (str): Path to save the decompressed file.
    """
    logging.info(f"\tDecompressing ... {gz_path}")

    try:
        with gzip.open(gz_path, 'rb') as source:
            with open(output_path, 'wb') as target:
                for chunk in iter(lambda: source.read(1024*1024), b''):  # Read in 1 MiB chunks until the empty byte string
                    target.write(chunk)

        logging.info(f"\tDecompressed .gz file to {output_path}")

    except Exception as e:
        logging.error(f"\tAn error occurred while decompressing the .gz file: {e}")

def process_file(input_file, output_file, max_pair = None):
    """
    Reads the FASTA file. Substitutes the 30th nucleotide in the DNA sequence (reference) with the nucleotide in the header (variant).
    Add the replaced nucleotide from the reference sequence to the header in front of the variant nucleotide.
    and writes to the final output_file.

    :param input_file: input FASTA file, ngs.fa
    :param output_file: saved output, e.g. ngs_variant.fa
    :param max_pair: specify the max number of pair to process. Leave out to process the whole file.
    """
    with (open(input_file, 'r') as infile, open(output_file, 'w') as outfile):
        lines = infile.readlines()

        pair_count = 0

        for i in range(0, len(lines), 2):  # increment by two (identifier and dna sequence)

            if max_pair is not None and pair_count >= max_pair:   # process only the first max_pair in file, if specified
                break

            header_variant = lines[i].strip()
            dna_sequence = lines[i + 1].strip()

            variant_nucleotide = header_variant[-1]     # The last character of the header identifier

            # Replace the 30th character (indexed @29)
            if len(dna_sequence) > 29:
                replaced_nucleotide = dna_sequence[29]
                modified_sequence = replace_nth_character(dna_sequence, 29, variant_nucleotide)

                # Append the original character to the variant_nucleotide
                header_variant = f"{header_variant[:-1]}{replaced_nucleotide}{variant_nucleotide}"

            outfile.write(f"{header_variant}\n")
            outfile.write(f"{modified_sequence}\n")
            pair_count+=1

def replace_nth_character(sequence, index, new_char):
    """
    Replace the character at the specified index with the new character
    """
    return sequence[:index] + new_char + sequence[index + 1:]

def calculate_md5(file_path):
    """
    Calculate the MD5 hash of the file content
    """
    md5_hash = hashlib.md5()

    with open(file_path, "rb") as file:
        for chunk in iter(lambda: file.read(4096), b""):       # Read and update hash in chunks
            md5_hash.update(chunk)

    return md5_hash.hexdigest()

def write_md5_to_file(md5_value, md5_file):
    """
    Write the MD5 hash value to the specified text file
    """
    with open(md5_file, 'w') as f:
        f.write(f"MD5 hash: {md5_value}\n")

if __name__ == "__main__":

    extract_to = 'data'

    gz_path = os.path.join(extract_to, 'ngs.fa.gz')
    uncompressed_path = os.path.join(extract_to, 'ngs.fa')
    final_path = os.path.join(extract_to, 'ngs_variants.fa')

    decompress_gz_file(gz_path, uncompressed_path)
    process_file(uncompressed_path, final_path, 250)

    md5_result = calculate_md5(final_path)
    print(f"MD5 hash of the output file: {md5_result}")

    md5_output_file = os.path.join(extract_to, 'md5_ngs_variants.txt')
    write_md5_to_file(md5_result, md5_output_file)