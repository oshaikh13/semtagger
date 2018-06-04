#!/bin/bash

#SBATCH --time=20:00:00
#SBATCH --mem=20GB

TAGGER_HOME="/home/joan/semtagger"
PMB_EXTRA_HOME="/home/joan/pmb_extra"

. ${TAGGER_HOME}/run.sh --train

OPTIND=1
. ${TAGGER_HOME}/run.sh --predict --input ${PMB_EXTRA_HOME}/en/gold/gold_train.off --output ${PMB_EXTRA_HOME}/en/gold/gold_train.sem
OPTIND=1
. ${TAGGER_HOME}/run.sh --predict --input ${PMB_EXTRA_HOME}/en/gold/gold_test.off --output ${PMB_EXTRA_HOME}/en/gold/gold_test.sem
OPTIND=1
. ${TAGGER_HOME}/run.sh --predict --input ${PMB_EXTRA_HOME}/en/silver/silver_train.off --output ${PMB_EXTRA_HOME}/en/silver/silver_train.sem
OPTIND=1
. ${TAGGER_HOME}/run.sh --predict --input ${PMB_EXTRA_HOME}/en/silver/silver_test.off --output ${PMB_EXTRA_HOME}/en/silver/silver_test.sem

python3 ${TAGGER_HOME}/utils/compare_tags.py ${PMB_EXTRA_HOME}/en/gold/gold_train.sem ${PMB_EXTRA_HOME}/en/gold/train/gold_train.gold
python3 ${TAGGER_HOME}/utils/compare_tags.py ${PMB_EXTRA_HOME}/en/gold/gold_test.sem ${PMB_EXTRA_HOME}/en/gold/test/gold_test.gold
python3 ${TAGGER_HOME}/utils/compare_tags.py ${PMB_EXTRA_HOME}/en/silver/silver_train.sem ${PMB_EXTRA_HOME}/en/silver/train/silver_train.gold
python3 ${TAGGER_HOME}/utils/compare_tags.py ${PMB_EXTRA_HOME}/en/silver/silver_test.sem ${PMB_EXTRA_HOME}/en/silver/test/silver_test.gold

