function help {
    echo -e "Usage:\n\tmetadata.sh -k (metadata key name)"; exit 1;
}

function main {
  get_metadata
}


function get_metadata {
    which jq || apt install jq -y > /dev/null 2>&1
    [ -z "$METADATA_KEY" ] && metadata=$(curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | jq) || metadata=$(curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/$METADATA_KEY?api-version=2021-02-01" | jq)
    echo $metadata
}

while getopts ":k:" option; do
   case $option in
        k)  k=${OPTARG}
            METADATA_KEY=${OPTARG}
            ;;
        \?) echo "Error: Invalid option"
            help
            ;;
   esac
done
shift $((OPTIND-1))

main