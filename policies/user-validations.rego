package kubernetes.admission

### dsmlp/user

# if awsed user not exist, deny entry
deny[msg] {
	fetch_user_info(username).status_code == 404
	msg := sprintf("Could not retrieve user = %v info from database", [username])
}

# if awsed key isnt working calls fail, deny
deny[msg] {
	fetch_user_info(username).status_code == 401
	msg := "key doesn't work for database!"
}

# if database issue exist
deny[msg] {
	fetch_user_info(username).status_code > 200
	msg := "database issue"
}
