#!/bin/bash
# this script prepares the data needed to train and test a universal semantic tagger


# download the PMB Universal Semantic Tags release
echo "[INFO] Downloading the PMB Universal Semantic Tags release ${PMB_VER}..."
if [ ! -d ${PMB_ROOT} ] || [ ! ${GET_PMB} -eq 0 ] && [ ! ${PMB_MAIN_DATA} -eq 0 ]; then
    rm -rf ${PMB_ROOT}
    mkdir -p ${PMB_ROOT}
    pushd ${PMB_ROOT} > /dev/null
    wget -q "pmb.let.rug.nl/releases/sem-${PMB_VER}.zip"
    unzip -qq "sem-${PMB_VER}.zip"
    rm -f "sem-${PMB_VER}.zip"
    mv sem-${PMB_VER}/* .
    rm -rf "sem-${PMB_VER}"
    popd > /dev/null
fi
echo "[INFO] Finished downloading PMB data"

# extract semantic tags from sentences in the PMB
echo "[INFO] Extracting PMB data..."
if [ ! ${PMB_MAIN_DATA} -eq 0 ]; then
    for l in ${PMB_LANGS[@]} ; do
        if [ ! -f ${PMB_EXTDIR}/${l}/sem_${l}.sem ] || [ ! ${GET_PMB} -eq 0 ]; then
            rm -f ${PMB_EXTDIR}/${l}/sem_${l}.sem
            mkdir -p ${PMB_EXTDIR}/${l}
            PMB_NUMFILES=0
            # currently only English is available
            if [ ${l} == "en" ]; then
                # iterate data sets in the PMB
                PMB_PARTS=("gold" "silver")
                for p in ${PMB_PARTS[@]} ; do
                    # define the source and target directories
                    p_sdir=${PMB_ROOT}/data/${p}
                    p_tdir=${PMB_EXTDIR}/${l}/${p}
                    # split each set into training and test sets
                    rm -rf ${p_tdir}
                    mkdir -p ${p_tdir}
                    p_train=${p_tdir}/train.gold
                    p_test=${p_tdir}/test.gold
                    # compute the number of sentences in each split
                    numsents=$(ls -1 ${p_sdir}/ | wc -l)
                    num_test=$(echo "(${numsents}*${PMB_TEST_SIZE}+0.5)/1" | bc)
                    num_train=$(($numsents - ${num_test}))
                    # sort sentences in each split and group them into single files
                    p_numfiles=0
                    p_files=$(ls -1 ${p_sdir}/ | sort -R --random-source=/dev/zero)
                    read -a arr <<< ${p_files}
                    for srcfile in ${p_files} ; do
                        # add file contents to the data split
                        p_numfiles=$((${p_numfiles} + 1))
                        if [ "${p_numfiles}" -le "${num_train}" ]; then
                            awk 'BEGIN{ FS="\t" } { if ( NF > 1 ) print $1 "\t" $2 ; else print "" } END{ print "" }' ${p_sdir}/${srcfile} \
                                >> ${p_train}
                        else
                            awk 'BEGIN{ FS="\t" } { if ( NF > 1 ) print $1 "\t" $2 ; else print "" } END{ print "" }' ${p_sdir}/${srcfile} \
                                >> ${p_test}
                        fi
                        # feedback output
                        PMB_NUMFILES=$((${PMB_NUMFILES} + 1))
                        if ! ((${PMB_NUMFILES} % 10000)) && [ ${PMB_NUMFILES} -ge 10000 ]; then
                            echo "[INFO] Processed ${PMB_NUMFILES} files (${l})..."
                        fi
                    done
                    # map UNK tags to NIL
                    sed -i 's/UNK\t/NIL\t/g' ${p_train}
                    sed -i 's/UNK\t/NIL\t/g' ${p_test}
                    # create files with removed semantic tags
                    awk 'BEGIN{ FS="\t" } { if ( NF > 1 ) print $2 ; else print "" }' ${p_train} \
                        >> ${p_tdir}/train.off
                    awk 'BEGIN{ FS="\t" } { if ( NF > 1 ) print $2 ; else print "" }' ${p_test} \
                        >> ${p_tdir}/test.off
                    # use training data as main data
                    awk 'BEGIN{ FS="\t" } { if ( NF > 1 ) print $1 "\t" $2 ; else print "" }' ${p_train} \
                        >> ${PMB_EXTDIR}/${l}/sem_${l}.sem
                done
            else
                echo -e "NIL\t.\n" >> ${PMB_EXTDIR}/${l}/sem_${l}.sem
            fi
            echo "[INFO] Extracted PMB data from ${PMB_NUMFILES} files (${l})"
        fi
    done
else
    # ensure removal of remaining data
    for l in ${PMB_LANGS[@]} ; do
        rm -f ${PMB_EXTDIR}/${l}/sem_${l}.sem
        mkdir -p ${PMB_EXTDIR}/${l}
        echo -e "NIL\t.\n" >> ${PMB_EXTDIR}/${l}/sem_${l}.sem
    done
fi

# extract semantic tags from the extra available data
echo "[INFO] Extracting EXTRA data..."
if [ ! ${PMB_EXTRA_DATA} -eq 0 ]; then
    # remove remaining temporary files
    for l in ${PMB_LANGS[@]} ; do
        rm -f ${PMB_EXTDIR}/${l}/extra_${l}.sem.tmp
    done

    for idx in ${!PMB_EXTRA_LANGS[*]} ; do
        l=${PMB_EXTRA_LANGS[$idx]}
        if [ ! -f ${PMB_EXTDIR}/${l}/extra_${l}.sem ] || [ ! ${GET_EXTRA} -eq 0 ]; then
            rm -f ${PMB_EXTDIR}/${l}/extra_${l}.sem
            mkdir -p ${PMB_EXTDIR}/${l}
            PMB_EXTRA_NUMFILES=0
            # iterate over files in the extra directory
            for srcfile in ${PMB_EXTRA_SRC[$idx]}/* ; do
                # add file contents to existing data
                awk 'BEGIN{ FS="\t" } { if ( NF > 1 ) print $1 "\t" $2 ; else print "" } END{ print "" }' ${srcfile} \
                    >> ${PMB_EXTDIR}/${l}/extra_${l}.sem.tmp
                # feedback output
                PMB_EXTRA_NUMFILES=$((${PMB_EXTRA_NUMFILES} + 1))
                if ! ((${PMB_EXTRA_NUMFILES} % 10000)) && [ ${PMB_EXTRA_NUMFILES} -ge 10000 ] ; then
                    echo "[INFO] Processed ${PMB_EXTRA_NUMFILES} files (${l})..."
                fi
            done
            echo "[INFO] Extracted EXTRA data from ${PMB_EXTRA_NUMFILES} files (${l})"
        fi
    done
    for l in ${PMB_LANGS[@]} ; do
        if [ -f ${PMB_EXTDIR}/${l}/extra_${l}.sem.tmp ]; then
            mv -f ${PMB_EXTDIR}/${l}/extra_${l}.sem.tmp ${PMB_EXTDIR}/${l}/extra_${l}.sem
            sed -i 's/UNK\t/NIL\t/g' ${PMB_EXTDIR}/${l}/extra_${l}.sem
        fi
    done
else
    # ensure removal of remaining data
    for l in ${PMB_LANGS[@]} ; do
        rm -f ${PMB_EXTDIR}/${l}/extra_${l}.sem
        rm -f ${PMB_EXTDIR}/${l}/extra_${l}.sem.tmp
    done
fi
echo "[INFO] Extraction of semantically tagged data completed"

