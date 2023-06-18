IFS=$'\n\t'
set -eou pipefail

if [[ "$#" -ne 2 || "${1}" == '-h' || "${1}" == '--help' ]]; then
	cat >&2 <<"EOF"
housekeeping_images.sh cleans up tagged or untagged images pushed for a given repository (an image name without a tag/digest)
and except the given number most recent images
USAGE:
  housekeeping_images.sh REPOSITORY NUMBER_OF_IMAGES_TO_REMAIN
EXAMPLE
  housekeeping_images.sh eu.gcr.io/YOUR_PROJECT/IMAGE_NAME 5
  would clean up everything under the eu.gcr.io/test-project/php repository
  pushed except for the 5 most recent images
EOF
	exit 1
# elif [ ${2} -ge 0 ] 2>/dev/null; then
#     echo "no number of images to remain given" >&2
#     exit 1
fi

main() {
	local C=0
	IMAGE="${1}"
	NUMBER_OF_IMAGES_TO_REMAIN=$((${2} - 1))

	DATE=$(gcloud container images list-tags $IMAGE --limit=unlimited \
		--sort-by=~TIMESTAMP --format=json | TZ=/usr/share/zoneinfo/UTC jq -r '.['$NUMBER_OF_IMAGES_TO_REMAIN'].timestamp.datetime | sub("(?<before>.*):"; .before ) | strptime("%Y-%m-%d %H:%M:%S%z") | mktime | strftime("%Y-%m-%d")')

	for digest in $(gcloud container images list-tags $IMAGE --limit=unlimited --sort-by=~TIMESTAMP \
		--filter="timestamp.datetime < '${DATE}'" --format='get(digest)'); do
		(
			set -x
			gcloud container images delete -q --force-delete-tags "${IMAGE}@${digest}"
		)
		let C=C+1
	done
	echo "Deleted ${C} images in ${IMAGE}." >&2
}

main "${1}" ${2}
