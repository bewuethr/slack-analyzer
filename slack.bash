# Fetch complete users list from Slack API
getusers() {
	curl https://slack.com/api/users.list \
		--silent \
		--get \
		--data 'pretty=1' \
		--header "Authorization: Bearer $BOT_TOKEN" \
		> users.json
}

# Remove bot and guest users
extractemployees() {
	jq '
		.members |
		map(select(
			(
				.is_bot or .is_restricted |
				not
			)
			and .name != "slackbot"
		))
	' users.json > employees.json
}

# Retrieve first or last message for user from Slack API
findmsg() {
	local userid=$1
	local dir=$2
	curl https://slack.com/api/search.messages \
		--silent \
		--get \
		--data 'pretty=1' \
		--data-urlencode "query=from:<@$userid>" \
		--data 'count=1' \
		--data 'sort=timestamp' \
		--data "sort_dir=$dir" \
		--header "Authorization: Bearer $USER_TOKEN"
}

# Find first message from user
findfirst() {
	local userid=$1
	findmsg "$userid" 'asc'
}

# Find last message from user
findlast() {
	local userid=$1
	findmsg "$userid" 'desc'
}

# Extract timestamp from message search result; return non-zero exit status if
# user has no messages at all
msg2timestamp() {
	if jq --exit-status '.messages.total == 0' > /dev/null; then
		return 1
	fi

	jq --raw-output '
		.messages.matches[0].ts |
		if test("[.]") then
			split(".")[0]
		else
			.
		end
	'
}

# Convert employees to input required for first/last lookup
extractids() {
	jq --compact-output '
		map([.id, .profile.real_name, .deleted, .profile.title]) |
		.[]
	' employees.json
}

# Loop over all employees and fetch the timestamp of their first message; if the
# user is deleted, also fetch their last message; print everything to
# tenures.tsv
tenurelookup() {
	printf '%s\t%s\t%s\t%s\t%s\n' 'id' 'name' 'title' 'first' 'last'

	local id name deleted title 
	while IFS=$'\t' read -r id name deleted title; do
		local first
		first=$(findfirst "$id" | msg2timestamp)

		if [[ $deleted == 'true' ]]; then
			local last
			last=$(findlast "$id" | msg2timestamp)
		fi

		printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$name" "$title" "$first" "$last"

		unset id name title deleted first last
		sleep 3
	done < <(extractids | jq --raw-output '@tsv')
} > tenures.tsv

tenureupdate() {
	:
	# Read ID and deleted
	# Look up in tenures; possible outcomes:
	# - first and last exist already; copy entry
	# - only first exists
	#   - deleted is false: copy entry
	#   - deleted is true: find last, add to entry
	# - no timestamp or ID does not exist
	#   - deleted is false: find first
	#   - deleted is true: find first and last
	#
	# Introduce status to avoid looking up people without messages repeatedly:
	# - fresh: not deleted, has no messages
	# - active: not deleted, has first message
	# - alumnus: deleted, has first and last message
	# - noshow: deleted, has no messages
}

prettyprint() {
	sed '1d' tenures.tsv \
		| sort --numeric-sort --key=4,4 --field-separator=$'\t' \
		| awk --field-separator='\t' --assign OFS='\t' '
			$4 {
				$4 = strftime("%F", $4)
				if ($5)
					$5 = strftime("%F", $5)
				print
			}
		' \
		| nl \
		| column --table --separator=$'\t' --table-truncate=4
}
