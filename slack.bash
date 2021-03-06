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

# Extract timestamp from message search result
msg2timestamp() {
	jq --raw-output '
		.messages.matches[0].ts |
		if test("[.]") then
			split(".")[0]
		else
			.
		end
	'
}

# Use .profile.real_name for names
