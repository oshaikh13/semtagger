#!/usr/bin/python3
# this script trains a neural model for semantic tagging

import sys
import os
sys.path.append(sys.argv[1])
#sys.stderr = open('/dev/null', 'w')
#os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

import pickle
import numpy as np

from models.argparser import get_args
from models.loader import load_conll_notags, make_char_seqs
from models.nnmodels import get_model

from utils.input2feats import wordsents2sym, charsents2sym

#sys.stderr = sys.__stderr__


# parse input arguments
args = get_args()

# load trained model parameters
minfo = pickle.load(open(args.output_model_info, 'rb'))
params = minfo['params']

# read and featurize unlabelled data
word_inputs, word_sents = load_conll_notags(args.input_pred_file,
                                            vocab = minfo['word2idx'].keys(),
                                            oovs = minfo['oov_sym'],
                                            pads = minfo['pad_word'],
                                            lower = False,
                                            mwe = True,
                                            unk_case = True)

# transform inputs to a symbolic representation
if params.use_words:
    X_word, _ = wordsents2sym(word_sents,
                              minfo['max_slen'],
                              minfo['word2idx'],
                              minfo['tag2idx'],
                              minfo['oov_sym']['unknown'],
                              minfo['DEFAULT_TAG'],
                              minfo['pad_word']['pad'],
                              minfo['DEFAULT_TAG'])

# compute character-based inputs
if params.use_chars:
    char_sents, _ = make_char_seqs(word_sents,
                                   vocab = set(minfo['char2idx'].keys()),
                                   oovs = minfo['oov_sym'],
                                   pads = minfo['pad_char'],
                                   len_perc = params.word_len_perc,
                                   lower = False,
                                   mwe = params.multi_word)

    # map character sentences and their tags to a symbolic representation
    X_char = charsents2sym(char_sents,
                           minfo['max_slen'],
                           minfo['max_wlen'],
                           minfo['char2idx'],
                           minfo['oov_sym']['unknown'],
                           minfo['pad_char'])

# build input for the model
if params.use_words and params.use_chars:
    X = [X_word, X_char]
elif params.use_words:
    X = X_word
elif params.use_chars:
    X = X_char

# use a trained model to predict the corresponding tags
if params.use_words and params.use_chars:
    model = get_model(minfo['params'],
                      minfo['num_tags'],
                      minfo['max_slen'],
                      minfo['num_words'],
                      minfo['wemb_dim'],
                      minfo['wemb_matrix'],
                      minfo['max_wlen'],
                      minfo['num_chars'],
                      minfo['cemb_dim'],
                      minfo['cemb_matrix'])
elif params.use_words:
    model = get_model(minfo['params'],
                      minfo['num_tags'],
                      minfo['max_slen'],
                      minfo['num_words'],
                      minfo['wemb_dim'],
                      minfo['wemb_matrix'])

elif params.use_chars:
    model = get_model(minfo['params'],
                      minfo['num_tags'],
                      minfo['max_wlen'],
                      minfo['num_chars'],
                      minfo['cemb_dim'],
                      minfo['cemb_matrix'])

model.load_weights(args.output_model)
model.summary()

# predict tags using the model
p = model.predict(X, verbose=min(1, minfo['params'].verbose))
p = np.argmax(p, axis=-1) + 1


# reconstruct the original file with tags
#print(word_inputs[0])
#print(word_sents[0])
#print(p[0])
#print(list(filter(lambda y: y[0] > 0, zip([x[1] for x in word_sents[0]], p[0]))))

### Attention! A sentence from word_input can be splitted in multiple word_sents sentences
idx_offset = 0
with open(args.output_pred_file, 'w') as ofile:
    for sidx in range(len(word_inputs)):
        # fix the index SIDX to point to the correct sentence always
        old_offset = idx_offset
        while list(filter(lambda y: y[1] != -1, word_sents[sidx+idx_offset]))[-1][1] < len(word_inputs[sidx])-1:
            idx_offset += 1

        wpos2tag = {}
        for off in range(old_offset, idx_offset+1):
            for wpos, tag in zip([x[1] for x in word_sents[sidx+off]], p[sidx+off]):
                if wpos not in wpos2tag:
                    wpos2tag[wpos] = []
                wpos2tag[wpos].append(tag)

        for widx in range(len(word_inputs[sidx])):
            tgt_word = word_inputs[sidx][widx]
            tgt_tag = minfo['tag2idx'][minfo['DEFAULT_TAG']]
            if widx in wpos2tag:
                tgt_tag = max(set(wpos2tag[widx]), key=wpos2tag[widx].count)
            # write out
            ofile.write(tgt_word + '\t' + str(minfo['idx2tag'][tgt_tag]) + '\n')
        ofile.write('\n')

