# set -x
 
function main {
  get_objectValue
}


function objectValue() {
  which jq || apt install jq -y
  read -p "Enter Json Object: " object
  read -p "Enter Key from Object: " key
  key=$(echo $key | sed 's/\//./g') 
  value=$(echo $object | jq .$key)
  echo "value: $value"
}

main