#!/bin/bash
set -e

BASEURL="https://dgca-businessrule-service-test.ezdrav.si/rules/"

rm -rf "rules.bak"
mv "rules" "rules.bak" || true
mkdir -p "rules"

cat << ENDHEADER > "rules/README.md"
# List of rules

| Country | Rule | Source | Description |
| ------- | ---- | ------ | ----------- |
ENDHEADER

curl -s "${BASEURL}" | jq -r '.[] | .country + " " + .identifier + " " + .hash ' \
| while IFS=" " read -r COUNTRY ID HASH; do
    mkdir -p "rules/${COUNTRY}"

    if [ ! -f "rules/${COUNTRY}/README.md" ]
    then
        cat << ENDCOUTRYHEADER > "rules/${COUNTRY}/README.md"
# List of rules for country ${COUNTRY}

| Rule | Source | Description |
| ---- | ------ | ----------- |
ENDCOUTRYHEADER
    fi

    echo -n "Downloading ${COUNTRY}: ${ID} > "
    curl -s "${BASEURL}${COUNTRY}/${HASH}" | jq --sort-keys > "rules/${COUNTRY}/${ID}.json"
    DESC=$(jq -r 'select(.Description != null) | .Description[]|select(.lang == "en").desc' "rules/${COUNTRY}/${ID}.json")
    echo "${DESC}"
    echo "| [${COUNTRY}](${COUNTRY}/README.md) | [${ID}](${COUNTRY}/${ID}.json) | [API](${BASEURL}${COUNTRY}/${HASH}) | ${DESC} |" >> "rules/README.md"
    echo "| [${ID}](${ID}.json) | [API](${BASEURL}${COUNTRY}/${HASH}) | ${DESC} |" >> "rules/${COUNTRY}/README.md"
done
rm -rf "rules.bak"
