## Trait file (trait.tsv)
Filename: *gensp.population*.gen.*Author1_Author2_year*.trait.tsv

Some publications provide information on how traits are measured, or a treatment used for a particular group of samples on which the trait is measured. This file presents that with trait and description columns.
1. *trait name* matches the trait name used in the other files in the collection
2. *description* describes the measurement, treatment, etc. associated with this trait

Header (required):
```
#trait_name description
```

Example:
```
#trait_name     description
Late leaf spot	LLS resistance score at 70 DAS of 2004, 2005, 2006, 2008, 2009; LLS score at 90 DAS of 2005, 2006, 2009
Rust, Puccinia	Rust resistance score at 70 DAS of 2014; 80 DAS of 2006, 2007E, 2007L, 2008, 2009; Rust score at 90 DAS of 2006, 2007E, 2007L
```
