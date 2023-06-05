#!/usr/bin/env bash

echo "STEP: starting step2_filter.sh"

# extract only CR2s from input list of image files
IMAGE_FILE="$1"

echo "extracting CR2s from ${IMAGE_FILE}..."
if [[ ! -e "${IMAGE_FILE}" ]]; then
  echo "${IMAGE_FILE} does not exist; exiting."
  exit 1
fi

if [[ ! "${IMAGE_FILE}" =~ .input.csv ]]; then
  echo "${IMAGE_FILE}: name must be of the form 'foobar.input.csv"
  exit 1
fi

RUN_DATE=`date +%Y-%mT%d-%H:%M`
IMAGE_DIVERTED="${IMAGE_FILE/input/diverted}"
IMAGE_CR2S="${IMAGE_FILE/input/cr2s}"
rm -f ${IMAGE_DIVERTED} ; touch ${IMAGE_DIVERTED}
rm -f ${IMAGE_CR2S} ; touch ${IMAGE_CR2S}

while read -r IMAGE
  do
    if [[ ! "${IMAGE}" =~ .CR2 ]]; then
      echo "'${IMAGE}' does not have .CR2 in it; diverting to error queue"
      echo -e "${IMAGE}\t${RUN_DATE}" >> ${IMAGE_DIVERTED}
    else
      echo -e "${IMAGE}\t${RUN_DATE}" >> ${IMAGE_CR2S}
    fi
done < "${IMAGE_FILE}"

wc -l ${IMAGE_CR2S}
wc -l ${IMAGE_DIVERTED}
