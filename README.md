# semtagger

### About this repository

This repository provides a universal semantic tagger which can be easily trained on the [Parallel Meaning Bank](http://pmb.let.rug.nl). 

It was developed as part of the master's thesis titled _Universal semantic tagging methods and their applications_, submitted at both Saarland University and the University of Groningen. The results there reported can be reproduced by running the script ```job.sh``` and defining the appropriate configuration options.

A recent version of Python 3 with the packages listed in [requirements.txt](./requirements.txt) is expected.

### Training a neural model

```$ ./run.sh --train [--model MODEL_FILE]```

### Using a trained model to predict sem-tags

```$ ./run.sh --predict --input INPUT_CONLL_FILE --output OUTPUT_CONLL_FILE [--model MODEL_FILE]```

### Jointly training and predicting

```$ ./run.sh --train --predict --input INPUT_CONLL_FILE --output OUTPUT_CONLL_FILE [--model MODEL_FILE]```

### Configuration

One can edit [config.sh](./config.sh) for fine control over the employed features and model architecture.

It is recommended that you edit [config.sh](./config.sh) in order to use models which are suitable for your system, especially when not using a GPU for computations.

Note that trained models are stored/loaded using the directory defined in [config.sh](./config.sh) when the ```--model``` option is not provided.

### Comments

It is advisable to run a tokenizer such as [Elephant](http://gmb.let.rug.nl/elephant/about.php) on your additional data (if any).

Furthermore, if you have the means to identify multiword expressions, you can represent them as a single token using white spaces, tildes or hyphens (as in ```ice cream```, ```ice~cream``` or ```ice-cream```).

### References

1. L. Abzianidze and J. Bos. [_Towards Universal Semantic Tagging_](http://www.aclweb.org/anthology/W17-6901). In Proceedings of the 12th International Conference on Computational Semantics (IWCS) - Short papers. Association for Computational Linguistics, 2017.

2. J. Bjerva, B. Plank and J. Bos. [_Semantic Tagging with Deep Residual Networks_](http://aclweb.org/anthology/C16-1333). In Proceedings of COLING 2016, the 26th International Conference on Computational Linguistics: Technical Papers, pages 3531–3541. Association for Computational Linguistics, 2016.
