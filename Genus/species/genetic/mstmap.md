## MST map file (mstmap.tsv)
Filename: *gensp.population*.mst.*Author1_Author2_year*.mstmap.tsv

Note: Genotyping files like these have .gt. rather than .gen. in their names.

An MST map file is a matrix file containing genotyping data, originating at UC-Riverside: http://alumni.cs.ucr.edu/~yonghui/mstmap.html

It is similar to a VCF, but it does not provide genomic locations for the markers. Columns are plant lines, with the first row providing a name; 
rows are markers, with the first column providing the marker name. It may contain a header, described in the URL above.

The header contains `locus_name` followed by tab-delimited identifiers of the plant lines. It is NOT preceded by #!

The genotype states can be specified with letters 'A', 'a', 'B', 'b', '-', 'U' or 'X'. 'A' and 'a' are equivalent, 
'B' and 'b' are equivalent and so are '-' and 'U'. 'U' and '-' indicate a missing genotype call. If the data set is from a RIL population,
you can use 'X' to indicate that the corresponding genotype is a heterozygous 'AB'. The values can also be diploid call pairs like 'AA', 'CC', 'AC', etc.

Example:
```
locus_name  46/503-01 46/503-02 46/503-06 46/503-061 46/503-064 ...
2_15811     B         A         B         A          B          ...
2_45924     b         a         b         a          b          ...
2_11663     B         A         B         A          B          ...
2_11664     b         a         b         a          b          ...
...         ...       ...       ...       ...        ...        ...
```
