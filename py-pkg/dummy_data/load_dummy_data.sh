#! /bin/sh

rm -rf data_files
mkdir -p data_files
echo "Downloading Sample Data ..."
curl https://download.elastic.co/demos/kibana/gettingstarted/shakespeare.json | grep -E '"speech_number":[0-9]+' | sed 'i\{"index":{"_index":"shakespeare","_type":"line"}}' > data_files/shakespeare.json

echo "Sample Data:"
head data_files/shakespeare.json

head -50000 data_files/shakespeare.json > data_files/sample_data.json
split -l 1000 data_files/sample_data.json data_files/data_

for clusterhost in $(grep "es_[1-9]:" ../docker-compose.yml | sed s/"[[:space:]]"//g | sed s/":"//g); do

    echo "Loading Mapping for $clusterhost"
    curl --silent --header "Content-Type: application/json" -X PUT "http://$clusterhost:9200/shakespeare" -d @$clusterhost_mapping.json

    echo "Loading Sample Data for $clusterhost"
    for filename in $(ls data_files | grep data_); do
        curl --silent --header "Content-Type: application/x-ndjson" -X POST "http://$clusterhost:9200/shakespeare/_bulk" --data-binary "@data_files/$filename" >> $clusterhost.out;
    done

    curl -X POST "http://$clusterhost:9200/shakespeare/_refresh"

done

echo "Cleaning Up..."
rm -rf data_files

echo "Done!"
