![Python](https://img.shields.io/badge/Python-3670A0?style=plastic&logo=python&logoColor=ffdd54) ![SQL](https://img.shields.io/badge/SQL-blue?style=plastic&logo=databricks&logoColor=white) ![GitHub](https://img.shields.io/github/license/Ramy-Badr-Ahmed/bioinformatics-misc-scripts?style=plastic)
### Script 1

**FASTA Sequence Variant Modifier**

This script reads a FASTA file, `ngs.fa`, substitutes the 30th nucleotide in each DNA sequence (reference) 
with the variant nucleotide specified in the header, and writes the resulting sequences to a new FASTA file
`ngs_variants.fa`.

The replaced nucleotide from the reference sequence is appended to the header, in front of the variant nucleotide. The script also calculates the MD5 checksum of the resulting file for verification purposes.

- Decompresses .gz FASTA file, a sample file is included.
- Processes up to a specified number of sequence pairs (default is all).
- Logs the processing of sequences and outputs a preview of the modified sequences.
- Calculates and stores the MD5 hash of the final output file.

### Script 2

**Identifying Unique Peptide Sequences from Mass-Spectrometry Data**

Determine which peptides (protein snippets of 8 to 12 amino acids) are presented to the immune system 
on the surface of tumor cells, mass-spectrometry experiments are performed.

Each experiment produces a list of spectra, and for each spectrum, a tool generates up to 10 possible peptide sequences,
referred to as sequence-spectrum matches (SSMs). However, only one sequence can correctly match each spectrum.

The goal is to identify how many unique peptide sequences have been matched to spectra in the mass-spectrometry experiments. 

We are interested in the highest-scoring sequence for each spectrum, provided that:

- The score (Score) of the sequence is greater than or equal to 0.3. 
- Spectra with ambiguous highest scores (i.e., more than one sequence with the same highest score) are excluded.

The result of this query script is the total count of unique sequences identified from the mass-spectrometry experiments. A sample DB is included.

### Script 3

**Database Design for Clinical Trial Patients**

The database schema is designed to store data for multiple ongoing multi-center clinical trials. 
The schema captures patient information, trial details, screening visits, treatment progress, 
and transference between studies as outlined by clinical scientists. 

The structure allows tracking of patients’ eligibility for various studies, screening results,
and follow-up visit data, and facilitates identifying patients who could be eligible for other studies.

The schema consists of the following tables: 
`Study`, `Center`, `Patient`, `ScreeningVisit`, `PreTreatmentVisit`, `FollowUpVisit`, and `Transference`. A model is included.

- Created with The `InnoDB` storage engine for all tables. 
  `InnoDB` ensures reliable transactional operations and supports foreign key constraints, maintaining referential integrity between related tables.

- The `utf8mb4` character set and `utf8mb4_unicode_ci` collation are applied to allow the storage of a wide range of Unicode characters, supporting special characters in fields like patient names and study details.

- To enhance query performance, indexes have been added to frequently queried fields like `CenterID`, `CurrentStudyID`, and `PatientID` in several tables (`Patient`, `ScreeningVisit`, `FollowUpVisit`). 
  These indexes enhance query performance, allowing faster lookups and reducing the time needed for data retrieval.

- To enforce Referential Integrity, foreign key relationships are defined with `ON DELETE` and `ON UPDATE CASCADE` or `SET NULL` actions.  
  This ensures that if referenced records (such as a `Study` or `Patient`) are deleted or updated, dependent records are automatically updated or nullified, avoiding orphaned records and maintaining database integrity.

### Script 4

**MGF_Offset Script**

`MGF_Offset` is a command-line tool designed to process `MGF` files from mass spectrometry experiments 
and update their offsets in a connected database (databaseMS). It ensures that each MGF file is processed only once and updates the database based on the content of the file. 

To handle the processing in a multithreaded fashion, the script uses an executor pool for parallelism.

The script identifies multiple MGF folders via the PathFinder class (e.g., `DIA`, `DDA`, `HCD`, `ETD` folders). For each folder, MGF files are located and processed if:

> The corresponding <basename>.done flag file does not already exist.
> 
> The required upload flag file (<basename>.uploaded) exists.

- Database Interaction:
For each valid MGF file, the script interacts with the connected databaseMS to retrieve the necessary metadata. If the MGF file has not been processed in the database or has zero MS2 entries, it is skipped.


- Thread Pool Execution:
`MGF` file updates are processed using a thread pool (`executors.new_fixed_thread_pool(8)`), allowing multiple files to be updated simultaneously. 
 Once all files are processed, the script gracefully shuts down the thread pool and ensures all threads have completed their tasks.


- Logging and Locking Mechanism:
The script creates a lock file `MGF_Offset.lock` in the working directory to prevent concurrent execution. 
If the lock file exists, the script stops execution. Logging is handled via a console and file logger, where all actions and errors are recorded for auditing purposes.
