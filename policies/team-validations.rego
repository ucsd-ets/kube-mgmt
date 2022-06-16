package kubernetes.admission

deny[msg] {
	teaminfo := fetch_team_info(username)
	gids := {gid | gid := teaminfo[i].gid}
	gid_selected := to_number(team_gid)
	not gids[gid_selected]
	msg := sprintf("%s does not have permission to use gid %s", [username, gid_selected])
}

deny[msg] {
	teaminfo := fetch_team_info(username)
	gid_selected := to_number(team_gid)
	gids := {gid | gid := teaminfo[i].gid}
	courses := [course | course := teaminfo[i].course.courseId]
	course_indexes := [j | j := courses[i] == course]

	# don't no why this works for j but it does -_-
	gids_for_course := {gid | gid := gids[j]}
	not gids_for_course[gid_selected]
	msg := sprintf("%s does not have permission to use gid %s for course %s", [username, gid_selected, course])
}

######################### TESTS #########################

test_not_deny_if_team {
	not deny["yuwei does not have permission to use gid 100000078"] with input.request as {"object": {
		"metadata": {
			"namespace": "yuwei",
			"labels": {
				"dsmlp/user": "yuwei",
				"dsmlp/team": "100000078",
			},
		},
		"spec": {"securityContext": {"runAsUser": 81172}},
	}}
}

test_deny_if_not_in_team {
	deny with input.request as {"object": {
		"metadata": {
			"namespace": "yuwei",
			"labels": {
				"dsmlp/user": "yuwei",
				"dsmlp/team": "100000070",
			},
		},
		"spec": {"securityContext": {"runAsUser": 81172}},
	}}
}

test_deny_if_team_not_in_course {
	deny with input.request as {"object": {
		"metadata": {
			"namespace": "yuwei",
			"labels": {
				"dsmlp/user": "yuwei",
				"dsmlp/team": "1000000780",
				"dsmlp/course": "BIPN162_S120_A00",
			},
		},
		"spec": {"securityContext": {"runAsUser": 81172}},
	}}
}

test_not_deny_if_team_in_course {
	not deny.yuwei with input.request as {"object": {
		"metadata": {
			"namespace": "yuwei",
			"labels": {
				"dsmlp/user": "yuwei",
				"dsmlp/team": "100000078",
				"dsmlp/course": "BIPN162_S120_A00",
			},
		},
		"spec": {"securityContext": {"runAsUser": 81172}},
	}}
}
